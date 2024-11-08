//
//  FetchAutoCompleteModel.swift
//  Just Swap
//
//  Created by Donovan Holmes on 10/22/24.
//
import GooglePlaces
import SwiftUI

struct GooglePlacesAutocompleteView: UIViewControllerRepresentable {
    @Binding var city: String
    @Binding var state: String
    @Binding var zipcode: String
    @Binding var country: String
    var searchType: SearchType // Property to differentiate between city, state, or country
    
    enum SearchType {
        case city
        case state
        case country
    }
    
    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator
        
        // Set the filter based on search type
        let filter = GMSAutocompleteFilter()
        switch searchType {
        case .city:
            filter.type = .city // Filter for cities
        case .state:
            filter.type = .region // General filter
        case .country:
            filter.type = .region // Filter for countries
        }
        autocompleteController.autocompleteFilter = filter
        
        return autocompleteController
    }
    
    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        var parent: GooglePlacesAutocompleteView
        
        init(_ parent: GooglePlacesAutocompleteView) {
            self.parent = parent
        }
        
        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            var cityName: String?
            var stateName: String?
            var countryName: String?
            var postalCode: String?
            
            // Check the address components
            guard let addressComponents = place.addressComponents else {
                print("Error: No address components found.")
                viewController.dismiss(animated: true, completion: nil)
                return
            }
            
            for component in addressComponents {
                print("Component: \(component.name), Types: \(component.types)") // Log component details
                switch component.types.first {
                case "locality":
                    cityName = component.name
                case "administrative_area_level_1":
                    stateName = component.name
                case "country":
                    countryName = component.name
                case "postal_code":
                    postalCode = component.name
                default:
                    break
                }
            }
            
            // Log the extracted values for debugging
            print("Selected Place:")
            print("City: \(cityName ?? "N/A")")
            print("State: \(stateName ?? "N/A")")
            print("Country: \(countryName ?? "N/A")")
            print("Postal Code: \(postalCode ?? "N/A")")
            
            // Update the parent properties if values were found
            if let city = cityName {
                parent.city = city
            }
            if let state = stateName {
                parent.state = state
            }
            if let country = countryName {
                parent.country = country
            }
            if let zip = postalCode {
                parent.zipcode = zip
            }
            
            // Dismiss the autocomplete view
            viewController.dismiss(animated: true, completion: nil)
        }
        
        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: ", error.localizedDescription)
            viewController.dismiss(animated: true, completion: nil)
        }
        
        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}
