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


import BLTNBoard

class DriverViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate, NavigationMapViewDelegate {

    @IBOutlet weak var cancelPreplannedCarpoolButton: SpringButton!
    @IBOutlet weak var startPlannedCarpoolSelector: SpringButton!
    @IBOutlet weak var startCarPoolButton: SpringButton!
    @IBOutlet weak var searchBarContainerView: UIView!
    @IBOutlet weak var mapView: NavigationMapView!
    
    @IBOutlet weak var userLocationButton: UIButton!
    var preplannedCarpoolDate: Date?
    
    var bulletinManager: BLTNItemManager?
    
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
        
        startCarPoolButton.layer.cornerRadius = 22
        startPlannedCarpoolSelector.layer.cornerRadius = 22
        cancelPreplannedCarpoolButton.layer.cornerRadius = 22
        cancelPreplannedCarpoolButton.addLightShadow()
        
        userLocationButton.layer.cornerRadius = 22
        userLocationButton.addLightShadow()
        
        let timeOfNow = Date().addingTimeInterval(10*60)
        let formatedTime = Converters.getFormattedDate(date: timeOfNow, format: "MMM dd HH:mm")
        startPlannedCarpoolSelector.setTitle("Abfahrt: \(formatedTime)", for: .normal)
        
        setupDriverMap()
        setupSearch()

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
    
