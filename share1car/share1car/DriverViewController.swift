//
//  DriverViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

import JGProgressHUD
import Loaf

import Spring

class DriverViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate, NavigationMapViewDelegate {

    @IBOutlet weak var startCarPoolButton: SpringButton!
    @IBOutlet weak var searchBarContainerView: UIView!
    @IBOutlet weak var mapView: NavigationMapView!
    
    
    let hud = JGProgressHUD(style: .light)
        
    let geocoder = Geocoder.shared
    
    var resultSearchController: UISearchController?
    
    var turnByturnNavigationController: NavigationViewController?
    
    var currentRouteJSONString: String?
    
    
    
    var currentRoute: Route? {
        get {
                return routes?.first
            }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    var routes: [Route]? {
        didSet {
            guard let routes = routes, let current = routes.first else { mapView.removeRoutes(); return }
            mapView.showRoutes(routes)
            mapView.showWaypoints(current)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startCarPoolButton.layer.cornerRadius = 8
        
        setupDriverMap()
        setupSearch()
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        Loaf("Long press on map to find a route", state: .custom(.init(backgroundColor: .brandColor, icon: UIImage(named: "add-route"))), sender: self).show()
    }
    
    

    func setupDriverMap() {
    
        mapView.navigationMapViewDelegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setZoomLevel(14, animated: false)
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(gesture)
    }
    
    func setupSearch() {
        
        let locationSearchTVC = storyboard!.instantiateViewController(withIdentifier: "SearchTableViewController") as! SearchTableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTVC)
        resultSearchController!.searchResultsUpdater = locationSearchTVC as UISearchResultsUpdating
        resultSearchController!.searchBar.placeholder = "Search for places"
        searchBarContainerView.addSubview(resultSearchController!.searchBar)
        
        resultSearchController!.hidesNavigationBarDuringPresentation = false
        resultSearchController!.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTVC.currentUserLocation = mapView.userLocation
        locationSearchTVC.completion = { (location, didCancel) in
            

            self.resultSearchController?.dismiss(animated: true, completion: nil)
            self.requestRouteOptions(destination:  location!)
//            self.drawRoute(origin: (self.mapView.userLocation!.coordinate), destination: location!)
            self.toggleCarpoolButton(active: true)
            
        }
    }
    
    
    func removeRouteWithIdentifier(driverID: String) {
        
        if let source = self.mapView.style?.source(withIdentifier: driverID) as? MGLShapeSource {
            
            self.mapView.style?.removeSource(source)
            
        }
    }
    


    

    
     
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
         
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
         
        requestRouteOptions(destination: location)
        toggleCarpoolButton(active: true)
    }
    
    func toggleCarpoolButton(active: Bool) {
        
        if (active) {
            startCarPoolButton.animation = "fadeInUp"
            startCarPoolButton.animate()
        } else {
            startCarPoolButton.animation = "fadeOut"
            startCarPoolButton.animate()
        }
        
    }
    
//    func startNavigation() {
//
////        let origin = mapView.userLocation?.coordinate
////        let destination = currentDestination
//
//        guard let origin = mapView.userLocation?.coordinate, let destination = currentDestination else {
//            Alerts.systemErrorAlert(error: "Origin or destination of the route was not set", inController: self)
//            return
//        }
//
//        let options = NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
//
//        Directions.shared.calculate(options) { (waypoints, routes, error) in
//            guard let route = routes?.first, error == nil else {
//                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
//                return
//            }
//
//
//            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
//            let navigationService = MapboxNavigationService(route: route, simulating: .always)
//            let navigationOptions = NavigationOptions(navigationService: navigationService)
//            self.turnByturnNavigationController = NavigationViewController(for: route, options: navigationOptions)
//            self.turnByturnNavigationController!.modalPresentationStyle = .fullScreen
//            self.turnByturnNavigationController!.delegate = self
//
//            DriverDataManager.shared.setRoute(routeString: self.currentRouteJSONString!, driverID: AuthManager.shared.currentUserID()!)
//
//            self.present(self.turnByturnNavigationController!, animated: true, completion: nil)
//
//        }
//
//
//    }
    
    
    
