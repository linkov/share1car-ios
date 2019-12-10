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

import EasyPeasy

class CarpoolAcceptManager: NSObject {

    // MARK: General
    
    private var bulletinManager: BLTNItemManager?
    private var carpoolRequestAlert: CarpoolAlertBTLNItem?
    private var currentBadgeView: RequestUpdateBadgeView?
    
    // MARK: Model
    
    private var originalRoute: Route?
    private var currentCarpoolRequestRiderID: String?
    private var currentCarpoolRequest = S1CCarpoolRequest()
    
    // MARK: State
    
    private var isPresentingCarpoolCompleteAlert = false
    private var isObservingDriverRequests = false
    private var isPresentingCarpoolRequest = false
    
    // MARK: Inputs
    var routeCurrentLegtimeRemaining: Double?
    var mapView: NavigationMapView?
    var presentingViewController: UIViewController?
    
    
    static let shared = CarpoolAcceptManager()

     override init(){
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolRequestNotificationReceivedNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NotificationsManager.onCarpoolAcceptNotificationReceivedNotification, object: nil)
        
        
    }
    
    public func configureAndStartSubscriptions(activeRoute: Route, mapView: NavigationMapView, presentingViewController: UIViewController) {
        self.originalRoute = activeRoute
        self.presentingViewController = presentingViewController
        self.mapView = mapView
        self.startObservingCarpoolRequestsForMyDriverID()
        DriverDataManager.shared.setRoute(route: activeRoute, driverID: AuthManager.shared.currentUserID()!)
    }
    
    
    // MARK: - Start / Stop carpool requests
    
    private func resetToOriginalRoute() {
        
        if originalRoute != nil {
            
            let navVC: NavigationViewController = self.presentingViewController! as! NavigationViewController
            navVC.route = originalRoute!
          
            DriverDataManager.shared.setRoute(route: originalRoute!, driverID: AuthManager.shared.currentUserID()!)

        }
    }
    
    @objc public  func rejectCarpoolRequest() {
        
        if self.currentCarpoolRequestRiderID != nil {
            
            DriverDataManager.shared.setRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .rejected)
            
            DriverDataManager.shared.setRouteRequest(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .deleted)
            
            DriverDataManager.shared.deleteRouteRequest(fromDriverID: AuthManager.shared.currentUserID()!)
            
        }
        
        resetToOriginalRoute()
    }
    
    public func cancelCarpoolAvailability() {
        
        DriverDataManager.shared.removeRoute(driverID:  AuthManager.shared.currentUserID()!)
        

    }
    
    
    public func cleanUp() {
        isPresentingCarpoolCompleteAlert = false
        originalRoute = nil
        currentCarpoolRequest = S1CCarpoolRequest()
        currentCarpoolRequestRiderID = nil
        currentBadgeView = nil
    }
    
    
    private func acceptCarpoolRequest() {

        let currentLocation: Waypoint = Waypoint(coordinate: self.mapView!.userLocation!.coordinate, coordinateAccuracy: -1, name: "Current location")
        let riderPickupLocation: Waypoint = Waypoint(coordinate: currentCarpoolRequest.pickUpLocation!, coordinateAccuracy: -1, name: "Pick up")
        let riderDropOff: Waypoint = Waypoint(coordinate: currentCarpoolRequest.dropOffLocation!, coordinateAccuracy: -1, name: "Drop off")
        let originaDriverDestimation: Waypoint = Waypoint(coordinate: (originalRoute?.coordinates?.last)!, coordinateAccuracy: -1, name: "Final destination")
        
          let options = NavigationRouteOptions(waypoints: [currentLocation, riderPickupLocation, riderDropOff, originaDriverDestimation ], profileIdentifier: .automobile)
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
            DriverDataManager.shared.setRouteRequest(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequestRiderID!, status: .accepted)
            
            DriverDataManager.shared.setRoute(route: route, driverID: AuthManager.shared.currentUserID()!)
            

        }
        
    }
    
    public func didUpdateTimeRemaining(timeRemaining: Double) {
        
        if currentCarpoolRequest.status == .accepted && currentBadgeView != nil  && self.currentCarpoolRequest.riderDetails != nil {
            currentBadgeView?.titleLabel.text = "Pick up \(self.currentCarpoolRequest.riderDetails!.name!) in \( Int(timeRemaining/60 ) ) minutes"
            if Int(timeRemaining/60) < 2 && Int(timeRemaining/60) > 1  {
                currentBadgeView?.titleLabel.text = "Picking up \(self.currentCarpoolRequest.riderDetails!.name!) in a minute"
                currentBadgeView!.actionButton.backgroundColor = .white
                currentBadgeView!.actionButton.setTitleColor(.black, for: .normal)
                currentBadgeView!.actionButton.setTitle("OK")
                currentBadgeView!.actionButton.removeTarget(self, action: nil, for: .touchUpInside)
                currentBadgeView!.actionButton.addTarget(self, action: #selector(dismissNonblockingBadgeView), for: .touchUpInside)
            } else if Int(timeRemaining/60) == 1 {
                
                dismissNonblockingBadgeView()
                showPickUpProximityAlert()
            
            }
        }
    }
    
    
    public func showDropOffProximityAlert() {
//     showRequestUpdateBadgeView(title: "Carpool is completed", actionTitle: nil, action: nil)
    }
    
    public func showPickUpProximityAlert() {
        
        if isPresentingCarpoolCompleteAlert && currentCarpoolRequest.status != .confirmed {
            return
        }
         isPresentingCarpoolCompleteAlert = true
    
           dismissNonblockingBadgeView()
                          
           let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolRequest.carpoolDistance!)
           
           let carpoolConfirm = BulletinDataSource.makeCarpoolRequestPage(
               
               
               title: "Confirm carpool",
               photoURL: self.currentCarpoolRequest.riderDetails!.photoURL!, mainTitle: "Pick up passengers and confirm the ride", subtitle: nil, priceText: "price: $\(priceStringForDistance)")
           
           

           carpoolConfirm.actionButtonTitle = "Confirm & finish"
           carpoolConfirm.actionHandler = { (item: BLTNActionItem) in
            
               item.manager?.dismissBulletin()
            
            DriverDataManager.shared.setRideAccept(fromDriverID: AuthManager.shared.currentUserID()!, toRiderID: self.currentCarpoolRequest.riderDetails!.UID!, status: .confirmed)

                
           }
           

           carpoolConfirm.alternativeHandler = { (item: BLTNActionItem) in
             
               self.cancelCarpoolAvailability()
               item.manager?.dismissBulletin()
               
           }
           
           if (!bulletinManager!.isShowingBulletin) {
               
               bulletinManager = BLTNItemManager(rootItem: carpoolConfirm)
               bulletinManager!.backgroundViewStyle = .dimmed
               
               bulletinManager!.showBulletin(above: self.presentingViewController!)
               
           } else {
               self.bulletinManager?.push(item: carpoolConfirm)

           }
           
           
           
       }

    
    // MARK: - Subscriptions
  
    private func startObservingCarpoolRequestsForMyDriverID() {
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
    
    
    
    @objc private func onDidReceiveData(_ notification:Notification) {
        
        if isObservingDriverRequests == false {
            self.startObservingCarpoolRequestsForMyDriverID()
        }
        
    }
    
    
    private func processStatus(request: S1CCarpoolRequest) {
        
        
        if request.status == .requested && currentCarpoolRequest.status != .requested {
            currentCarpoolRequest = request
            processNewCarpoolRequest()
        }
        
        if request.status == .accepted && currentCarpoolRequest.status != .accepted {
            currentCarpoolRequest.status = request.status
        }
    
        if request.status == .riderCancelled && currentCarpoolRequest.status != .riderCancelled {
            currentCarpoolRequest = request
             resetToOriginalRoute()
            showRequestUpdateBadgeView(title: "Rider cancelled request", actionTitle: nil, action: nil)
        }
        
        
        if request.status == .confirmed && currentCarpoolRequest.status != .confirmed {
            currentCarpoolRequest.status = request.status
        }
        
        
        if request.status == .cancelled && currentCarpoolRequest.status != .cancelled {
             showRequestUpdateBadgeView(title: "Ride was cancelled", actionTitle: nil, action: nil)
        }


    }
    
    
     // MARK: - Fetch carpool details
    
    private func processNewCarpoolRequest() {
     
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

    
    
    private func fetchDistanceFromPickUpToDropoff(pickup: CLLocationCoordinate2D, dropoff:CLLocationCoordinate2D, completion: @escaping distance_errorstring_block ) {
        
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
    
    
    private func fetchMyTravelToPickupLocation(pickUp: CLLocationCoordinate2D, completion: @escaping  time_errorstring_block) {
        let driverLocation = mapView?.userLocation?.coordinate
        
        if driverLocation == nil {
             Alerts.systemErrorAlert(error: "Current driver location is nil", inController: self.presentingViewController!)
        }
        
        
        let driverWaypoint = Waypoint(location: CLLocation(latitude: driverLocation!.latitude, longitude: driverLocation!.longitude))
        let pickUpWaypoint = Waypoint(coordinate: pickUp)
                   
        let options = NavigationRouteOptions(waypoints: [driverWaypoint, pickUpWaypoint], profileIdentifier: .automobileAvoidingTraffic)
                  
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
    
    // MARK: - Present carpool status UI
    
    @objc private func dismissNonblockingBadgeView() {
        
        if currentBadgeView != nil && ((currentBadgeView?.superview) != nil) {
            currentBadgeView!.removeFromSuperview()
        }
    }
    
    
    private func showRequestUpdateBadgeView(title: String, actionTitle: String?, action: Selector?) {
        
        dismissNonblockingBadgeView()
        
        if bulletinManager != nil && bulletinManager!.isShowingBulletin == true {
            bulletinManager!.dismissBulletin()
        }
        
        let window = UIApplication.shared.keyWindow!
        
        currentBadgeView = RequestUpdateBadgeView.instanceFromNib()
        currentBadgeView!.titleLabel.text = title
        
        
        if actionTitle != nil {
            currentBadgeView!.actionButton.setTitle(actionTitle)
            currentBadgeView!.actionButton.removeTarget(self, action: nil, for: .touchUpInside)
            currentBadgeView!.actionButton.addTarget(self, action: action!, for: .touchUpInside)
                   } else {
            currentBadgeView!.actionButton.backgroundColor = .white
            currentBadgeView!.actionButton.setTitleColor(.black, for: .normal)
            currentBadgeView!.actionButton.setTitle("OK")
            currentBadgeView!.actionButton.removeTarget(self, action: nil, for: .touchUpInside)
            currentBadgeView!.actionButton.addTarget(self, action: #selector(dismissNonblockingBadgeView), for: .touchUpInside)
                       
                   }
        

       
        window.addSubview(currentBadgeView!)
        
//        view.easy.layout(Edges(UIEdgeInsets(top: 0, left: 10, bottom: 5, right: 10)))
        currentBadgeView!.easy.layout(
            Height(100),
            Bottom(10).to(window),
          Left(10).to(window),
          Right(10).to(window)
        )
        
        currentBadgeView!.animate()
        
        
    }
    
    private func showRequestUpdate(title: String, subtitle: String?) {
        

        dismissNonblockingBadgeView()
        
        if  !(bulletinManager?.isShowingBulletin ?? false) {
            return
        }
        
            let waitingConfirmationPage =  BulletinDataSource.makeCarpoolWaitingForConfirmationPage(title: title)
            waitingConfirmationPage.isDismissable = true
            if subtitle != nil {
                waitingConfirmationPage.descriptionText = subtitle
            }
        
            
            waitingConfirmationPage.alternativeHandler = { (item: BLTNActionItem) in
                 self.rejectCarpoolRequest()
                 self.bulletinManager!.dismissBulletin()
            }
            
            waitingConfirmationPage.dismissalHandler = { (item: BLTNItem) in
            }
            
            
            self.bulletinManager?.push(item: waitingConfirmationPage)
            
            
        }
    
    private func showCarpoolRequest() {
            


            let timeOfRendevous = Date().addingTimeInterval(self.currentCarpoolRequest.driverTimeToPickUpLocation!*60)
            let formatedTime = Converters.getFormattedDate(date: timeOfRendevous, format: "HH:mm")
        

            let priceStringForDistance = PriceCalculation.driverFeeStringForDistance(travelDistance: self.currentCarpoolRequest.carpoolDistance!)
            carpoolRequestAlert = BulletinDataSource.makeCarpoolRequestPage(


                title: "Pick up \(self.currentCarpoolRequest.riderDetails!.name!)",
                photoURL: self.currentCarpoolRequest.riderDetails!.photoURL!, mainTitle: "Pickup at ca. \(formatedTime)", subtitle: "Meet \(self.currentCarpoolRequest.riderDetails!.name!) in: \( Int(self.currentCarpoolRequest.driverTimeToPickUpLocation ?? 0) ) minutes ", priceText: "price: $\(priceStringForDistance)")


            carpoolRequestAlert!.actionHandler = { (item: BLTNActionItem) in
                self.acceptCarpoolRequest()
                
                self.showRequestUpdateBadgeView(title: "Pick up \(self.currentCarpoolRequest.riderDetails!.name!) in \( Int(self.routeCurrentLegtimeRemaining!/60 ) ) minutes", actionTitle: "cancel", action:  #selector(self.rejectCarpoolRequest))

//                self.showRequestUpdate(title: "Pick up \(self.currentCarpoolRequest.riderDetails!.name!) in \( Int(self.currentCarpoolRequest.driverTimeToPickUpLocation ?? 0) ) minutes", subtitle: nil)
            }

        carpoolRequestAlert!.actionButtonTitle = "Accept request"

            carpoolRequestAlert!.alternativeHandler = { (item: BLTNActionItem) in
                self.rejectCarpoolRequest()
                self.carpoolRequestAlert!.manager?.dismissBulletin()

            }

            carpoolRequestAlert!.dismissalHandler =  { (item) in
                self.isPresentingCarpoolRequest = false

            }

            bulletinManager = BLTNItemManager(rootItem: carpoolRequestAlert!)
            bulletinManager!.backgroundViewStyle = .dimmed

            bulletinManager!.statusBarAppearance = .hidden
            bulletinManager!.showBulletin(above: self.presentingViewController!)




            

            
        }
    
    
    

    
    
}