    override func viewDidAppear(_ animated: Bool) {
    
        if AuthManager.shared.isLoggedIn() {
            
            DriverDataManager.shared.fetchPreplannedCarpool { (result, errorString) in
                
                if result != nil {
                    let dateString = result
                    self.preplannedCarpoolDate = Date.dateFromISOString(string: dateString as! String)
                    self.toggleCarpoolButton(active: true)
                    self.toggleUIForActivePreplannedCarpool(active: true)
                }
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
        resultSearchController!.searchResultsUpdater = locationSearchTVC as UISearchResultsUpdating
        resultSearchController!.searchBar.placeholder = "Search for places"
        resultSearchController!.searchBar.addLightShadow()
        searchBarContainerView.addSubview(resultSearchController!.searchBar)
        
        searchBarContainerView.layer.cornerRadius = 22
        searchBarContainerView.clipsToBounds = true
        
        resultSearchController!.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        locationSearchTVC.currentUserLocation = mapView.userLocation
        locationSearchTVC.completion = { (location, didCancel) in
            

            self.resultSearchController?.dismiss(animated: true, completion: nil)
            self.requestRouteOptions(destination:  location!)
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
            
            startPlannedCarpoolSelector.animation = "zoomIn"
            startPlannedCarpoolSelector.animate()

            
        } else {
            
            
            startPlannedCarpoolSelector.animation = "zoomOut"
            startPlannedCarpoolSelector.animate()
            
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
            self.mapView.setVisibleCoordinateBounds(MGLCoordinateBounds(sw: (self.currentRoute?.coordinates?.first)!, ne: (self.currentRoute?.coordinates?.last)!), edgePadding: UIEdgeInsets(top: 120, left: 120, bottom: 180, right: 120), animated: true) {
                
            }
            self.toggleCarpoolButton(active: true)
            self.hud.dismiss()
            
            OnboardingManager.shared.showCarpoolOverlayOnboarding(carpoolButton: self.startCarPoolButton, plannedCarpoolButton: self.startPlannedCarpoolSelector)

            
        }
    }
    
    

    
     // MARK: - Actions
    @IBAction func onPlannedCarpoolTap(_ sender: Any) {
        
        
                let timeOfNow = Date().addingTimeInterval(10*60)
               

               let carpoolPlanning = BulletinDataSource.makeDatePage()
                carpoolPlanning.actionHandler = { item in
                
                    carpoolPlanning.manager?.dismissBulletin()
                   
                }

                carpoolPlanning.datePicker.setDate(timeOfNow, animated: true)
                carpoolPlanning.datePicker.addTarget(self, action: #selector(carpoolDatePickerChanged(picker:)), for: .valueChanged)

                       
               
//
//               carpoolPlanning.actionHandler = { (item: BLTNActionItem) in
//
//
//               }
//
//
//               carpoolPlanning.alternativeHandler = { (item: BLTNActionItem) in
//
//
//               }
//

               
               bulletinManager = BLTNItemManager(rootItem: carpoolPlanning)
               bulletinManager!.backgroundViewStyle = .dimmed
               
               bulletinManager!.statusBarAppearance = .hidden
               bulletinManager!.showBulletin(above: self)
        
        
    }
    
    @IBAction func userLocationDidTap(_ sender: Any) {
        
        LocationManager.shared.findUserLocation { (coord) in
            
            self.mapView.setCenter(coord, zoomLevel: 12, animated: true)
        }
        
    }
    
    @objc func carpoolDatePickerChanged(picker: UIDatePicker) {
        print(picker.date)
        if picker.date >  Date().addingTimeInterval(10*60) {
            preplannedCarpoolDate = picker.date
        }
        
        let formatedTime = Converters.getFormattedDate(date: picker.date, format: "MMM dd HH:mm")
        startPlannedCarpoolSelector.setTitle("Abfahrt: \(formatedTime)", for: .normal)
    }
    
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
        
        if preplannedCarpoolDate != nil {
            
            
           let shouldReturn = OnboardingManager.shared.showPlannedCarpoolOverlayReturning()
            if shouldReturn {
                return
            }
            hud.show(in: self.view)
            DriverDataManager.shared.addPreplannedCarpool(date: preplannedCarpoolDate!, completion: { (result, errorString) in
                self.hud.dismiss()
                if errorString != nil {
                    Alerts.systemErrorAlert(error: errorString!, inController: self)
                    return
                }
                
                
                self.toggleUIForActivePreplannedCarpool(active: true)
                
            })
            
            return
        }
        
        
        let navigationService = MapboxNavigationService(route: route, simulating: simMode)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        self.turnByturnNavigationController = NavigationViewController(for: route, options: navigationOptions)
        self.turnByturnNavigationController!.modalPresentationStyle = .fullScreen
        self.turnByturnNavigationController!.delegate = self
        
        CarpoolAcceptManager.shared.configure(activeRoute: route, mapView: mapView, presentingViewController: self.turnByturnNavigationController!)
        CarpoolAcceptManager.shared.startObservingCarpoolRequestsForMyDriverID()
        DriverDataManager.shared.setRoute(route: route, driverID: AuthManager.shared.currentUserID()!)
        
        self.show(self.turnByturnNavigationController!, sender: self)
        
    }
    
    @IBAction func didTapCancelPreplannedCarpool(_ sender: Any) {
        
        preplannedCarpoolDate = nil
        hud.show(in: self.view)
        DriverDataManager.shared.removePreplannedCarpool(completion: { (result, errorString) in
            self.hud.dismiss()
            if errorString != nil {
                Alerts.systemErrorAlert(error: errorString!, inController: self)
                return
            }
            
            
            self.toggleUIForActivePreplannedCarpool(active: false)
            
        })
        
    }
    
    func toggleUIForActivePreplannedCarpool(active: Bool) {
    
        if active {
            
            startCarPoolButton.backgroundColor = .orange
            startCarPoolButton.setTitle("Start now", for: .normal)
            cancelPreplannedCarpoolButton.animation = "zoomIn"
            cancelPreplannedCarpoolButton.animate()
            
        } else {
            startCarPoolButton.setTitle("Start carpool", for: .normal)
            startCarPoolButton.backgroundColor = .brandColor
            cancelPreplannedCarpoolButton.animation = "zoomOut"
            cancelPreplannedCarpoolButton.animate()
        }
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
        
        CarpoolAcceptManager.shared.cancelCarpoolRequest()
        
        DriverDataManager.shared.removeRoute(driverID: AuthManager.shared.currentUserID()!)
    
         NotificationCenter.default.post(name: NotificationsManager.onFeedbackScreenRequestedNotification, object: nil)
         
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        print(#function)
        //let simulatedDriverLocation = CLLocationCoordinate2D(latitude: 52.4778, longitude: 13.4393)
        
        DriverDataManager.shared.setCurrentLocation(location: location.coordinate, driverID: AuthManager.shared.currentUserID()!)
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        print("navigationViewController willArriveAt")
               print("waypoint: \(waypoint)")
               print("remainingTimeInterval: \(remainingTimeInterval)")
               print("distance: \(distance)")
        
    
        
        //CarpoolAcceptManager.shared.informAboutCloseProximityToRiderPickUpPoint()
        
        // send notification when driver is near pick up
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

