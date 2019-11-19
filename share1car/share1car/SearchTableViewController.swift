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

    }

    // MARK: - Table view data source / delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.qualifiedName

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
        
        options.allowedISOCountryCodes = ["DE"]     //only German addresses allowed
//        options.focalLocation = CLLocation(latitude: self.currentUserLocation!.coordinate.latitude, longitude: self.currentUserLocation!.coordinate.longitude)
        options.allowedScopes = [.address, .pointOfInterest]
        options.autocompletesQuery = true
        
        
        geocoder.geocode(options) { (placemarks, attribution, error) in

            guard let placemarks = placemarks else {
                return
            }
            
            self.matchingItems = placemarks
            self.tableView.reloadData()

        }

        
    }
    
}
