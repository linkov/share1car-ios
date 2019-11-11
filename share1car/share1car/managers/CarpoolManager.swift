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

class CarpoolManager: NSObject {
    
    
    enum CarpoolRequestStatus: String {
        case requested = "requested"
        case accepted = "accepted"
        case confirmed = "confirmed"
    }
    
    var activeCarpoolStatus: CarpoolRequestStatus?
    
    var bulletinManager: BLTNItemManager?
    
    var potentialCarpoolRiderTimeToPickUpLocation: TimeInterval?
    var potentialCarpoolDriverTimeToPickUpLocation: TimeInterval?
    var potentialCarpoolDriverID: String?
    var potentialCarpoolPickUpLocation: CLLocationCoordinate2D?
    var potentialCarpoolDropOffLocation: CLLocationCoordinate2D?
    
    var mapView: NavigationMapView?
    var presentingViewController: UIViewController?
    
    var routeFeatures: [String:MGLPolylineFeature] = [:]
    
    static let shared = CarpoolManager()

     override init(){
        super.init()
    }
    
    
    func configure(mapView: NavigationMapView, presentingViewController: UIViewController) {
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
            
            var points: [MGLPointAnnotation] = []
            
            for (key, value) in locationsDictionary {
                
                let point = MGLPointAnnotation()
                point.title = key
                
                let coordsArray = value as! [Double]
                
                
                point.coordinate = CLLocationCoordinate2D(latitude: coordsArray[0], longitude: coordsArray[1])
                points.append(point)
                
            }
            
            self.mapView!.addAnnotations(points)

             
        }
        
    }
    
    
    func updateRoutesOnMap(routes: [String : String]) {
        
        
        for (key, value) in routes {
            
            let data = Data(value.utf8)
            let feature = try! MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLPolylineFeature
            
            routeFeatures[key] = feature
            drawRouteFeature(driverID: key, feature: feature)
            
         
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
                self.showCarpoolSuggestion()
            })
            
        })
        
    }
    
    func findCarpool(currentLocation: CLLocationCoordinate2D, dropOffLocation: CLLocationCoordinate2D ) {
        
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
                self.potentialCarpoolDriverID = key

                self.drawRiderRouteFromLocationViaPickUpToDropOff(pickUp: closestLocationOnDriverRouteForPickup!.coordinate, dropOff: dropOffLocation)
                self.fetchTimingsForCarpool(driverID: self.potentialCarpoolDriverID!, pickUpLocation: closestLocationOnDriverRouteForPickup!.coordinate, currentLocation: currentLocation)
                
                self.potentialCarpoolPickUpLocation = closestLocationOnDriverRouteForPickup!.coordinate
                self.potentialCarpoolDropOffLocation = dropOffLocation
                
            
            
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
            
               self.potentialCarpoolRiderTimeToPickUpLocation = route.expectedTravelTime/60
               
               
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
               
            
                self.potentialCarpoolDriverTimeToPickUpLocation = route.expectedTravelTime/60
                completion(nil, nil)
            
               
               
              


           }
       }
    
    
    func removeSourceWithIdentifier(routeID: String) {
        
        if let source = self.mapView!.style?.source(withIdentifier: routeID) as? MGLShapeSource {
            
            self.mapView!.style?.removeSource(source)
            
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
    
    func showCarpoolSuggestion() {
        
        let carpoolRequest = BulletinDataSource.makeCarpoolRequestPage()
        carpoolRequest.actionHandler = { (item: BLTNActionItem) in
            
            RiderDataManager.shared.requestCarpool(pickUpLocation: self.potentialCarpoolPickUpLocation!, dropOffLocation: self.potentialCarpoolDropOffLocation!, driverID: self.potentialCarpoolDriverID!)
        }
        
        carpoolRequest.descriptionText = "Driver arrives to your pick up point in \( Int(potentialCarpoolDriverTimeToPickUpLocation ?? 0)  ) minutes. You can be at pick up point in \( Int(potentialCarpoolRiderTimeToPickUpLocation ?? 0) ) minutes"

        
        carpoolRequest.alternativeHandler = { (item: BLTNActionItem) in
            carpoolRequest.manager?.dismissBulletin()
            self.removeSourceWithIdentifier(routeID: self.potentialCarpoolDriverID!)
        }
        
        bulletinManager = BLTNItemManager(rootItem: carpoolRequest)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: self.presentingViewController!)
        
    }
    
    
    
}
