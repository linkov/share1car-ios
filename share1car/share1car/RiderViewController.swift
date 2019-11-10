//
//  RiderViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Mapbox

import Polyline

import MapboxGeocoder
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import Turf

import Loaf
import BLTNBoard

import JGProgressHUD

class RiderViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, NavigationMapViewDelegate {

    
    @IBOutlet weak var mapView: NavigationMapView!
    
    
     let hud = JGProgressHUD(style: .light)
    
    var routeFeatures: [String:MGLPolylineFeature] = [:]
    
    
    var potentialCarpoolRiderTimeToPickUpLocation: TimeInterval?
    var potentialCarpoolDriverTimeToPickUpLocation: TimeInterval?
    var potentialCarpoolDriverID: String?
    
    
    var locationManager = CLLocationManager()
    

    lazy var carpoolAvailablebulletinManager: BLTNItemManager = {
        
                   let page = BLTNPageItem(title: "Car pool with [Name]")
        page.image = UIImage(named: "locationPermission")

        page.descriptionText = "Driver arrives to your pick up point in \( Int(potentialCarpoolDriverTimeToPickUpLocation ?? 0)  ) minutes. You can be at pick up point in \( Int(potentialCarpoolRiderTimeToPickUpLocation ?? 0) ) minutes"
        page.actionButtonTitle = "Send request"
        page.alternativeButtonTitle = "Not now"
        page.actionHandler = { (item: BLTNActionItem) in
            
            RiderDataManager.shared.requestCarpool(driverID: self.potentialCarpoolDriverID!)
        }
        page.alternativeHandler = { (item: BLTNActionItem) in
            page.manager?.dismissBulletin()
            self.removeSourceWithIdentifier(routeID: self.potentialCarpoolDriverID!)
        }       
        
        let rootItem: BLTNItem = page
        
        return BLTNItemManager(rootItem: rootItem)
    }()
    
    
    lazy var bulletinManager: BLTNItemManager = {
        let page = BLTNPageItem(title: "Your location")
        page.image = UIImage(named: "locationPermission")

        page.descriptionText = "We need to know your location to give you accurate updates about carpools near you."
        page.actionButtonTitle = "Allow"
        page.alternativeButtonTitle = "Not now"
        page.actionHandler = { (item: BLTNActionItem) in
            
            page.manager?.dismissBulletin()

            LocationManager.shared.requestLocationPermissions { (didGetPermission) in

                self.mapView.setCenter(self.mapView.userLocation!.coordinate, zoomLevel: 12, animated: false)
                 
            }

        }
        page.alternativeHandler = { (item: BLTNActionItem) in
            page.manager?.dismissBulletin()
        }
        
        let rootItem: BLTNItem = page
        return BLTNItemManager(rootItem: rootItem)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        setupRiderMap()
        
        
        RiderDataManager.shared.getDriversLocationa { (locationsDictionary) in
            
            var points: [MGLPointAnnotation] = []
            
            for (key, value) in locationsDictionary {
                
                let point = MGLPointAnnotation()
                point.title = key
                
                let coordsArray = value as! [Double]
                
                
                point.coordinate = CLLocationCoordinate2D(latitude: coordsArray[0], longitude: coordsArray[1])
                points.append(point)
                
            }
            
            self.mapView.addAnnotations(points)

             
        }
        
        
        RiderDataManager.shared.getAvailableDriverRoutes { (routesDictionary) in
                DispatchQueue.main.async {
                        self.updateRoutesOnMap(routes: routesDictionary)
                }
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    
        if (!LocationManager.shared.locationEnabled()) {
            bulletinManager.showBulletin(above: self)
        } else {
            
            if (LocationManager.shared.validCoordinates(coord: self.mapView.userLocation!.coordinate)) {
                self.mapView.setCenter(self.mapView.userLocation!.coordinate, zoomLevel: 12, animated: false)
            }
           
            Loaf("Tap on map to set your drop off location", state: .info, sender: self).show()
        }
        
    }
    
    
    func setupRiderMap() {
    
        mapView.delegate = self
        mapView.navigationMapViewDelegate = self
        mapView.showsUserLocation = true
        mapView.setZoomLevel(14, animated: false)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(gesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapGesture)
        
        gesture.require(toFail: doubleTapGesture)
        
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
            if let source = self.mapView.style?.source(withIdentifier: driverID) as? MGLShapeSource {
                
                source.shape = feature
                
            } else {
                
                let source = MGLShapeSource(identifier: driverID, features: [feature], options: nil)
                
                // Customize the route line color and width
                let lineStyle = MGLLineStyleLayer(identifier: driverID, source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                
                // Add the source and style layer of the route line to the map
                self.mapView.style?.addSource(source)
                self.mapView.style?.addLayer(lineStyle)
    
            }
            
            
        }
    
    
    func removeSourceWithIdentifier(routeID: String) {
        
        if let source = self.mapView.style?.source(withIdentifier: routeID) as? MGLShapeSource {
            
            self.mapView.style?.removeSource(source)
            
        }
    }
    
    func drawDrivingRouteFromPickUpToDropOffUsingSelectedDriverRoutePoints() {
        
    }

    func fetchWalkingRouteToPickUpLocation(pickUp: CLLocationCoordinate2D) {
        
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(coordinate: userLocation.coordinate)
        let pickUpWaypoint = Waypoint(coordinate: pickUp)
         
        let options = NavigationRouteOptions(waypoints: [userWaypoint, pickUpWaypoint], profileIdentifier: .walking)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                return
            }
            

            guard route.coordinateCount > 0 else { return }
            
            self.potentialCarpoolRiderTimeToPickUpLocation = route.expectedTravelTime/60
            
            self.showCarpoolSuggestion()
           


        }
    }
    
    
    func fetchDriverRouteToPickUpLocation(pickUp: CLLocationCoordinate2D) {
        
        
        
        let driverLocation = RiderDataManager.shared.lastLocationForDriver(driverID: self.potentialCarpoolDriverID!)
        
        guard driverLocation != nil else {
            Alerts.systemErrorAlert(error: "Driver location is nil", inController: self)
            return
        }
        
        let driverWaypoint = Waypoint(location: CLLocation(latitude: driverLocation!.latitude, longitude: driverLocation!.longitude))
        let pickUpWaypoint = Waypoint(coordinate: pickUp)
         
        let options = NavigationRouteOptions(waypoints: [driverWaypoint, pickUpWaypoint], profileIdentifier: .walking)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                return
            }
            

