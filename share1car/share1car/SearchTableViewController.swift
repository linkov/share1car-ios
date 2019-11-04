//
//  SearchTableViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder

class SearchTableViewController: UITableViewController, MGLMapViewDelegate {

    var currentUserLocation: MGLUserLocation?
    var completion: coordinate_didCancel_block?
    var matchingItems: [Placemark] = []
    
    let geocoder = Geocoder.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source / delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.qualifiedName
        //TODO: put only postal address instead of full name again
//        cell.detailTextLabel?.text = selectedItem.qualifiedName
        return cell
    }
    
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let selectedItem = matchingItems[indexPath.row]
            
            self.completion!(selectedItem.location?.coordinate, false)
            
        }

}



extension SearchTableViewController : UISearchResultsUpdating {
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchBarText = searchController.searchBar.text
        
        if (searchBarText == nil) {
            return
        }
        
        print(searchBarText!)
        
        let options = ForwardGeocodeOptions(query: searchBarText!)
        
        // To refine the search, you can set various properties on the options object.
        options.allowedISOCountryCodes = ["DE"]     //only German addresses allowed
//        options.focalLocation = CLLocation(latitude: self.currentUserLocation!.coordinate.latitude, longitude: self.currentUserLocation!.coordinate.longitude)
        options.allowedScopes = [.address, .pointOfInterest]
        options.autocompletesQuery = true
        
        
        geocoder.geocode(options) { (placemarks, attribution, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            guard let placemarks = placemarks else {
                return
            }
            
            self.matchingItems = placemarks
            self.tableView.reloadData()

            
            
            print(placemark.name)
//            // 200 Queen St
            print(placemark.qualifiedName!)
//            // 200 Queen St, Saint John, New Brunswick E2L 2X1, Canada
        
//            let coordinate = placemark.location!.coordinate
//            print("\(coordinate.latitude), \(coordinate.longitude)")
//            // 45.270093, -66.050985
//
//            #if !os(tvOS)
//            let formatter = CNPostalAddressFormatter()
//            print(formatter.string(from: placemark.postalAddress!))
//            // 200 Queen St
//            // Saint John New Brunswick E2L 2X1
//            // Canada
//            #endif
        }

        
    }
    
}
