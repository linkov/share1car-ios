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

import EasyPeasy

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
    
    var ETAs:[CLLocationDegrees:String] = [:]
    
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
        
        
        

        Loaf("Long press on map to find a route", state: .custom(.init(backgroundColor: .brandColor, icon: UIImage(named: "add-route"))), sender: self).show()
    }

    override func viewWillAppear(_ animated: Bool) {
        OnboardingManager.shared.changePresentingViewController(viewController: self)
        
        if (LocationManager.shared.locationEnabled()) {
            
            mapView.showsUserLocation = true
            
            LocationManager.shared.findUserLocation { (coord) in
                
                self.mapView.setCenter(coord, zoomLevel: 12, animated: false)
            }
        }
    }
    
    

    func setupDriverMap() {
        
        
        startCarPoolButton.addLightShadow()
        
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

        resultSearchController!.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        resultSearchController!.searchResultsUpdater = locationSearchTVC as UISearchResultsUpdating
        resultSearchController!.searchBar.placeholder = "Search for places"
        
//        resultSearchController!.searchBar.easy.layout(Left(30),Right(30))
        
        searchBarContainerView.addSubview(resultSearchController!.searchBar)
        
//        resultSearchController!.searchBar.layer.cornerRadius = 22
        searchBarContainerView.layer.cornerRadius = 22
        searchBarContainerView.clipsToBounds = true
        

//        resultSearchController!.searchBar.easy.layout(
//            Left(20).to(resultSearchController!.searchBar.superview!, .left),
//            Right(20).to(resultSearchController!.searchBar.superview!, .right)
//        )
        
        resultSearchController!.hidesNavigationBarDuringPresentation = false
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
        
                
        let shouldReturn = OnboardingManager.shared.showOnMapTapOnboardingReturning(mapView: mapView)
        if (shouldReturn) {
            return
        }
        
        
        
         
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
         
        requestRouteOptions(destination: location)
        
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
    
    func showETAsForRoutes() {
        
        
        for route in self.routes ?? [] {
            guard route.coordinateCount > 0 else { return }
            
            let routeCenterCoordinate = route.coordinates![route.coordinates!.count/2]
            let annotation = MGLPointAnnotation()
            annotation.coordinate = routeCenterCoordinate
            let str:String = String(format:"%.0f", route.expectedTravelTime/60)
            ETAs[annotation.coordinate.latitude] = "\(str) min"
             
            // Add marker `hello` to the map.
            mapView.addAnnotation(annotation)
            
        }
    }
    
    
    func requestRouteOptions(destination: CLLocationCoordinate2D) {
        
        if mapView.annotations != nil {
            mapView.removeAnnotations(mapView!.annotations!)
        }
        
        
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "user")
        let destinationWaypoint = Waypoint(coordinate: destination)
         
        let options = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
         
        hud.show(in: self.view)
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let routes = routes else {
                Loaf("No routes found", state: .info, sender: self).show()
                return
                
                
            }
            self.routes = routes
            self.mapView?.showRoutes(routes)
            self.mapView?.showWaypoints(self.currentRoute!)
            self.showETAsForRoutes()
            self.toggleCarpoolButton(active: true)
            self.hud.dismiss()
        }
    }
    
    

    
     // MARK: - Actions
    
    @IBAction func onCarpoolTap(_ sender: Any) {
        
//        let shouldReturn = OnboardingManager.shared.showCarpoolOverlayOnboardingReturning(carpoolButton: self.startCarPoolButton)
//        if shouldReturn {
//            return
//        }
    
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
        
        CarpoolAcceptManager.shared.configure(activeRoute: route, mapView: mapView, presentingViewController: self.turnByturnNavigationController!)
        
        DriverDataManager.shared.setRoute(route: route, driverID: AuthManager.shared.currentUserID()!)
        
        self.show(self.turnByturnNavigationController!, sender: self)
        
    }

    
     // MARK: - NavigationViewControllerDelegate
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        print("navigationViewControllerDidDismiss")
        
        navigationViewController.navigationService.stop()
        turnByturnNavigationController?.dismiss(animated: true, completion: {
           
        })
        
        mapView.removeAnnotations(mapView!.annotations!)
        
        routes = nil
        toggleCarpoolButton(active: false)
        
        CarpoolAcceptManager.shared.handleRideCancellation()
        
        DriverDataManager.shared.removeRoute(driverID: AuthManager.shared.currentUserID()!)
    
         NotificationCenter.default.post(name: NotificationsManager.onFeedbackScreenRequestedNotification, object: nil)
         
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
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        let eta = ETAs[annotation.coordinate.latitude]
        
        if eta == nil {
            return nil
        }

        let myClassNib = UINib(nibName: "RouteETAAnnotationView", bundle: nil)
        let annotationView = myClassNib.instantiate(withOwner: nil, options: nil)[0] as! RouteETAAnnotationView
        annotationView.setup(eta: eta!)
        annotationView.bounds = CGRect(x: 0, y: 0, width: 60, height: 20)

         
        return annotationView
    }
     
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    

}

