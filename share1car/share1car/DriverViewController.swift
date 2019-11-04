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

import Spring

class DriverViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate {

    @IBOutlet weak var startCarPoolButton: SpringButton!
    @IBOutlet weak var searchBarContainerView: UIView!
    @IBOutlet weak var mapView: MGLMapView!
    let geocoder = Geocoder.shared
    var currentDestination: CLLocationCoordinate2D?
    var resultSearchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startCarPoolButton.layer.cornerRadius = 8
        
        setupDriverMap()
        setupSearch()
        
//        presentNavTest()
        
    }
    
    

    func setupDriverMap() {
    
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setZoomLevel(14, animated: false)
        
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
            
            self.currentDestination = location
            self.resultSearchController?.dismiss(animated: true, completion: nil)
            
            self.drawRoute(origin: (self.mapView.userLocation!.coordinate), destination: location!)
            self.toggleCarpoolButton(active: true)
            
        }
    }
    
    
    func drawRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {

        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        

        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            
            guard let route = routes?.first, error == nil else {
                 Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                return
            }
            
                        
            guard route.coordinateCount > 0 else { return }
            
            
            var routeCoordinates = route.coordinates!
            let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
            
            // If there's already a route line on the map, reset its shape to the new route
            if let source = self.mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
                
                source.shape = polyline
                
            } else {
                
                let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
                
                // Customize the route line color and width
                let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
                lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                
                // Add the source and style layer of the route line to the map
                self.mapView.style?.addSource(source)
                self.mapView.style?.addLayer(lineStyle)
                
                
            }
            
        }
    }

    

    
    func drawRoute(route: Route) {

    }
    
    func toggleCarpoolButton(active: Bool) {
        
        if (active) {
            startCarPoolButton.animate()
        } else {
            
        }
        
    }
    
    func startNavigation() {
        
//        let origin = mapView.userLocation?.coordinate
//        let destination = currentDestination
        
        guard let origin = mapView.userLocation?.coordinate, let destination = currentDestination else {
            Alerts.systemErrorAlert(error: "Origin or destination of the route was not set", inController: self)
            return
        }
        
        let options = NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                return
            }
            
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            let navigationService = MapboxNavigationService(route: route, simulating: .always)
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            let navigationViewController = NavigationViewController(for: route, options: navigationOptions)
            navigationViewController.modalPresentationStyle = .fullScreen
            navigationViewController.delegate = self
            
            self.present(navigationViewController, animated: true, completion: nil)
        }
    
            
    }
    
     // MARK: - Actions
    
    @IBAction func onCarpoolTap(_ sender: Any) {
        
        if (!AuthManager.shared.isLoggedIn) {
            AuthManager.shared.presentAuthUIFrom(controller: self)
            return
        }
        startNavigation()
        
    }
    
    
     // MARK: - NavigationViewControllerDelegate
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        print("navigationViewControllerDidDismiss")
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        print("navigationViewController didUpdate")
        print("progress: \(progress)")
        print("location: \(location)")
        print("rawLocation: \(rawLocation)")
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        print("navigationViewController willArriveAt")
               print("waypoint: \(waypoint)")
               print("remainingTimeInterval: \(remainingTimeInterval)")
               print("distance: \(distance)")
    }
    
    
     // MARK: - MGLMapViewDelegate
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        
        guard let userLocation = mapView.userLocation else {
            return
        }
        
        mapView.setCenter(userLocation.coordinate, zoomLevel: 12, animated: false)
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
    // Always allow callouts to popup when annotations are tapped.
        return true
    }
     
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

    }

}