            guard route.coordinateCount > 0 else { return }
            
            self.potentialCarpoolDriverTimeToPickUpLocation = route.expectedTravelTime/60
            
            self.fetchWalkingRouteToPickUpLocation(pickUp: pickUp)


        }
    }
    
    
    func addRiderRoute(feature:MGLPolylineFeature) {

            if let source = self.mapView.style?.source(withIdentifier: "rider-route") as? MGLShapeSource {

                source.shape = feature

            } else {

                let source = MGLShapeSource(identifier: "rider-route", features: [feature], options: nil)

                let lineStyle = MGLLineStyleLayer(identifier: "rider-route", source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
                lineStyle.lineDashPattern = NSExpression(forConstantValue: [2, 1.5])
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)

                self.mapView.style?.addSource(source)
                self.mapView.style?.addLayer(lineStyle)

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
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                return
            }
            

            guard route.coordinateCount > 0 else { return }


            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)

            self.addRiderRoute(feature: polyline)


        }
    }
    

    func findCarpool(currentLocation: CLLocationCoordinate2D, dropOffLocation: CLLocationCoordinate2D ) {
        
        guard (mapView.style?.sources.count)! > 0 else {
            Loaf("There are no car pools available at the moment", state: .info, sender: self).show()
            return
        }
        
        for (key, feature) in routeFeatures {
            
            
            let buffer = UnsafeBufferPointer(start: feature.coordinates, count: Int(feature.pointCount))
            let coordinates = Array(buffer)
            
            let lineStringForDriverRoute = LineString(coordinates)
            
            let closestLocationOnDriverRouteForPickup = lineStringForDriverRoute.closestCoordinate(to: currentLocation)
            let closestLocationOnDriverRouteForDropOff = lineStringForDriverRoute.closestCoordinate(to: dropOffLocation)
            
            
            
            
            
            if (Int(closestLocationOnDriverRouteForPickup!.distance) <= UserSettingsManager.shared.getMaximumPickupDistance()
                && Int(closestLocationOnDriverRouteForDropOff!.distance) <= UserSettingsManager.shared.getMaximumDropoffDistance()
                ) {
                self.potentialCarpoolDriverID = key
                
//                let pickUpLat = closestLocationOnDriverRouteForPickup?.coordinate[0]
//                let pickUpLong = closestLocationOnDriverRouteForPickup?.coordinate[1]
//
//                let pickUpLocation = CLLocationCoordinate2D(latitude: pickUpLat, longitude: pickUpLong)
               
                self.drawRiderRouteFromLocationViaPickUpToDropOff(pickUp: closestLocationOnDriverRouteForPickup!.coordinate, dropOff: dropOffLocation)
                self.fetchDriverRouteToPickUpLocation(pickUp: closestLocationOnDriverRouteForPickup!.coordinate)
                
            
            
            } else {
                
                Loaf("There are no car pools available in 600 meters radius from your current location and your destimation", state: .info, sender: self).show()
            }
            

            
        }
        
        
        
    }
    
    func showCarpoolSuggestion() {
        self.carpoolAvailablebulletinManager.showBulletin(above: self)
    }
    
    
    // MARK: - Actions
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
       
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
         
        findCarpool(currentLocation: mapView.userLocation!.coordinate, dropOffLocation: location)
        print(location)

    }
    
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        

    }
    


    
    // MARK: - NavigationMapViewDelegate
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        
    }
    
    
    
    
     // MARK: - MGLMapViewDelegate
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
    
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
     
        // For better performance, always try to reuse existing annotations.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "driverLocationItem")
         
        // If there is no reusable annotation image available, initialize a new one.
        if(annotationImage == nil) {
            annotationImage = MGLAnnotationImage(image: UIImage(named: "driverLocationItem")!, reuseIdentifier: "driverLocationItem")
        }
         
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {

        return true
    }
     
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

    }

}
