//
//  CarpoolAcceptManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/13/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit

import BLTNBoard

import CoreLocation
import Mapbox

import Polyline

import MapboxGeocoder
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

import Loaf

class CarpoolAcceptManager: NSObject {

    
    var isObservingDriverRequests = false
    var isPresentingCarpoolRequest = false
    
    var mapView: NavigationMapView?
    var presentingViewController: UIViewController?
    
    var bulletinManager: BLTNItemManager?

    
    var carpoolRequestAlert: CarpoolAlertBTLNItem?
    var currentCarpoolRequestRiderID: String?
    var currentCarpoolRequest = S1CCarpoolRequest()
    
    var activeRoute: Route?
    
    static let shared = CarpoolAcceptManager()

     override init(){
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolRequestNotificationReceivedNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolAcceptNotificationReceivedNotification, object: nil)
        
        
    }
    
    func configure(activeRoute: Route, mapView: NavigationMapView, presentingViewController: UIViewController) {
        self.activeRoute = activeRoute
        self.presentingViewController = presentingViewController
        self.mapView = mapView

    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        
        if isObservingDriverRequests == false {
            self.startObservingCarpoolRequestsForMyDriverID()
        }
        
    }
    
    
    func processStatus(request: S1CCarpoolRequest) {
        
        
        if request.status == .requested && currentCarpoolRequest.status != .requested {
            currentCarpoolRequest = request
            processNewCarpoolRequest()
        }
        
        if request.status == .accepted && currentCarpoolRequest.status != .accepted {
            currentCarpoolRequest = request
        }
    
        if request.status == .riderCancelled && currentCarpoolRequest.status != .riderCancelled {
            currentCarpoolRequest = request
            
            showRequestUpdate(title: "Rider cancelled request", subtitle: nil)
        }
        
        
        if request.status == .confirmed && currentCarpoolRequest.status != .confirmed {
            currentCarpoolRequest = request
            showRequestUpdate(title: "Rider confirmed request", subtitle: nil)
        }
        
        
        if request.status == .cancelled && currentCarpoolRequest.status != .cancelled {
            showRequestUpdate(title: "Ride was cancelled", subtitle: nil)
        }


    }
    
    
    func processNewCarpoolRequest() {
     
        DataManager.shared.getUserDetails(userID: self.currentCarpoolRequestRiderID!) { (details, error) in
            if error != nil {
                return
            }


            self.currentCarpoolRequest.riderDetails = details


            self.fetchMyTravelToPickupLocation(pickUp: self.currentCarpoolRequest.pickUpLocation!) { (time, errorString) in
                if error != nil {
                    Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                     return
                 }
                
                

                self.currentCarpoolRequest.driverTimeToPickUpLocation = time

                self.fetchDistanceFromPickUpToDropoff(pickup: self.currentCarpoolRequest.pickUpLocation!, dropoff: self.currentCarpoolRequest.dropOffLocation!) { (distance, errorString) in

                    if error != nil {
                        Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                         return
                     }

                    self.currentCarpoolRequest.carpoolDistance = distance
                    self.showCarpoolRequest()


                }

            }

        }
        
    }
    
    
    func startObservingCarpoolRequestsForMyDriverID() {
        isObservingDriverRequests = true
        
        DriverDataManager.shared.observeCarpoolRequestForMyDriverID { (poolRequest, riderID, error) in
            
            if error != nil {
                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            
            
            if poolRequest == nil  {
                return
            }
            
            self.currentCarpoolRequestRiderID = riderID
            self.processStatus(request: poolRequest!)
            
        }
    }
    
    
    
    func fetchDistanceFromPickUpToDropoff(pickup: CLLocationCoordinate2D, dropoff:CLLocationCoordinate2D, completion: @escaping distance_errorstring_block ) {
        
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
            
            completion(route.distance, nil)
             
         }
            

            

    }
    
    
    func fetchMyTravelToPickupLocation(pickUp: CLLocationCoordinate2D, completion: @escaping  time_errorstring_block) {
        let driverLocation = mapView?.userLocation?.coordinate
        
        if driverLocation == nil {
             Alerts.systemErrorAlert(error: "Current driver location is nil", inController: self.presentingViewController!)
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
                                        
                    completion(route.expectedTravelTime/60, nil)

        }
        
    }
    
    func showRequestUpdate(title: String, subtitle: String?) {
        
            let waitingConfirmationPage =  BulletinDataSource.makeCarpoolWaitingForConfirmationPage(title: title)
            waitingConfirmationPage.isDismissable = true
            if subtitle != nil {
                waitingConfirmationPage.descriptionText = subtitle
            }
        
            
            waitingConfirmationPage.alternativeHandler = { (item: BLTNActionItem) in
                 self.cancelCarpoolRequest()
                 self.bulletinManager!.dismissBulletin()
            }
            
            waitingConfirmationPage.dismissalHandler = { (item: BLTNItem) in
    //            self.showFloatingCarpoolCancelButton()
            }
            
            
            self.bulletinManager?.push(item: waitingConfirmationPage)
            
            
        }
    
    func showCarpoolRequest() {
            

            let timeOfRendevous = Date().addingTimeInterval(self.currentCarpoolRequest.driverTimeToPickUpLocation!*60)
            let formatedTime = Converters.getFormattedDate(date: timeOfRendevous, format: "HH:mm")
            
            let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolRequest.carpoolDistance!)
            carpoolRequestAlert = BulletinDataSource.makeCarpoolRequestPage(
                
                
                title: "Pick up \(self.currentCarpoolRequest.riderDetails!.name!)",
                photoURL: self.currentCarpoolRequest.riderDetails!.photoURL!, mainTitle: "Pickup at ca. \(formatedTime)", subtitle: "Meet \(self.currentCarpoolRequest.riderDetails!.name!) in: \( Int(self.currentCarpoolRequest.driverTimeToPickUpLocation ?? 0) ) minutes ", priceText: "price: $\(priceStringForDistance)")
            
            
            carpoolRequestAlert!.actionHandler = { (item: BLTNActionItem) in
                self.acceptCarpoolRequest()
                
                self.showRequestUpdate(title: "Pick up \(self.currentCarpoolRequest.riderDetails!.name!) in \( Int(self.currentCarpoolRequest.driverTimeToPickUpLocation ?? 0) ) minutes", subtitle: nil)
            }
        
        carpoolRequestAlert!.actionButtonTitle = "Accept request"
            
    //        carpoolRequest.descriptionText = "Driver arrives to your pick up point in \( Int(self.currentCarpoolSearchResult.driverTimeToPickUpLocation ?? 0)  ) minutes. You can be at pick up point in \( Int(self.currentCarpoolSearchResult.riderTimeToPickUpLocation ?? 0) ) minutes"
    //
    //
            carpoolRequestAlert!.alternativeHandler = { (item: BLTNActionItem) in
                self.cancelCarpoolRequest()
                self.carpoolRequestAlert!.manager?.dismissBulletin()
                
            }
            
            carpoolRequestAlert!.dismissalHandler =  { (item) in
                self.isPresentingCarpoolRequest = false
//                 self.cancelCarpoolRequest()
//                carpoolRequest.manager?.dismissBulletin()
                       
            }
            
            bulletinManager = BLTNItemManager(rootItem: carpoolRequestAlert!)
            bulletinManager!.backgroundViewStyle = .dimmed
            
            bulletinManager!.statusBarAppearance = .hidden
            bulletinManager!.showBulletin(above: self.presentingViewController!)
            
            
            

            

            
        }
    
    
    func informAboutCloseProximityToRiderPickUpPoint() {
        
    }
    
    
    func acceptCarpoolRequest() {

        
        let riderPickupLocation: Waypoint = Waypoint(coordinate: currentCarpoolRequest.pickUpLocation!, coordinateAccuracy: -1, name: "Pick up")
        let riderDropOff: Waypoint = Waypoint(coordinate: currentCarpoolRequest.dropOffLocation!, coordinateAccuracy: -1, name: "Drop off")
        let originaDriverDestimation: Waypoint = Waypoint(coordinate: (activeRoute?.coordinates?.last)!, coordinateAccuracy: -1, name: "Final destination")
        
          let options = NavigationRouteOptions(waypoints: [riderPickupLocation, riderDropOff, originaDriverDestimation ], profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in

                guard let route = routes?.first, error == nil else {
                    return
                }

                guard route.coordinateCount > 0 else {

                 return
                 
                }
            
                
            
            let navVC: NavigationViewController = self.presentingViewController! as! NavigationViewController
            navVC.route = route
            

            DriverDataManager.shared.setRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .accepted)
            DriverDataManager.shared.setRequestAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .accepted)
            
            DriverDataManager.shared.setRoute(route: route, driverID: AuthManager.shared.currentUserID()!)
            

        }
        
    }
    

    
    func cancelCarpoolRequest() {
        
        DriverDataManager.shared.removeRoute(driverID:  AuthManager.shared.currentUserID()!)
        
        if self.currentCarpoolRequestRiderID != nil {
            
            DriverDataManager.shared.setRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .rejected)
        }

    }
    
    
}