    func requestRouteOptions(destination: CLLocationCoordinate2D) {
        
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "user")
        let destinationWaypoint = Waypoint(coordinate: destination)
         
        let options = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
         
        hud.show(in: self.view)
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let routes = routes else { return }
            self.routes = routes
            self.mapView?.showRoutes(routes)
            self.mapView?.showWaypoints(self.currentRoute!)
            self.hud.dismiss()
        }
    }
    
    
    
    
     // MARK: - Actions
    
    @IBAction func onCarpoolTap(_ sender: Any) {
        

        guard let route = currentRoute else { return }
        
        if (!AuthManager.shared.isLoggedIn()) {
            AuthManager.shared.presentAuthUIFrom(controller: self)
            return
        }
        
        var simMode:SimulationMode
        
        if (UserSettingsManager.shared.getShouldSimulateMovement()) {
            simMode = .always
        } else {
            simMode = .never
        }
        
        let navigationService = MapboxNavigationService(route: route, simulating: simMode)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        self.turnByturnNavigationController = NavigationViewController(for: route, options: navigationOptions)
        self.turnByturnNavigationController!.modalPresentationStyle = .fullScreen
        self.turnByturnNavigationController!.delegate = self
        
        DriverDataManager.shared.setRoute(route: route, driverID: AuthManager.shared.currentUserID()!)
        
        self.present(self.turnByturnNavigationController!, animated: true, completion: nil)
        
    }
    
    
//    func fetchDriverRoute() {
//
//        DriverDataManager.shared.getExistingDriverRoute(driverID: AuthManager.shared.currentUserID()!) { (route, error) in
//
//            if error != nil {
//                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
//                return
//            }
//
//            guard route != nil else {
//
//                Alerts.systemErrorAlert(error: "Driver route is empty", inController: self)
//                return
//
//            }
//
//            let data = Data(route!.utf8)
//            let feature = try! MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLPolylineFeature
//
//            let buffer = UnsafeBufferPointer(start: feature.coordinates, count: Int(feature.pointCount))
//            let coordinates = Array(buffer)
//
//            self.currentDestination = coordinates.last!
//            self.drawRouteFeature(driverID: AuthManager.shared.currentUserID()!, feature: feature)
//            self.toggleCarpoolButton(active: true)
//
//
//        }
//
//    }
    
    
     // MARK: - NavigationViewControllerDelegate
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        print("navigationViewControllerDidDismiss")
        
        turnByturnNavigationController?.navigationService.stop()
        turnByturnNavigationController?.dismiss(animated: true, completion: nil)
        
        routes = nil
        toggleCarpoolButton(active: false)
        
       DriverDataManager.shared.removeRoute(driverID: AuthManager.shared.currentUserID()!)
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        print("navigationViewController didUpdate")
        print("progress: \(progress)")
        print("location: \(location)")
        print("rawLocation: \(rawLocation)")
        
        DriverDataManager.shared.setCurrentLocation(location: location.coordinate, driverID: AuthManager.shared.currentUserID()!)
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        print("navigationViewController willArriveAt")
               print("waypoint: \(waypoint)")
               print("remainingTimeInterval: \(remainingTimeInterval)")
               print("distance: \(distance)")
    }
    
    
    
    
    // MARK: - NavigationMapViewDelegate
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        
        self.currentRoute = route
    }
    
    
     // MARK: - MGLMapViewDelegate
    
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        
        self.mapView.setCenter(self.mapView.userLocation!.coordinate, zoomLevel: 12, animated: false)
    }
    
    
    
//    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
//
//        guard let userLocation = mapView.userLocation else {
//            return
//        }
//
////        if (AuthManager.shared.isLoggedIn()) {
////            fetchDriverRoute()
////        }
//
//
//        mapView.setCenter(userLocation.coordinate, zoomLevel: 12, animated: false)
//    }
    
//    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
//    // Always allow callouts to popup when annotations are tapped.
//        return true
//    }
//
//    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
//
//    }

}
