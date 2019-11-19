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

class CarpoolAcceptManager: NSObject {

    var mapView: NavigationMapView?
    var presentingViewController: UIViewController?
    
    var bulletinManager: BLTNItemManager?

    
    var carpoolRequest: CarpoolAlertBTLNItem?
    var currentCarpoolRequestRiderID: String?
    var currentCarpoolAcceptResult = S1CCarpoolSearchResult()
    var activeCarpoolStatus: CarpoolRequestStatus?
    
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
        
        let info = Converters.userInfoFromRemoteNotification(userInfo: notification.userInfo!)
        let title = info.title
        print("onCarpoolRequestNotificationReceivedNotification NOTIFICATION TITLE: \(title)")
       
        self.fetchInfoForNewCarpoolRequest()
    }
    
    func fetchInfoForNewCarpoolRequest() {
        activeCarpoolStatus = .requested
        
        DriverDataManager.shared.fetchCarpoolRequestForMyDriverID { (result, error) in
            if error != nil {
                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                return
            }
            let status = result!["status"] as! String
            let riderID = result!["RiderID"] as! String
            let dropOff = result!["RiderDropoffLocation"]! as! [Double]
            let pickUp = result!["RiderPickupLocation"]! as! [Double]
            
            if status == "riderCancelled" {
                
                if self.carpoolRequest != nil {
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
                return
            }
            
            self.currentCarpoolRequestRiderID = riderID
            
            DataManager.shared.getUserDetails(userID: riderID) { (details, error) in
                if error != nil {
                    return
                }
                
                
                self.currentCarpoolAcceptResult.driverDetails = details
                self.currentCarpoolAcceptResult.dropOffLocation = CLLocationCoordinate2D(latitude: dropOff[0], longitude: dropOff[1])
                self.currentCarpoolAcceptResult.pickUpLocation = CLLocationCoordinate2D(latitude: pickUp[0], longitude: pickUp[1])
                
                self.fetchMyTravelToPickupLocation(pickUp: CLLocationCoordinate2D(latitude: pickUp[0], longitude: pickUp[1])) { (time, errorString) in
                    if error != nil {
                        Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                         return
                     }
                    
                    self.currentCarpoolAcceptResult.driverTimeToPickUpLocation = time
                    
                    self.fetchDistanceFromPickUpToDropoff(pickup: CLLocationCoordinate2D(latitude: pickUp[0], longitude: pickUp[1]), dropoff: CLLocationCoordinate2D(latitude: dropOff[0], longitude: dropOff[1])) { (distance, errorString) in
                        
                        if error != nil {
                            Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
                             return
                         }
                        
                        self.currentCarpoolAcceptResult.carpoolDistance = distance
                        self.showCarpoolRequest()
                        
                        
                    }
                    
                }
                
            }
            
            
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
    
    func showCarpoolRequest() {
            

            let timeOfRendevous = Date().addingTimeInterval(self.currentCarpoolAcceptResult.driverTimeToPickUpLocation!*60)
            let formatedTime = Converters.getFormattedDate(date: timeOfRendevous, format: "HH:mm")
            
            let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolAcceptResult.carpoolDistance!)
            carpoolRequest = BulletinDataSource.makeCarpoolRequestPage(
                
                
                title: "Pick up \(self.currentCarpoolAcceptResult.driverDetails!.name!)",
                photoURL: self.currentCarpoolAcceptResult.driverDetails!.photoURL!, mainTitle: "Pickup at ca. \(formatedTime)", subtitle: "Meet \(self.currentCarpoolAcceptResult.driverDetails!.name!) in: \( Int(self.currentCarpoolAcceptResult.driverTimeToPickUpLocation ?? 0) ) minutes ", priceText: "price: $\(priceStringForDistance)")
            
            
            carpoolRequest!.actionHandler = { (item: BLTNActionItem) in
                
                self.acceptCarpoolRequest()
                self.carpoolRequest!.manager?.dismissBulletin()
            }
        
        carpoolRequest!.actionButtonTitle = "Accept request"
            
    //        carpoolRequest.descriptionText = "Driver arrives to your pick up point in \( Int(self.currentCarpoolSearchResult.driverTimeToPickUpLocation ?? 0)  ) minutes. You can be at pick up point in \( Int(self.currentCarpoolSearchResult.riderTimeToPickUpLocation ?? 0) ) minutes"
    //
    //
            carpoolRequest!.alternativeHandler = { (item: BLTNActionItem) in
                self.cancelCarpoolRequest()
                self.carpoolRequest!.manager?.dismissBulletin()
                
                
            }
            
            carpoolRequest!.dismissalHandler =  { (item) in
//                 self.cancelCarpoolRequest()
//                carpoolRequest.manager?.dismissBulletin()
                       
            }
            
            bulletinManager = BLTNItemManager(rootItem: carpoolRequest!)
            bulletinManager!.backgroundViewStyle = .dimmed
            
            bulletinManager!.statusBarAppearance = .hidden
            bulletinManager!.showBulletin(above: self.presentingViewController!)
            
            
            

            

            
        }
    
    
    func informAboutCloseProximityToRiderPickUpPoint() {
        
    }
    
    
    func acceptCarpoolRequest() {
        
        activeCarpoolStatus = .accepted
        
        let riderPickupLocation: Waypoint = Waypoint(coordinate: currentCarpoolAcceptResult.pickUpLocation!, coordinateAccuracy: -1, name: "Pick up")
        let riderDropOff: Waypoint = Waypoint(coordinate: currentCarpoolAcceptResult.dropOffLocation!, coordinateAccuracy: -1, name: "Drop off")
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
            

            DriverDataManager.shared.sendRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .accepted)
            

        }
        
    }
    
    func handleRideCancellation() {
        
        if activeCarpoolStatus == .accepted {
            DriverDataManager.shared.sendRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .rejected)
        }
        
    }
    
    func cancelCarpoolRequest() {
        DriverDataManager.shared.sendRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .rejected)
    }
    
    
}
