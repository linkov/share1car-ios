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

import Loaf
import BLTNBoard


class CarpoolSearchManager: NSObject {
    

    var didShowCarpoolPickUpAlert = false
    
    var didSendRequestBlock: result_errordescription_block?
    
    var activeCarpoolAcceptStatus: CarpoolAcceptStatus?
    var driversLocations: [String : MGLPointAnnotation] = [:]
    
    var carpoolSearchResultBlock: carpool_search_result_error_block?
    var currentCarpoolSearchResult = S1CCarpoolSearchResult()
    
    var bulletinManager: BLTNItemManager?
    

    var mapView: NavigationMapView?
    var presentingViewController: RiderViewController?
    
    var routeFeatures: [String:MGLPolylineFeature] = [:]
    
    static let shared = CarpoolSearchManager()

     override init(){
        super.init()
        

        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolAcceptNotificationReceivedNotification, object: nil)


    
        
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        let status = Converters.notificationTypeFromNotificationUserInfo(userInfo: notification.userInfo!)
        
        
        processStatus(status: status)
        

    }
    
    func processStatus(status: String) {

        if status == "accepted" && activeCarpoolAcceptStatus != .accepted  {
            activeCarpoolAcceptStatus = .accepted
            showRequestUpdate(title: "Request accepted", subtitle: "Follow the map to meet the driver at the pick up location")

        }

        if status == "rejected" && activeCarpoolAcceptStatus != .rejected {
            self.cleanup()
            activeCarpoolAcceptStatus = .rejected
            Loaf("Your request was rejected", state: .warning, sender: self.presentingViewController!).show()

        }

        if status == "confirmed" && activeCarpoolAcceptStatus != .confirmed {
            activeCarpoolAcceptStatus = .confirmed
            showRequestUpdate(title: "You ride is starting", subtitle: nil)
        }

        if status == "arrived" && activeCarpoolAcceptStatus != .arrived {
            activeCarpoolAcceptStatus = .arrived
            showRequestUpdate(title: "You arrived", subtitle: nil)
            NotificationCenter.default.post(name: NotificationsManager.onFeedbackScreenRequestedNotification, object: nil)
        }
        
    }
    

    func displayMessage(title: String, cancelBlock: empty_block? ) {
        
        
        let carpoolProgressUpdate = BulletinDataSource.makeCarpoolProgressUpdatePage(
            
            
            title: title, cancelTitle: "Cancel")
        
        

        carpoolProgressUpdate.actionHandler = { (item: BLTNActionItem) in
            
            if cancelBlock != nil {
                cancelBlock!()
                carpoolProgressUpdate.manager?.dismissBulletin()
            }
            
        }
        

        

        
        bulletinManager = BLTNItemManager(rootItem: carpoolProgressUpdate)
        bulletinManager!.backgroundViewStyle = .dimmed
        
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: self.presentingViewController!)
        

    }
    
    func cleanup() {
        activeCarpoolAcceptStatus = nil
        didShowCarpoolPickUpAlert = false
        currentCarpoolSearchResult = S1CCarpoolSearchResult()
        removeSourceWithIdentifier(routeID: "rider-route-in")
        removeSourceWithIdentifier(routeID: "rider-route-out")
        
    }
    
    func cancelCarpool() {
        
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
    
    func configureAndStartSubscriptions(mapView: NavigationMapView, presentingViewController: RiderViewController) {
        self.presentingViewController = presentingViewController
        self.mapView = mapView
        subscribeMapViewToDriverRoutes()
        subscribeMapViewToDriverLocations()
    }
    
    
    func subscribeMapViewToDriverRoutes() {
        
        RiderDataManager.shared.getAvailableDriverRoutes { (routesDictionary) in
                DispatchQueue.main.async {
                        self.updateRoutesOnMap(routes: routesDictionary)
                }
            
        }
    }
    
    func subscribeMapViewToDriverLocations() {
        
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
                
                if  self.didShowCarpoolPickUpAlert == false && self.activeCarpoolAcceptStatus != nil && self.activeCarpoolAcceptStatus! == .accepted && self.currentCarpoolSearchResult.filled() && key == self.currentCarpoolSearchResult.driverDetails!.UID! {
                    
                    let distance = self.mapView?.userLocation?.coordinate.distance(to: point.coordinate)
                    if Int(distance!) < 100 {
                        
                        
                        self.didShowCarpoolPickUpAlert = true
                        self.showProximityAlert()
                        
                        
                    }
                    
                    
                }
                
                
                
                self.driversLocations[key] = point
                self.mapView!.addAnnotation(point)
            }
            
    
           
            

             
        }
        
    }
    
    
    func updateRoutesOnMap(routes: [String : String]) {
        
        for (key, _) in routeFeatures {
            
            removeSourceWithIdentifier(routeID: key)
        }
        
        routeFeatures = [:]
        
        mapView?.removeRoutes()
        
        for (key, value) in routes {
            
//            let data = Data(value.utf8)
            let polyline = Polyline(encodedPolyline: value, precision: 1e6)
            
//            let polyline = Polyline(encodedPolyline: value,
//                                    precision: 6)
            let feature = MGLPolylineFeature(coordinates: polyline.coordinates!, count: UInt(polyline.coordinates!.count))
            
            if AuthManager.shared.isLoggedIn() && key == AuthManager.shared.currentUserID()! {
               
            } else {
                routeFeatures[key] = feature
                drawRouteFeature(driverID: key, feature: feature)
            }
            

            

        }
        
    }
    
    func drawRouteFeature(driverID:String, feature:MGLPolylineFeature) {


            // If there's already a route line on the map, reset its shape to the new route
        if let source = self.mapView?.style?.source(withIdentifier: driverID) as? MGLShapeSource {
                
                source.shape = feature
               
            if let lineStyle = self.mapView?.style?.layer(withIdentifier: driverID) as? MGLLineStyleLayer {
                
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)
            } else {
                let lineStyle = MGLLineStyleLayer(identifier: driverID, source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                self.mapView!.style?.addLayer(lineStyle)
            }
            
                
            } else {
                
                let source = MGLShapeSource(identifier: driverID, features: [feature], options: nil)
                
                // Customize the route line color and width
                let lineStyle = MGLLineStyleLayer(identifier: driverID, source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                
                // Add the source and style layer of the route line to the map
                self.mapView!.style?.addSource(source)
                self.mapView!.style?.addLayer(lineStyle)
    
            }
            
            
        }
    
    
    
    
    

    
    
    func fetchTimingsForCarpool(driverID: String, pickUpLocation: CLLocationCoordinate2D, currentLocation: CLLocationCoordinate2D) {
        
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
    
    
    
    func fetchDriverRouteFromPickUpToDropOff(pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D, completion: @escaping result_errordescription_block ) {
        
        
        //           guard let userLocation = mapView?.userLocation!.location else { return }
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
    
    
    func findCarpool(currentLocation: CLLocationCoordinate2D, destination: CLLocationCoordinate2D , didSendRequest: @escaping result_errordescription_block ) {
        
        didSendRequestBlock = didSendRequest
        
        
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
            
            
            if (Int(closestLocationOnDriverRouteForPickup!.distance) <= UserSettingsManager.shared.getMaximumPickupDistance()) {
                let driverID = key
                
                DataManager.shared.getUserDetails(userID: driverID) { (userDetails, error) in
                    if error != nil {
                        
                        return
                    }
     
                    
                    self.drawRiderRouteFromCurrentLocationToPickUp(pickUp: closestLocationOnDriverRouteForPickup!.coordinate)
                    self.drawRiderRouteFromDropOffToDestination(dropOff: closestLocationOnDriverRouteForDropOff!.coordinate, riderDestination: destination)
                   
                    self.currentCarpoolSearchResult.driverDetails = userDetails
                    self.currentCarpoolSearchResult.dropOffLocation = closestLocationOnDriverRouteForDropOff!.coordinate
                    self.currentCarpoolSearchResult.pickUpLocation = closestLocationOnDriverRouteForPickup!.coordinate
                    
                    self.fetchTimingsForCarpool(driverID: userDetails!.UID!, pickUpLocation: closestLocationOnDriverRouteForPickup!.coordinate, currentLocation: currentLocation)
                    

                    
                    
                }

                
            
            
            } else {
                didSendRequestBlock!(nil,"There are no car pools available in \(UserSettingsManager.shared.getMaximumPickupDistance()) meters radius from your current location and your pick up location")
            }
            

            
        }
        
        
        
    }
    
    func fetchWalkingRouteToPickUpLocation(currentLocation: CLLocationCoordinate2D, pickUp: CLLocationCoordinate2D , completion: @escaping result_errordescription_block) {
           
//           guard let userLocation = mapView?.userLocation!.location else { return }
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
       
       
    func fetchDriverRouteToPickUpLocation(driverID: String, pickUp: CLLocationCoordinate2D, completion: @escaping result_errordescription_block) {
           
           
           
           let driverLocation = RiderDataManager.shared.lastLocationForDriver(driverID: driverID)
           
           guard driverLocation != nil else {
            //MARK: TODO - fetch dates for preplanned rides and be able to request a preplanned ride
//                completion(nil, "Driver location is nil")
                completion(nil, "This carpool is preplanned for future time")
               return
           }
           
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
    
    
    func removeSourceWithIdentifier(routeID: String) {
        
        if let source = self.mapView!.style?.source(withIdentifier: routeID) as? MGLShapeSource {
            
            self.mapView!.style?.removeSource(source)
            
            
            if let layer = self.mapView!.style?.layer(withIdentifier: routeID) {
                self.mapView!.style?.removeLayer(layer)
            }
            
            
        }
    }
    
    
    
    
    func addRiderRoute(feature:MGLPolylineFeature, identifier: String) {

            if let source = self.mapView!.style?.source(withIdentifier: identifier) as? MGLShapeSource {

                source.shape = feature

            } else {

                let source = MGLShapeSource(identifier: identifier, features: [feature], options: nil)

                let lineStyle = MGLLineStyleLayer(identifier: identifier, source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
                lineStyle.lineDashPattern = NSExpression(forConstantValue: [2, 1.5])
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)

                self.mapView!.style?.addSource(source)
                self.mapView!.style?.addLayer(lineStyle)

            }


        }

    
    func drawRiderRouteFromCurrentLocationToPickUp(pickUp: CLLocationCoordinate2D) {
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "Current location")
        let pickUpWaypoint = Waypoint(coordinate: pickUp)
        let options = NavigationRouteOptions(waypoints: [userWaypoint, pickUpWaypoint], profileIdentifier: .walking)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            

            guard route.coordinateCount > 0 else { return }


            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)

            self.addRiderRoute(feature: polyline, identifier: "rider-route-in")
            

        }
    }
    
    
    func drawRiderRouteFromDropOffToDestination(dropOff: CLLocationCoordinate2D, riderDestination: CLLocationCoordinate2D) {

        let dropOffWaypoint = Waypoint(coordinate: dropOff)
        let riderDestinationWaypoint = Waypoint(coordinate: riderDestination)
        let options = NavigationRouteOptions(waypoints: [dropOffWaypoint, riderDestinationWaypoint], profileIdentifier: .walking)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            

            guard route.coordinateCount > 0 else { return }


            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)

            self.addRiderRoute(feature: polyline, identifier: "rider-route-out")
            

        }
    }
    
    
    func confirmCarpoolForCarpoolSearchResult(result: S1CCarpoolSearchResult) {
    
        RiderDataManager.shared.confirmCarpool(driverID: result.driverDetails!.UID!)
    }

    
    func requestCarpoolForCarpoolSearchResult(result: S1CCarpoolSearchResult) {
                
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
    
    func showFloatingCarpoolCancelButton() {
        self.presentingViewController!.toggleCancelCarpoolButton(active: true)
    }
    
    

    
    func showRequestUpdate(title: String, subtitle: String?) {
        let waitingConfirmationPage =  BulletinDataSource.makeCarpoolWaitingForConfirmationPage(title: title)
        
        if subtitle != nil {
            waitingConfirmationPage.descriptionText = subtitle
        }
        
        waitingConfirmationPage.alternativeHandler = { (item: BLTNActionItem) in
             self.cancelCarpool()
             self.bulletinManager!.dismissBulletin()
        }
        
        waitingConfirmationPage.dismissalHandler = { (item: BLTNItem) in
//            self.showFloatingCarpoolCancelButton()
        }
        
        
        self.bulletinManager?.push(item: waitingConfirmationPage)
        
        
    }
    
    func showProximityAlert() {
 
            
        let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolSearchResult.carpoolDistance!)
        
        let carpoolConfirm = BulletinDataSource.makeCarpoolRequestPage(
            
            
            title: "Confirm carpool",
            photoURL: self.currentCarpoolSearchResult.driverDetails!.photoURL!, mainTitle: "Your driver is here!", subtitle: "You are 100 meters away from driver", priceText: "price: $\(priceStringForDistance)")
        
        

        carpoolConfirm.actionButtonTitle = "Confirm & start"
        carpoolConfirm.actionHandler = { (item: BLTNActionItem) in
            
            self.confirmCarpoolForCarpoolSearchResult(result: self.currentCarpoolSearchResult)
            self.showRequestUpdate(title: "Your ride starts now", subtitle: nil)

            
        }
        

        carpoolConfirm.alternativeHandler = { (item: BLTNActionItem) in
            
            self.cancelCarpool()
            carpoolConfirm.manager?.dismissBulletin()
            self.didSendRequestBlock!(nil,"You cancelled your ride")
            
        }
        
        self.bulletinManager?.push(item: carpoolConfirm)
    }
    
    
    
    func showCarpoolSuggestion() {
        
        guard self.currentCarpoolSearchResult.filled() else {
            
            return
        }
        
        OnboardingManager.shared.showRiderCarpoolInfoOverlayOnboarding { (didFinish) in
            
            self.presentCarpoolAlert()
        }

        
       


        
    }
    
    
    func presentCarpoolAlert() {
      
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

            
        }
        

        carpoolRequest.alternativeHandler = { (item: BLTNActionItem) in
            self.cancelCarpool()
            carpoolRequest.manager?.dismissBulletin()
            self.didSendRequestBlock!(nil,"You cancelled the request")
            
        }
        
        
        bulletinManager = BLTNItemManager(rootItem: carpoolRequest)
        bulletinManager!.backgroundViewStyle = .none
        
        bulletinManager!.showBulletin(above: self.presentingViewController!)
        
    }
    

    
    
}
