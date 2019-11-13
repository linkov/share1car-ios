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
    
    
    
    func showFeedback() {
        
         let feedbackVC = storyboard!.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
        self.parent!.present(feedbackVC, animated: true, completion: nil)
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
        
        turnByturnNavigationController?.navigationService.stop()
        turnByturnNavigationController?.dismiss(animated: true, completion: {
             self.showFeedback()
        })
        
        routes = nil
        toggleCarpoolButton(active: true)
        
        CarpoolAcceptManager.shared.handleRideCancellation()
        
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
    
    
    

}
