//
//  LocationManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/14/24.
//
 
import CoreLocation
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipcode: String = ""
    @Published var country: String = ""
    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?

//    private var locationCompletion: ((Result<(CLLocation, String, String, String, String), Error>) -> Void)?
    @Published var isLocationDenied: Bool = false
    
    @Published var authroizationStatus: CLAuthorizationStatus = .notDetermined
    // In LocationManager
    var isLocationAuthorized: Bool {
        return authroizationStatus == .authorizedWhenInUse || authroizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    //    // Request location authorization
        func requestLocationAuthorization() {
            locationManager.requestWhenInUseAuthorization()
        }
    
    // Asynchronous method to get the address for a location
    private func fetchAddress(for location: CLLocation) async throws -> (String, String, String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let state = placemark.administrativeArea ?? ""
                    let zipcode = placemark.postalCode ?? ""
                    let country = placemark.country ?? ""
                    continuation.resume(returning: (city, state, zipcode, country))
                } else {
                    continuation.resume(throwing: NSError(domain: "No placemark found", code: 6, userInfo: nil))
                }
            }
        }
    }
    
    // Request current location asynchronously
    func getCurrentLocation() async throws -> (CLLocation, String, String, String, String) {
        guard CLLocationManager.locationServicesEnabled() else {
            throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
        }
        
        let authorizationStatus = locationManager.authorizationStatus
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
        }
        
        let location = try await getLocationUpdate()
        let (city, state, zipcode, country) = try await fetchAddress(for: location)
        
        return (location, city, state, zipcode, country)
    }


      // Helper method to get location update asynchronously
    private func getLocationUpdate() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.requestLocation()
            
            var locationRequestCompleted = false

            locationCompletion = { result in
                guard !locationRequestCompleted else { return }
                
                switch result {
                case .success(let location):
                    locationRequestCompleted = true
                    continuation.resume(returning: location)
                case .failure(let error):
                    locationRequestCompleted = true
                    continuation.resume(throwing: error)
                }
            }
            
            Task {
                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                guard !locationRequestCompleted else { return }
                locationRequestCompleted = true
                continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
            }
        }
    }
    
    // CLLocationManagerDelegate method: handles location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
            return
        }
        
        locationCompletion?(.success(location)) // Return only CLLocation
    }
    
    // CLLocationManagerDelegate method: handles authorization changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.isLocationDenied = (status == .denied || status == .restricted)
        }
    }

    // CLLocationManagerDelegate method: handles location errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(.failure(error))
    }
    
    // Calculate distance between two locations in kilometers
    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000 // Convert meters to kilometers
    }
}


//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else {
//            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
//            return
//        }
//
//        Task {
//            do {
//                let (city, state, zipcode, country) = try await fetchAddress(for: location)
//                locationCompletion?(.success((location, city, state, zipcode, country)))
//            } catch {
//                locationCompletion?(.failure(error))
//            }
//        }
//    }
//    private func getLocationUpdate() async throws -> CLLocation {
//        return try await withCheckedThrowingContinuation { continuation in
//            // Request location
//            locationManager.requestLocation()
//
//            // Flag to track if the continuation has been resumed
//            var hasResumed = false
//
//            // Set the completion handler
//            locationCompletion = { [weak self] result in
//                guard !hasResumed else { return } // Ensure continuation is only resumed once
//                hasResumed = true // Mark continuation as resumed
//                self?.locationCompletion = nil // Clear completion handler
//
//                switch result {
//                case .success(let (location, _, _, _, _)):
//                    continuation.resume(returning: location)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//
//            // Add a timeout to ensure completion within a reasonable time
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
//                guard !hasResumed else { return } // Prevent multiple resumptions
//                hasResumed = true // Mark as resumed due to timeout
//                self?.locationCompletion = nil // Clear completion handler
//                continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
//            }
//        }
//    }

//    private func getLocationUpdate() async throws -> CLLocation {
//        return try await withCheckedThrowingContinuation { continuation in
//            // Request location
//            locationManager.requestLocation()
//
//            // Set the completion handler
//            locationCompletion = { [weak self] result in
//                // Clear the completion handler after use to avoid retain cycles
//                self?.locationCompletion = nil
//
//                switch result {
//                case .success(let (location, _, _, _, _)):
//                    continuation.resume(returning: location)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//
//            // Add a timeout to prevent continuation from leaking
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
//                if let locationCompletion = self?.locationCompletion {
//                    // If completion is still set, assume a timeout
//                    self?.locationCompletion = nil
//                    continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
//                }
//            }
//        }
//    }

//      private func getLocationUpdate() async throws -> CLLocation {
//          return try await withCheckedThrowingContinuation { continuation in
//              // Request location
//              locationManager.requestLocation()
//
//              // Flag to track if continuation has been resumed
//              var hasResumed = false
//
//              // Set the completion handler
//              locationCompletion = { result in
//                  guard !hasResumed else { return } // Check if already resumed
//
//                  switch result {
//                  case .success(let (location, _, _, _, _)):
//                      hasResumed = true // Mark as resumed
//                      continuation.resume(returning: location)
//                  case .failure(let error):
//                      hasResumed = true // Mark as resumed
//                      continuation.resume(throwing: error)
//                  }
//              }
//          }
//      }
