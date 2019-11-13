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
    

    var didSendRequestBlock: didfinish_block?
    
    var activeCarpoolStatus: CarpoolRequestStatus?
    var driversLocations: [String : MGLPointAnnotation] = [:]
    
    var carpoolSearchResultBlock: carpool_search_result_error_block?
    var currentCarpoolSearchResult = S1CCarpoolSearchResult()
    
    var bulletinManager: BLTNItemManager?

    var mapView: NavigationMapView?
    var presentingViewController: UIViewController?
    
    var routeFeatures: [String:MGLPolylineFeature] = [:]
    
    static let shared = CarpoolSearchManager()

     override init(){
        super.init()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolAcceptNotificationReceivedNotification, object: nil)

    
        
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        let info = Converters.userInfoFromRemoteNotification(userInfo: notification.userInfo!)
        let title = info.title
        Loaf(title, state: .info, sender: self.presentingViewController!).show()
    }
    
    
    func configureAndStartSubscriptions(mapView: NavigationMapView, presentingViewController: UIViewController) {
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
        
        RiderDataManager.shared.getDriversLocationa { (locationsDictionary) in
        
            
             self.mapView!.removeAnnotations(self.mapView!.annotations ?? [])
            
            for (key, value) in locationsDictionary {
                
                let point = MGLPointAnnotation()
                point.title = key
                
                let coordsArray = value as! [Double]
                
                
                point.coordinate = CLLocationCoordinate2D(latitude: coordsArray[0], longitude: coordsArray[1])
                
                
                
                self.driversLocations[key] = point
                self.mapView!.addAnnotation(point)
            }
            
    
           
            

             
        }
        
    }
    
    
    func updateRoutesOnMap(routes: [String : String]) {
        
        mapView?.removeRoutes()
        
        for (key, value) in routes {
            
            if (AuthManager.shared.currentUserID() != nil) {
                
                if (key != AuthManager.shared.currentUserID()!) {
                    
                    let data = Data(value.utf8)
                    let feature = try! MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLPolylineFeature
                    
                    routeFeatures[key] = feature
                    drawRouteFeature(driverID: key, feature: feature)
                    
                }
                
            } else {
                
                let data = Data(value.utf8)
                let feature = try! MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLPolylineFeature
                
                routeFeatures[key] = feature
                drawRouteFeature(driverID: key, feature: feature)
            }
            

            

         
        }
        
    }
    
    func drawRouteFeature(driverID:String, feature:MGLPolylineFeature) {


            // If there's already a route line on the map, reset its shape to the new route
        if let source = self.mapView?.style?.source(withIdentifier: driverID) as? MGLShapeSource {
                
                source.shape = feature
                
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
                Alerts.systemErrorAlert(error: error!, inController: self.presentingViewController!)
                return
            }
            
            self.fetchWalkingRouteToPickUpLocation(currentLocation: currentLocation, pickUp: pickUpLocation, completion:  { (result, error) in
                if error != nil {
                    Alerts.systemErrorAlert(error: error!, inController: self.presentingViewController!)
                    return
                }
               
                self.fetchDriverRouteFromPickUpToDropOff(pickup: pickUpLocation, dropoff: self.currentCarpoolSearchResult.dropOffLocation!) { (result, errorString) in
                    
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
    
    
    func findCarpool(currentLocation: CLLocationCoordinate2D, dropOffLocation: CLLocationCoordinate2D , didSendRequest: @escaping didfinish_block ) {
        
        didSendRequestBlock = didSendRequest
        
        
        guard routeFeatures.count > 0 else {
            Loaf("There are no car pools available at the moment", state: .info, sender: self.presentingViewController!).show()
            return
        }
        
        for (key, feature) in routeFeatures {
            
            
            let buffer = UnsafeBufferPointer(start: feature.coordinates, count: Int(feature.pointCount))
            let coordinates = Array(buffer)
            
            let lineStringForDriverRoute = LineString(coordinates)
            let closestLocationOnDriverRouteForPickup = lineStringForDriverRoute.closestCoordinate(to: currentLocation)
            
            
            
            if (Int(closestLocationOnDriverRouteForPickup!.distance) <= UserSettingsManager.shared.getMaximumPickupDistance()) {
                let driverID = key
                
                DataManager.shared.getUserDetails(userID: driverID) { (userDetails, error) in
                    if error != nil {
                        
                        return
                    }
     
                    
                    
                    self.drawRiderRouteFromLocationViaPickUpToDropOff(pickUp: closestLocationOnDriverRouteForPickup!.coordinate, dropOff: dropOffLocation)
                    self.fetchTimingsForCarpool(driverID: userDetails!.UID!, pickUpLocation: closestLocationOnDriverRouteForPickup!.coordinate, currentLocation: currentLocation)
                    
                    self.currentCarpoolSearchResult.driverDetails = userDetails
                    self.currentCarpoolSearchResult.dropOffLocation = dropOffLocation
                    self.currentCarpoolSearchResult.pickUpLocation = closestLocationOnDriverRouteForPickup!.coordinate
                    
                    
                }

                
            
            
            } else {
                
                Loaf("There are no car pools available in \(UserSettingsManager.shared.getMaximumPickupDistance()) meters radius from your current location and your pick up location", state: .info, sender: self.presentingViewController!).show()
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
                completion(nil, "Driver location is nil")
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
    
    
    func addRiderRoute(feature:MGLPolylineFeature) {

            if let source = self.mapView!.style?.source(withIdentifier: "rider-route") as? MGLShapeSource {

                source.shape = feature

            } else {

                let source = MGLShapeSource(identifier: "rider-route", features: [feature], options: nil)

                let lineStyle = MGLLineStyleLayer(identifier: "rider-route", source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
                lineStyle.lineDashPattern = NSExpression(forConstantValue: [2, 1.5])
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)

                self.mapView!.style?.addSource(source)
                self.mapView!.style?.addLayer(lineStyle)

            }


        }


    func drawRiderRouteFromLocationViaPickUpToDropOff(pickUp: CLLocationCoordinate2D, dropOff: CLLocationCoordinate2D ) {

        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "user")
        let pickUpWaypoint = Waypoint(coordinate: pickUp)
        let destinationWaypoint = Waypoint(coordinate: dropOff)
         
        let options = NavigationRouteOptions(waypoints: [userWaypoint, pickUpWaypoint, destinationWaypoint])


        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            

            guard route.coordinateCount > 0 else { return }


            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)

            self.addRiderRoute(feature: polyline)


        }
    }
    
    func requestCarpoolForCarpoolSearchResult(result: S1CCarpoolSearchResult) {
        
        RiderDataManager.shared.requestCarpool(pickUpLocation: result.pickUpLocation!, dropOffLocation: result.dropOffLocation!, driverID: result.driverDetails!.UID!)
        
    }
    
    
    func showCarpoolSuggestion() {
        
        guard self.currentCarpoolSearchResult.filled() else {
            
            return
        }
        let timeOfRendevous = Date().addingTimeInterval(self.currentCarpoolSearchResult.riderTimeToPickUpLocation!*60)
        let formatedTime = Converters.getFormattedDate(date: timeOfRendevous, format: "HH:mm")
        
        let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolSearchResult.carpoolDistance!)
        let carpoolRequest = BulletinDataSource.makeCarpoolRequestPage(
            
            
            title: "Ride with \(self.currentCarpoolSearchResult.driverDetails!.name!)",
            photoURL: self.currentCarpoolSearchResult.driverDetails!.photoURL!, mainTitle: "Pickup at ca. \(formatedTime)", subtitle: "Meet \(self.currentCarpoolSearchResult.driverDetails!.name!) in: \( Int(self.currentCarpoolSearchResult.riderTimeToPickUpLocation ?? 0) ) minutes ", priceText: "price: $\(priceStringForDistance)")
        
        

        carpoolRequest.actionHandler = { (item: BLTNActionItem) in
            
            self.requestCarpoolForCarpoolSearchResult(result: self.currentCarpoolSearchResult)
            self.didSendRequestBlock!(true)
            Loaf("We have sent request to the driver", state: .info, sender: self.presentingViewController!).show()
            carpoolRequest.manager?.dismissBulletin()
            
        }
        

        carpoolRequest.alternativeHandler = { (item: BLTNActionItem) in
            self.removeSourceWithIdentifier(routeID: "rider-route")
            carpoolRequest.manager?.dismissBulletin()
            
        }
        
        carpoolRequest.dismissalHandler =  { (item) in
            self.removeSourceWithIdentifier(routeID: "rider-route")
            carpoolRequest.manager?.dismissBulletin()
                   
        }
        
        bulletinManager = BLTNItemManager(rootItem: carpoolRequest)
        bulletinManager!.backgroundViewStyle = .dimmed
        
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: self.presentingViewController!)
        
        
        

        

        
    }
    

    
    
}
