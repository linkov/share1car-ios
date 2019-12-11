//
//  CarpoolManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/10/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox

import Polyline

import MapboxGeocoder
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import Turf

import EasyPeasy

import Loaf
import BLTNBoard

//TODO: Fetch current status of any active carpool and reconstruct
// thelast active currentCarpoolSearchResult if any
class CarpoolSearchManager: NSObject {
    
    
    // MARK: General
    
    private var didSendRequestBlock: result_errordescription_block?
    private var carpoolSearchResultBlock: carpool_search_result_error_block?
    private var bulletinManager: BLTNItemManager?
    private var currentBadgeView: RequestUpdateBadgeView?
    
    // MARK: Model
    
    private var currentCarpoolSearchResult = S1CCarpoolSearchResult()
    private var driversLocations: [String : MGLPointAnnotation] = [:]
    private var routeFeatures: [String:MGLPolylineFeature] = [:]
    
    // MARK: State
    private var didShowCarpoolPickUpAlert = false
    private var activeCarpoolAcceptStatus: CarpoolAcceptStatus?
    

    // MARK: Inputs
    
    var mapView: NavigationMapView?
    var presentingViewController: RiderViewController?
    
    
    
    static let shared = CarpoolSearchManager()

     override init(){
        super.init()
        

        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolAcceptNotificationReceivedNotification, object: nil)


    
        
    }
    

    // MARK: - Start / Stop carpool requests
    
    
    public func findCarpool(currentLocation: CLLocationCoordinate2D, destination: CLLocationCoordinate2D , didSendRequest: @escaping result_errordescription_block ) {
        
        didSendRequestBlock = didSendRequest
        self.currentCarpoolSearchResult.riderDestination = destination
        
        if (activeCarpoolAcceptStatus != nil) && activeCarpoolAcceptStatus != .rejected {
            return
        }
        
        
        guard routeFeatures.count > 0 else {
            didSendRequestBlock!(nil,"No drivers available")
            return
        }
        
        for (key, feature) in routeFeatures {
            
            
            let buffer = UnsafeBufferPointer(start: feature.coordinates, count: Int(feature.pointCount))
            let coordinates = Array(buffer)
            
            let lineStringForDriverRoute = LineString(coordinates)
            let closestLocationOnDriverRouteForPickup = lineStringForDriverRoute.closestCoordinate(to: currentLocation)
            let closestLocationOnDriverRouteForDropOff = lineStringForDriverRoute.closestCoordinate(to: destination)
            
            
            
            if (Int(closestLocationOnDriverRouteForPickup!.distance) <= UserSettingsManager.shared.getMaximumPickupDistance() && activeCarpoolAcceptStatus == nil) {
                let driverID = key
                
                DataManager.shared.getUserDetails(userID: driverID) { (userDetails, error) in
                    if error != nil {
                        
                        return
                    }
                    
                    
                    DriverDataManager.shared.getPreplannedCarpoolDate(driverID: driverID, completion: { (result, error ) in
                      
                        if result != nil {
                            self.currentCarpoolSearchResult.carpooPreplannedDateString = (result as! String)
                            self.currentCarpoolSearchResult.driverDetails = userDetails
                            self.currentCarpoolSearchResult.dropOffLocation = closestLocationOnDriverRouteForDropOff!.coordinate
                            self.currentCarpoolSearchResult.pickUpLocation = closestLocationOnDriverRouteForPickup!.coordinate
                            self.currentCarpoolSearchResult.carpoolDistance = self.currentCarpoolSearchResult.pickUpLocation?.distance(to: self.currentCarpoolSearchResult.dropOffLocation!)
                            self.currentCarpoolSearchResult.riderTimeToPickUpLocation = (self.currentCarpoolSearchResult.pickUpLocation?.distance(to: currentLocation))!/40
                            
                            self.showPreplannedCarpoolSuggestion()
                            
                        } else {
                            
                             
                             self.calculateRiderRouteFromCurrentLocationToPickUp(pickUp: closestLocationOnDriverRouteForPickup!.coordinate)
                             self.calculateRiderRouteFromDropOffToDestination(dropOff: closestLocationOnDriverRouteForDropOff!.coordinate, riderDestination: destination)
                            
                             self.currentCarpoolSearchResult.driverDetails = userDetails
                             self.currentCarpoolSearchResult.dropOffLocation = closestLocationOnDriverRouteForDropOff!.coordinate
                             self.currentCarpoolSearchResult.pickUpLocation = closestLocationOnDriverRouteForPickup!.coordinate
                             
                             self.fetchTimingsForCarpool(driverID: userDetails!.UID!, pickUpLocation: closestLocationOnDriverRouteForPickup!.coordinate, currentLocation: currentLocation)
                        }
                        
                    })
     

                    

                    
                    
                }

                
            
            
                return
            }
            

         
            
        }
        
        didSendRequestBlock!(nil,"There are no car pools available in \(UserSettingsManager.shared.getMaximumPickupDistance()) meters radius from your current location and your pick up location")
        
        
        
    }
    
    @objc public func cancelCarpool() {
        
        if (activeCarpoolAcceptStatus == nil) || activeCarpoolAcceptStatus == .rejected {
            return
        }
        
        RiderDataManager.shared.cancelCarpool(driverID: (currentCarpoolSearchResult.driverDetails?.UID!)!, riderID: AuthManager.shared.currentUserID()!) { (success, errorString) in
            
            var title: String
            
            if errorString != nil {
            
                title = errorString!
                
            } else {
                
                title = "Your ride was cancelled"
            }
            self.cleanup()
            Loaf(title, state: .warning, sender: self.presentingViewController!).show()
            

            
        }
    }
    
    private func confirmCarpoolForCarpoolSearchResult(result: S1CCarpoolSearchResult) {
    
//        RiderDataManager.shared.confirmCarpool(driverID: result.driverDetails!.UID!)
    }

    
    private func requestCarpoolForCarpoolSearchResult(result: S1CCarpoolSearchResult) {
                
        RiderDataManager.shared.requestCarpool(pickUpLocation: result.pickUpLocation!, dropOffLocation: result.dropOffLocation!, driverID: result.driverDetails!.UID!)
        
        RiderDataManager.shared.startObservingRideAcceptForMyRiderID { (acceptResult, error) in
            
            guard error == nil else {
                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            
            if acceptResult == nil || acceptResult?.count == 0 {
                return
            }
            
            let status = acceptResult![result.driverDetails!.UID!] as! String
            self.processStatus(status: status)
            
            
        }
        
    }
    
    
    public func cleanup() {
        
         activeCarpoolAcceptStatus = nil
         didShowCarpoolPickUpAlert = false
         currentCarpoolSearchResult = S1CCarpoolSearchResult()
         removeRiderSourceWithIdentifier(routeID: "rider-route-in")
         removeRiderSourceWithIdentifier(routeID: "rider-route-out")
         
     }
    
    
    // MARK: - Subscriptions
    
    @objc func onDidReceiveData(_ notification:Notification) {
        let status = Converters.notificationTypeFromNotificationUserInfo(userInfo: notification.userInfo!)
        
        
        processStatus(status: status)
        

    }
    
    func processStatus(status: String) {
        
        print("RideAccept STATUS IS:")
        print(status)

        if status.contains("accepted")  && activeCarpoolAcceptStatus != .accepted  {
            activeCarpoolAcceptStatus = .accepted
            bulletinManager?.dismissBulletin()
            
            var title = "Request accepted, follow the map to meet the driver"
            if currentCarpoolSearchResult.carpooPreplannedDateString != nil {
                let date = Date().addingTimeInterval(200000)
                title = "Follow the map to meet the driver - \(Converters.getRelativeDate(date: date))"
            }
            
            showRequestUpdateBadgeView(title: title, actionTitle: "cancel", action: #selector(cancelCarpool))

        }

        if status.contains("rejected") && activeCarpoolAcceptStatus != .rejected {
            self.activeCarpoolAcceptStatus = .rejected

            
            dismissNonblockingBadgeView()

            showRequestUpdate(title: "Request rejected", subtitle: nil)
            if self.currentCarpoolSearchResult.driverDetails != nil {
                RiderDataManager.shared.clearCarpoolData(driverID: self.currentCarpoolSearchResult.driverDetails!.UID!, riderID: AuthManager.shared.currentUserID()!, completion: { (result, error) in
                    
                    
                    self.cleanup()
                    
                })
                
            } else {
                  self.cleanup()
            }



            

        }

        if status.contains("confirmed") && activeCarpoolAcceptStatus != .confirmed {
            activeCarpoolAcceptStatus = .confirmed
            showProximityAlert()
        }

        if status.contains("arrived")  && activeCarpoolAcceptStatus != .arrived {
            activeCarpoolAcceptStatus = .arrived
            showRequestUpdateBadgeView(title: "You arrived", actionTitle: nil, action: nil)
            NotificationCenter.default.post(name: NotificationsManager.onFeedbackScreenRequestedNotification, object: nil)
        }
        
    }
    
    func configureAndStartSubscriptions(mapView: NavigationMapView, presentingViewController: RiderViewController) {
        self.presentingViewController = presentingViewController
        self.mapView = mapView
        subscribeMapViewToDriverRoutes()
        subscribeMapViewToDriverLocations()
    }
    
    
   private func subscribeMapViewToDriverRoutes() {
        
        RiderDataManager.shared.getAvailableDriverRoutes { (routesDictionary) in
                DispatchQueue.main.async {
                        self.updateRoutesOnMap(routes: routesDictionary)
                }
            
        }
    }
    
   private func subscribeMapViewToDriverLocations() {
        
        RiderDataManager.shared.getDriversLocations { (locationsDictionary) in
        
            
             self.mapView!.removeAnnotations(self.mapView!.annotations ?? [])
            
            for (key, value) in locationsDictionary {
                

                let point = MGLPointAnnotation()
                point.title = key
                
                let coordsArray = value as! [Double]
                
                
                point.coordinate = CLLocationCoordinate2D(latitude: coordsArray[0], longitude: coordsArray[1])
                
        
                if AuthManager.shared.isLoggedIn() && key == AuthManager.shared.currentUserID()! {
                    return
                }
                
                if  self.didShowCarpoolPickUpAlert == false && self.activeCarpoolAcceptStatus != nil && self.activeCarpoolAcceptStatus == .accepted && self.currentCarpoolSearchResult.filled() && key == self.currentCarpoolSearchResult.driverDetails!.UID! {
                    

                    let closest = self.mapView!.userLocation!.coordinate.distance(to: point.coordinate)
                    print(closest)
                    
                    let distance = closest
                    
                    if Int(distance) < 300 {
                        
                        print("Proximity alert")
                        
                        
                        if (!self.didShowCarpoolPickUpAlert) {
                             self.didShowCarpoolPickUpAlert = true
                             self.showProximityAlert()
                        }
                       
                        
                        
                    }
                    
                    
                }
                
                
                
                self.driversLocations[key] = point
                self.mapView!.addAnnotation(point)
            }
            
    
           
            

             
        }
        
    }
    
    
    // MARK: - Draw updates on map
    
    private func removeRiderSourceWithIdentifier(routeID: String) {
         
        
         if let source = self.mapView!.style?.source(withIdentifier: routeID) as? MGLShapeSource {
             
             self.mapView!.style?.removeSource(source)
             
             
             if let layer = self.mapView!.style?.layer(withIdentifier: routeID) {
                 self.mapView!.style?.removeLayer(layer)
             }
             
             
         }
     }
    

    private func removeSourceWithIdentifier(routeID: String) {
         
        
        if routeID == "rider-route-in" || routeID == "rider-route-out" {
            return
        }
         if let source = self.mapView!.style?.source(withIdentifier: routeID) as? MGLShapeSource {
             
             self.mapView!.style?.removeSource(source)
             
             
             if let layer = self.mapView!.style?.layer(withIdentifier: routeID) {
                 self.mapView!.style?.removeLayer(layer)
             }
             
             
         }
     }
     
     
     
     
     private func addRiderRoute(feature:MGLPolylineFeature, identifier: String) {

             if let source = self.mapView!.style?.source(withIdentifier: identifier) as? MGLShapeSource {

                 source.shape = feature
                
                if let lineStyle = self.mapView?.style?.layer(withIdentifier: identifier) as? MGLLineStyleLayer {
                    
                    lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1))
                    lineStyle.lineDashPattern = NSExpression(forConstantValue: [2, 1.5])
                    lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                } else {
                    let lineStyle = MGLLineStyleLayer(identifier: identifier, source: source)
                    lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1))
                    lineStyle.lineDashPattern = NSExpression(forConstantValue: [2, 1.5])
                    lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                }
                

             } else {

                 let source = MGLShapeSource(identifier: identifier, features: [feature], options: nil)

                 let lineStyle = MGLLineStyleLayer(identifier: identifier, source: source)
                 lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1))
                 lineStyle.lineDashPattern = NSExpression(forConstantValue: [2, 1.5])
                 lineStyle.lineWidth = NSExpression(forConstantValue: 3)

                 self.mapView!.style?.addSource(source)
                 self.mapView!.style?.addLayer(lineStyle)

             }


         }

     

     

    private func updateRiderInOutRoutesForCurrentCarpool(feature: MGLPolylineFeature) {
        
        let buffer = UnsafeBufferPointer(start: feature.coordinates, count: Int(feature.pointCount))
        let coordinates = Array(buffer)
        
        let lineStringForDriverRoute = LineString(coordinates)
        let closestLocationOnDriverRouteForPickup = lineStringForDriverRoute.closestCoordinate(to: (mapView?.userLocation!.coordinate)!)
        let closestLocationOnDriverRouteForDropOff = lineStringForDriverRoute.closestCoordinate(to: self.currentCarpoolSearchResult.riderDestination!)
        
        self.calculateRiderRouteFromCurrentLocationToPickUp(pickUp: closestLocationOnDriverRouteForPickup!.coordinate)
        self.calculateRiderRouteFromDropOffToDestination(dropOff: closestLocationOnDriverRouteForDropOff!.coordinate, riderDestination: self.currentCarpoolSearchResult.riderDestination!)
    }
    
    private func updateRoutesOnMap(routes: [String : String]) {
       
        for (key, _) in routeFeatures {
 
            removeSourceWithIdentifier(routeID: key)
        }
        
        routeFeatures = [:]
        
        mapView?.removeRoutes()
        
        for (key, value) in routes {
            

            let polyline = Polyline(encodedPolyline: value, precision: 1e6)

            let feature = MGLPolylineFeature(coordinates: polyline.coordinates!, count: UInt(polyline.coordinates!.count))
            
            if AuthManager.shared.isLoggedIn() && key == AuthManager.shared.currentUserID()! {
               
            } else {
                routeFeatures[key] = feature
                
                if key == currentCarpoolSearchResult.driverDetails?.UID {
                    self.updateRiderInOutRoutesForCurrentCarpool(feature: feature)
                }
                drawRouteFeature(driverID: key, feature: feature)
            }
            

            

        }
        
    }
    
    private func drawRouteFeature(driverID:String, feature:MGLPolylineFeature) {


            // If there's already a route line on the map, reset its shape to the new route
        if let source = self.mapView?.style?.source(withIdentifier: driverID) as? MGLShapeSource {
                
                source.shape = feature
               
            if let lineStyle = self.mapView?.style?.layer(withIdentifier: driverID) as? MGLLineStyleLayer {
                
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.5333333333, green: 0.5960784314, blue: 0.6352941176, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 4)
            } else {
                let lineStyle = MGLLineStyleLayer(identifier: driverID, source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.5333333333, green: 0.5960784314, blue: 0.6352941176, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 4)
                self.mapView!.style?.addLayer(lineStyle)
            }
            
                
            } else {
                
                let source = MGLShapeSource(identifier: driverID, features: [feature], options: nil)
                
                // Customize the route line color and width
                let lineStyle = MGLLineStyleLayer(identifier: driverID, source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.5333333333, green: 0.5960784314, blue: 0.6352941176, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 4)
                
                // Add the source and style layer of the route line to the map
                self.mapView!.style?.addSource(source)
                self.mapView!.style?.addLayer(lineStyle)
    
            }
            
            
        }
    
    
    // MARK: - Calculate routes
    
    private func calculateRiderRouteFromCurrentLocationToPickUp(pickUp: CLLocationCoordinate2D) {
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "Current location")
        let pickUpWaypoint = Waypoint(coordinate: pickUp)
        let options = NavigationRouteOptions(waypoints: [userWaypoint, pickUpWaypoint], profileIdentifier: .walking)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            

            guard route.coordinateCount > 0 else {
                
                
                return
                
                
                
            }


            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
            self.addRiderRoute(feature: polyline, identifier: "rider-route-in")
            

        }
    }
    
    
    private func calculateRiderRouteFromDropOffToDestination(dropOff: CLLocationCoordinate2D, riderDestination: CLLocationCoordinate2D) {

        let dropOffWaypoint = Waypoint(coordinate: dropOff)
        let riderDestinationWaypoint = Waypoint(coordinate: riderDestination)
        let options = NavigationRouteOptions(waypoints: [dropOffWaypoint, riderDestinationWaypoint], profileIdentifier: .walking)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            

            guard route.coordinateCount > 0 else {
                
                return
                
                
            }


            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
            self.addRiderRoute(feature: polyline, identifier: "rider-route-out")
            

        }
    }
    
    

    // MARK: - Fetch carpool details
    

    
    private func fetchTimingsForCarpool(driverID: String, pickUpLocation: CLLocationCoordinate2D, currentLocation: CLLocationCoordinate2D) {
        
        fetchDriverRouteToPickUpLocation(driverID: driverID, pickUp: pickUpLocation, completion: { (result, error) in
            if error != nil {
                self.didSendRequestBlock!(nil,error!)
                return
            }
            
            self.fetchWalkingRouteToPickUpLocation(currentLocation: currentLocation, pickUp: pickUpLocation, completion:  { (result, error) in
                if error != nil {
                    self.didSendRequestBlock!(nil,error!)
                    return
                }
               
                self.fetchDriverRouteFromPickUpToDropOff(pickup: pickUpLocation, dropoff: self.currentCarpoolSearchResult.dropOffLocation!) { (result, errorString) in
                    if error != nil {
                        self.didSendRequestBlock!(nil,error!)
                        return
                    }
                    self.showCarpoolSuggestion()
                }
            })
            
        })
        
    }
    
    
    
   private func fetchDriverRouteFromPickUpToDropOff(pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D, completion: @escaping result_errordescription_block ) {
        
        
        let pickupWaypoint = Waypoint(coordinate: pickup)
        let dropoffWaypoint = Waypoint(coordinate: dropoff)
         
        let options = NavigationRouteOptions(waypoints: [pickupWaypoint, dropoffWaypoint], profileIdentifier: .automobileAvoidingTraffic)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 completion(nil, error!.localizedDescription)
                return
            }
            

            guard route.coordinateCount > 0 else {
             
             completion(nil, "Route has no coordinates")
             return
             
         }
            
            self.currentCarpoolSearchResult.carpoolDistance = route.distance
            
            
            
            completion(nil, nil)


        }
    }

    
    private func fetchWalkingRouteToPickUpLocation(currentLocation: CLLocationCoordinate2D, pickUp: CLLocationCoordinate2D , completion: @escaping result_errordescription_block) {
           
           let userWaypoint = Waypoint(coordinate: currentLocation)
           let pickUpWaypoint = Waypoint(coordinate: pickUp)
            
           let options = NavigationRouteOptions(waypoints: [userWaypoint, pickUpWaypoint], profileIdentifier: .walking)
           
           _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

               guard let route = routes?.first, error == nil else {
                    completion(nil, error!.localizedDescription)
                   return
               }
               

               guard route.coordinateCount > 0 else {
                
                completion(nil, "Route has no coordinates")
                return
                
            }
            
            self.currentCarpoolSearchResult.riderTimeToPickUpLocation = route.expectedTravelTime/60
               
               
               completion(nil, nil)


           }
       }
       
    
    
    private func fetchDriverRouteToPreplannedPickUpLocation(driverID: String, pickUp: CLLocationCoordinate2D, completion: @escaping result_errordescription_block) {
            
            
            
            let driverLocation = RiderDataManager.shared.lastLocationForDriver(driverID: driverID)
            
            let driverWaypoint = Waypoint(location: CLLocation(latitude: driverLocation!.latitude, longitude: driverLocation!.longitude))
            let pickUpWaypoint = Waypoint(coordinate: pickUp)
             
            let options = NavigationRouteOptions(waypoints: [driverWaypoint, pickUpWaypoint], profileIdentifier: .walking)
            
            _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

                guard let route = routes?.first, error == nil else {
                    completion(nil, error!.localizedDescription)
                    return
                }
                

                guard route.coordinateCount > 0 else {
                     completion(nil, "Route has no coordinates")
                     return
                 
                 }
             
             
                
             
                 self.currentCarpoolSearchResult.driverTimeToPickUpLocation = route.expectedTravelTime/60
                 completion(nil, nil)
             
                
                
               


            }
        }
     
    
       
   private func fetchDriverRouteToPickUpLocation(driverID: String, pickUp: CLLocationCoordinate2D, completion: @escaping result_errordescription_block) {
           
           
           
           let driverLocation = RiderDataManager.shared.lastLocationForDriver(driverID: driverID)
           
           let driverWaypoint = Waypoint(location: CLLocation(latitude: driverLocation!.latitude, longitude: driverLocation!.longitude))
           let pickUpWaypoint = Waypoint(coordinate: pickUp)
            
           let options = NavigationRouteOptions(waypoints: [driverWaypoint, pickUpWaypoint], profileIdentifier: .walking)
           
           _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

               guard let route = routes?.first, error == nil else {
                   completion(nil, error!.localizedDescription)
                   return
               }
               

               guard route.coordinateCount > 0 else {
                    completion(nil, "Route has no coordinates")
                    return
                
                }
            
            
               
            
                self.currentCarpoolSearchResult.driverTimeToPickUpLocation = route.expectedTravelTime/60
                completion(nil, nil)
            
               
               
              


           }
       }
    
    
    

    
    // MARK: - Present carpool status UI
    
    @objc private func dismissNonblockingBadgeView() {
        
        if currentBadgeView != nil {
            currentBadgeView!.removeFromSuperview()
        }
    }
    
    private func showRequestUpdateBadgeView(title: String, actionTitle: String?, action: Selector?) {
        
        dismissNonblockingBadgeView()
    
        
            let window = UIApplication.shared.keyWindow!
            
            currentBadgeView = RequestUpdateBadgeView.instanceFromNib()
            currentBadgeView!.titleLabel.text = title
        
            if actionTitle != nil {
                currentBadgeView!.actionButton.setTitle(actionTitle)
                currentBadgeView!.actionButton.removeTarget(self, action: nil, for: .touchUpInside)
                currentBadgeView!.actionButton.addTarget(self, action: action!, for: .touchUpInside)
            } else {
                currentBadgeView!.actionButton.backgroundColor = .white
                currentBadgeView!.actionButton.setTitleColor(.black, for: .normal)
                currentBadgeView!.actionButton.setTitle("OK")
                currentBadgeView!.actionButton.removeTarget(self, action: nil, for: .touchUpInside)
                currentBadgeView!.actionButton.addTarget(self, action: #selector(dismissNonblockingBadgeView), for: .touchUpInside)
                
            }
            
            
            

           
            window.addSubview(currentBadgeView!)
            
    //        view.easy.layout(Edges(UIEdgeInsets(top: 0, left: 10, bottom: 5, right: 10)))
            currentBadgeView!.easy.layout(
                Height(100),
                Bottom(10).to(window),
              Left(10).to(window),
              Right(10).to(window)
            )
            
            currentBadgeView!.animate()
            
            
    }
        
    

   
    private func showRequestUpdate(title: String, subtitle: String?) {
        let waitingConfirmationPage =  BulletinDataSource.makeCarpoolWaitingForConfirmationPage(title: title)
        
        if subtitle != nil {
            waitingConfirmationPage.descriptionText = subtitle
        }
        
        if self.activeCarpoolAcceptStatus == .rejected || self.activeCarpoolAcceptStatus == .accepted {
            
            waitingConfirmationPage.isDismissable = true;
            waitingConfirmationPage.alternativeButtonTitle = nil
            
        } else {
            
            waitingConfirmationPage.alternativeHandler = { (item: BLTNActionItem) in
                 self.cancelCarpool()
                 self.bulletinManager!.dismissBulletin()
            }
        }
        

        
        waitingConfirmationPage.dismissalHandler = { (item: BLTNItem) in
//            self.showFloatingCarpoolCancelButton()
        }
        
        
        if (!bulletinManager!.isShowingBulletin) {
            
            bulletinManager = BLTNItemManager(rootItem: waitingConfirmationPage)
            bulletinManager!.backgroundViewStyle = .dimmed
            
            bulletinManager!.showBulletin(above: self.presentingViewController!)
            
        } else {
           self.bulletinManager?.push(item: waitingConfirmationPage)

        }
        
       
        
        
    }
    
    private func showCarpoolPaymentView() {
        
    }
    
    private func showProximityAlert() {
 
        dismissNonblockingBadgeView()
        
//        self.showRequestUpdateBadgeView(title: "Your driver is here", actionTitle: nil, action: nil)
            
        let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolSearchResult.carpoolDistance!)

        let carpoolConfirm = BulletinDataSource.makeCarpoolRequestPage(


            title: "Confirm carpool",
            photoURL: self.currentCarpoolSearchResult.driverDetails!.photoURL!, mainTitle: "Your driver is here!", subtitle: "You are ready to start the ride", priceText: "price: $\(priceStringForDistance)")



        carpoolConfirm.actionButtonTitle = "Confirm & start"
        carpoolConfirm.actionHandler = { (item: BLTNActionItem) in

            item.manager?.dismissBulletin()
            self.confirmCarpoolForCarpoolSearchResult(result: self.currentCarpoolSearchResult)
            self.showRequestUpdateBadgeView(title: "Your ride starts now", actionTitle: nil, action: nil)


        }


        carpoolConfirm.alternativeHandler = { (item: BLTNActionItem) in

            self.cancelCarpool()
            item.manager?.dismissBulletin()
            self.didSendRequestBlock!(nil,"You cancelled your ride")

        }

        if (!bulletinManager!.isShowingBulletin) {

            bulletinManager = BLTNItemManager(rootItem: carpoolConfirm)
            bulletinManager!.backgroundViewStyle = .dimmed

            bulletinManager!.showBulletin(above: self.presentingViewController!)

        } else {
            self.bulletinManager?.push(item: carpoolConfirm)

        }

        
        
    }
    
    
     // TODO: remove fake date
    private func showPreplannedCarpoolSuggestion() {
        
            let date = Date().addingTimeInterval(200000)
//          let date = Date.dateFromISOString(string:  self.currentCarpoolSearchResult.carpooPreplannedDateString!)
        
        
             let formatedTime = Converters.getFormattedDate(date: date, format: "HH:mm")
             let formatedDate = Converters.getFormattedDate(date: date, format: "MMM - D")
             
             let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolSearchResult.carpoolDistance!)
             let carpoolRequest = BulletinDataSource.makeCarpoolRequestPage(
                 
                 
                title: "Ride with \(self.currentCarpoolSearchResult.driverDetails!.name!) \(Converters.getRelativeDate(date: date))",
                 photoURL: self.currentCarpoolSearchResult.driverDetails!.photoURL!, mainTitle: "Pickup at ca. \(formatedTime)", subtitle: "Meet \(self.currentCarpoolSearchResult.driverDetails!.name!) on \(formatedDate)", priceText: "price: $\(priceStringForDistance)")
             
             

             carpoolRequest.actionHandler = { (item: BLTNActionItem) in
                 
                 self.didSendRequestBlock!("We have sent request to the driver",nil)
                 self.showRequestUpdate(title: "Waiting for confirmation", subtitle: nil)
                 self.requestCarpoolForCarpoolSearchResult(result: self.currentCarpoolSearchResult)
                 carpoolRequest.manager?.dismissBulletin()

                 
             }
             

             carpoolRequest.alternativeHandler = { (item: BLTNActionItem) in
                 self.cancelCarpool()
                 carpoolRequest.manager?.dismissBulletin()
                 self.didSendRequestBlock!(nil,"You cancelled the request")
                 
             }
             
             
             bulletinManager = BLTNItemManager(rootItem: carpoolRequest)
             bulletinManager!.backgroundViewStyle = .dimmed
             
             bulletinManager!.showBulletin(above: self.presentingViewController!)
    }
    
    private func showCarpoolSuggestion() {
        
        guard self.currentCarpoolSearchResult.filled() else {
            
            return
        }
        
        OnboardingManager.shared.showRiderCarpoolInfoOverlayOnboarding { (didFinish) in
            
            self.presentCarpoolAlert()
        }

        
       


        
    }
    
    
    private func presentCarpoolAlert() {
      
        let timeOfRendevous = Date().addingTimeInterval(self.currentCarpoolSearchResult.riderTimeToPickUpLocation!*60)
        let formatedTime = Converters.getFormattedDate(date: timeOfRendevous, format: "HH:mm")
        
        let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolSearchResult.carpoolDistance!)
        let carpoolRequest = BulletinDataSource.makeCarpoolRequestPage(
            
            
            title: "Ride with \(self.currentCarpoolSearchResult.driverDetails!.name!)",
            photoURL: self.currentCarpoolSearchResult.driverDetails!.photoURL!, mainTitle: "Pickup at ca. \(formatedTime)", subtitle: "Meet \(self.currentCarpoolSearchResult.driverDetails!.name!) in: \( Int(self.currentCarpoolSearchResult.riderTimeToPickUpLocation ?? 0) ) minutes ", priceText: "price: $\(priceStringForDistance)")
        
        

        carpoolRequest.actionHandler = { (item: BLTNActionItem) in
            
            self.didSendRequestBlock!("We have sent request to the driver",nil)
            self.showRequestUpdate(title: "Waiting for confirmation", subtitle: nil)
            self.requestCarpoolForCarpoolSearchResult(result: self.currentCarpoolSearchResult)
            carpoolRequest.manager?.dismissBulletin()

            
        }
        

        carpoolRequest.alternativeHandler = { (item: BLTNActionItem) in
            self.cancelCarpool()
            carpoolRequest.manager?.dismissBulletin()
            self.didSendRequestBlock!(nil,"You cancelled the request")
            
        }
        
        
        bulletinManager = BLTNItemManager(rootItem: carpoolRequest)
        bulletinManager!.backgroundViewStyle = .dimmed
        
        bulletinManager!.showBulletin(above: self.presentingViewController!)
        
    }
    


    
    
}
