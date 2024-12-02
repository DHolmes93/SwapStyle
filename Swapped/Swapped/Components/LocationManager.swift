//
//  LocationManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/14/24.
//
import CoreLocation
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipcode: String = ""
    @Published var country: String = ""
    
    @Published var isLocationDenied: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var userCoordinates: CLLocationCoordinate2D? // User's current coordinates
    
    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
    private var authorizationContinuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationAuthorization() async throws {
        guard CLLocationManager.locationServicesEnabled() else {
            throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            try await waitForAuthorization()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            isLocationDenied = true
            throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
        }
    }
    
    private func waitForAuthorization() async throws {
        try await withCheckedThrowingContinuation { continuation in
            authorizationContinuation = continuation
        }
    }

    func getCurrentLocation() async throws -> (CLLocationCoordinate2D?, String, String, String, String) {
        try await requestLocationAuthorization()
        
        let location = try await getLocationUpdate()
        let (city, state, zipcode, country) = try await fetchAddress(for: location)
        
        userCoordinates = location.coordinate
        return (userCoordinates, city, state, zipcode, country)
    }

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
                if !locationRequestCompleted {
                    locationRequestCompleted = true
                    continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
                }
            }
        }
    }

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

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationContinuation?.resume()
        case .denied, .restricted:
            authorizationContinuation?.resume(throwing: NSError(domain: "Location authorization denied", code: 1, userInfo: nil))
        default:
            break
        }
        authorizationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
            return
        }
        
        locationCompletion?(.success(location))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(.failure(error))
    }
}

//import CoreLocation
//import UIKit
//
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    static let shared = LocationManager()
//    private let locationManager = CLLocationManager()
//    
//    @Published var city: String = ""
//    @Published var state: String = ""
//    @Published var zipcode: String = ""
//    @Published var country: String = ""
//    
//    @Published var isLocationDenied: Bool = false
//    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
//    var userCoordinates: CLLocationCoordinate2D? // User's current coordinates
//    
//    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
//    
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
////        checkLocationPermission()
//    }
//    
//    func requestLocationAuthorization() {
//        let authorizationStatus = CLLocationManager.authorizationStatus()
//        
//        if authorizationStatus == .notDetermined {
//            locationManager.requestWhenInUseAuthorization() // Or requestAlwaysAuthorization()
//        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
//            isLocationDenied = true
//        }
//    }
//    
//    private func fetchAddress(for location: CLLocation) async throws -> (String, String, String, String) {
//        return try await withCheckedThrowingContinuation { continuation in
//            let geocoder = CLGeocoder()
//            geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                } else if let placemark = placemarks?.first {
//                    let city = placemark.locality ?? ""
//                    let state = placemark.administrativeArea ?? ""
//                    let zipcode = placemark.postalCode ?? ""
//                    let country = placemark.country ?? ""
//                    continuation.resume(returning: (city, state, zipcode, country))
//                } else {
//                    continuation.resume(throwing: NSError(domain: "No placemark found", code: 6, userInfo: nil))
//                }
//            }
//        }
//    }
//    func checkAndRequestAuthorization() async throws {
//          guard CLLocationManager.locationServicesEnabled() else {
//              throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
//          }
//
//          let authorizationStatus = locationManager.authorizationStatus
//          if authorizationStatus == .notDetermined {
//              locationManager.requestWhenInUseAuthorization()
//              try await waitForAuthorization()
//          } else if authorizationStatus == .restricted || authorizationStatus == .denied {
//              throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
//          }
//      }
//    
//    func getCurrentLocation() async throws -> (CLLocationCoordinate2D?, String, String, String, String) {
//        guard CLLocationManager.locationServicesEnabled() else {
//            throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
//        }
//
//        let authorizationStatus = locationManager.authorizationStatus
//        switch authorizationStatus {
//        case .notDetermined:
//            locationManager.requestWhenInUseAuthorization()
//            // Await authorization change before proceeding
//            try await waitForAuthorization()
//        case .restricted, .denied:
//            throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
//        case .authorizedWhenInUse, .authorizedAlways:
//            break // Proceed to fetch location
//        @unknown default:
//            throw NSError(domain: "Unknown location authorization status", code: 2, userInfo: nil)
//        }
//
//        let location = try await getLocationUpdate()
//        let (city, state, zipcode, country) = try await fetchAddress(for: location)
//
//        // Save the user coordinates for later use
//        userCoordinates = location.coordinate
//
//        return (userCoordinates, city, state, zipcode, country)
//    }
//
//    private func waitForAuthorization() async throws {
//        try await withCheckedThrowingContinuation { continuation in
//            let handler: (CLAuthorizationStatus) -> Void = { status in
//                if status == .authorizedWhenInUse || status == .authorizedAlways {
//                    continuation.resume()
//                } else if status == .denied || status == .restricted {
//                    continuation.resume(throwing: NSError(domain: "Location authorization denied", code: 1, userInfo: nil))
//                }
//            }
//            
//            locationManager.didChangeAuthorization = handler // Assuming this handler exists in your LocationManager
//        }
//    }
//
//    
//    private func getLocationUpdate() async throws -> CLLocation {
//        return try await withCheckedThrowingContinuation { continuation in
//            locationManager.requestLocation()
//            
//            var locationRequestCompleted = false
//            
//            locationCompletion = { result in
//                guard !locationRequestCompleted else { return }
//                
//                switch result {
//                case .success(let location):
//                    locationRequestCompleted = true
//                    continuation.resume(returning: location)
//                case .failure(let error):
//                    locationRequestCompleted = true
//                    continuation.resume(throwing: error)
//                }
//            }
//            
//            Task {
//                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
//                guard !locationRequestCompleted else { return }
//                locationRequestCompleted = true
//                continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
//            }
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else {
//            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
//            return
//        }
//        
//        locationCompletion?(.success(location)) // Return only CLLocation
//    }
//    
////    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
////        DispatchQueue.main.async {
////            self.isLocationDenied = (status == .denied || status == .restricted)
////            self.authorizationStatus = status
////        }
////    }
//    // Store the continuation to resume later
//    private var authorizationContinuation: CheckedContinuation<Void, Error>?
//
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        switch status {
//        case .authorizedWhenInUse, .authorizedAlways:
//            authorizationContinuation?.resume()
//            authorizationContinuation = nil
//        case .denied, .restricted:
//            authorizationContinuation?.resume(throwing: NSError(domain: "Location authorization denied", code: 1, userInfo: nil))
//            authorizationContinuation = nil
//        default:
//            break
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        locationCompletion?(.failure(error))
//    }
//    
//    func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
//        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
//        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
//        return location1.distance(from: location2) / 1000 // Convert meters to kilometers
//    }
//}

//import CoreLocation
//
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    static let shared = LocationManager()
//    private let locationManager = CLLocationManager()
//    
//    @Published var city: String = ""
//    @Published var state: String = ""
//    @Published var zipcode: String = ""
//    @Published var country: String = ""
//    
//    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
//    
//    @Published var isLocationDenied: Bool = false
//    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
//    
//    var userCoordinates: CLLocationCoordinate2D? // User's current coordinates
//    
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//    }
//    
//    // Request location authorization
//    func requestLocationAuthorization() {
//        locationManager.requestWhenInUseAuthorization()
//    }
//    
//    // Asynchronous method to fetch the address for a location
//    private func fetchAddress(for location: CLLocation) async throws -> (String, String, String, String) {
//        return try await withCheckedThrowingContinuation { continuation in
//            let geocoder = CLGeocoder()
//            geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                } else if let placemark = placemarks?.first {
//                    let city = placemark.locality ?? ""
//                    let state = placemark.administrativeArea ?? ""
//                    let zipcode = placemark.postalCode ?? ""
//                    let country = placemark.country ?? ""
//                    continuation.resume(returning: (city, state, zipcode, country))
//                } else {
//                    continuation.resume(throwing: NSError(domain: "No placemark found", code: 6, userInfo: nil))
//                }
//            }
//        }
//    }
//    
//    // Request current location asynchronously
//    func getCurrentLocation() async throws -> (CLLocationCoordinate2D?, String, String, String, String) {
//        guard CLLocationManager.locationServicesEnabled() else {
//            throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
//        }
//        
//        let authorizationStatus = locationManager.authorizationStatus
//        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
//            throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
//        }
//        
//        let location = try await getLocationUpdate()
//        let (city, state, zipcode, country) = try await fetchAddress(for: location)
//        
//        // Save the user coordinates for later use
//        userCoordinates = location.coordinate
//        
//        return (userCoordinates, city, state, zipcode, country)
//    }
//    
//    // Helper method to get location update asynchronously
//    private func getLocationUpdate() async throws -> CLLocation {
//        return try await withCheckedThrowingContinuation { continuation in
//            locationManager.requestLocation()
//            
//            var locationRequestCompleted = false
//            
//            locationCompletion = { result in
//                guard !locationRequestCompleted else { return }
//                
//                switch result {
//                case .success(let location):
//                    locationRequestCompleted = true
//                    continuation.resume(returning: location)
//                case .failure(let error):
//                    locationRequestCompleted = true
//                    continuation.resume(throwing: error)
//                }
//            }
//            
//            Task {
//                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
//                guard !locationRequestCompleted else { return }
//                locationRequestCompleted = true
//                continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
//            }
//        }
//    }
//    
//    // CLLocationManagerDelegate method: handles location updates
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else {
//            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
//            return
//        }
//        
//        locationCompletion?(.success(location)) // Return only CLLocation
//    }
//    
//    // CLLocationManagerDelegate method: handles authorization changes
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        DispatchQueue.main.async {
//            self.isLocationDenied = (status == .denied || status == .restricted)
//        }
//    }
//    
//    // CLLocationManagerDelegate method: handles location errors
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        locationCompletion?(.failure(error))
//    }
//    
//    // Calculate distance between two locations in kilometers
//    func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
//        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
//        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
//        return location1.distance(from: location2) / 1000 // Convert meters to kilometers
//    }
//}

//    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
//        return from.distance(from: to) / 1000 // Convert meters to kilometers
////    }
//}

//import CoreLocation
//import Foundation
//import CoreMotion
//import UIKit
//import SwiftUICore
//
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    static let shared = LocationManager()
//    private let locationManager = CLLocationManager()
//    @Published var city: String = ""
//    @Published var state: String = ""
//    @Published var zipcode: String = ""
//    @Published var country: String = ""
//    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
//    @State private var userLocation: CLLocationCoordinate2D? = nil
////    private var userCoordinate: CLLocationCoordinate2D?
//    var userCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)  // Example: San Francisco coordinates
//    
//    @Published var isLocationDenied: Bool = false
//    @Published var authroizationStatus: CLAuthorizationStatus = .notDetermined
//    
//    var isLocationAuthorized: Bool {
//        return authroizationStatus == .authorizedWhenInUse || authroizationStatus == .authorizedAlways
//    }
//    
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//    }
//    
//    func requestLocationAuthorization() {
//        locationManager.requestWhenInUseAuthorization()
//    }
//    // Function to set user location
//    func setUserLocation(latitude: Double, longitude: Double) {
//        userCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//    
//    // Method to create coordinates from the current location
//    func createCoordinates() async throws -> CLLocationCoordinate2D {
//        // Fetch current location
//        let (location, _, _, _, _) = try await getCurrentLocation()
//        // Extract CLLocationCoordinate2D from CLLocation
//        return location.coordinate
//    }
//    
//    // Asynchronous method to fetch the current location
//    func getCurrentLocation() async throws -> (CLLocationCoordinate2D?, String, String, String, String) {
//        guard CLLocationManager.locationServicesEnabled() else {
//            throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
//        }
//        
//        let authorizationStatus = locationManager.authorizationStatus
//        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
//            throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
//        }
//        
//        let location = try await getLocationUpdate()
//        let (city, state, zipcode, country) = try await fetchAddress(for: location)
//        
//        return (userCoordinates, location, city, state, zipcode, country)
//    }
//    
//    private func getLocationUpdate() async throws -> CLLocation {
//        return try await withCheckedThrowingContinuation { continuation in
//            locationManager.requestLocation()
//            
//            var locationRequestCompleted = false
//            
//            locationCompletion = { result in
//                guard !locationRequestCompleted else { return }
//                
//                switch result {
//                case .success(let location):
//                    locationRequestCompleted = true
//                    continuation.resume(returning: location)
//                case .failure(let error):
//                    locationRequestCompleted = true
//                    continuation.resume(throwing: error)
//                }
//            }
//            
//            Task {
//                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
//                guard !locationRequestCompleted else { return }
//                locationRequestCompleted = true
//                continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
//            }
//        }
//    }
//    
//    private func fetchAddress(for location: CLLocation) async throws -> (String, String, String, String) {
//        return try await withCheckedThrowingContinuation { continuation in
//            let geocoder = CLGeocoder()
//            geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                } else if let placemark = placemarks?.first {
//                    let city = placemark.locality ?? ""
//                    let state = placemark.administrativeArea ?? ""
//                    let zipcode = placemark.postalCode ?? ""
//                    let country = placemark.country ?? ""
//                    continuation.resume(returning: (city, state, zipcode, country))
//                } else {
//                    continuation.resume(throwing: NSError(domain: "No placemark found", code: 6, userInfo: nil))
//                }
//            }
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else {
//            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
//            return
//        }
//        
//        locationCompletion?(.success(location))
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        DispatchQueue.main.async {
//            self.isLocationDenied = (status == .denied || status == .restricted)
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        locationCompletion?(.failure(error))
//    }
//    
//    // Function that accepts a CLLocationCoordinate2D and creates a CLLocation object
//    // Function that takes CLLocationCoordinate2D as an argument
//    func processLocation(coordinate: CLLocationCoordinate2D) {
//        // Create a CLLocation object using the provided coordinates
//        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//        
//        // Do something with the location
//        print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
//    }
//}


//import CoreLocation
//import Foundation
//import CoreMotion
//import UIKit
//
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    static let shared = LocationManager()
//    private let locationManager = CLLocationManager()
//    @Published var city: String = ""
//    @Published var state: String = ""
//    @Published var zipcode: String = ""
//    @Published var country: String = ""
//    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
//    @State private var userLocation: CLLocationCoordinate2D? = nil
//
//
////    private var locationCompletion: ((Result<(CLLocation, String, String, String, String), Error>) -> Void)?
//    @Published var isLocationDenied: Bool = false
//    
//    @Published var authroizationStatus: CLAuthorizationStatus = .notDetermined
//    // In LocationManager
//    var isLocationAuthorized: Bool {
//        return authroizationStatus == .authorizedWhenInUse || authroizationStatus == .authorizedAlways
//    }
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        
//    }
//    //    // Request location authorization
//        func requestLocationAuthorization() {
//            locationManager.requestWhenInUseAuthorization()
//        }
//    
//    // Asynchronous method to get the address for a location
//    private func fetchAddress(for location: CLLocation) async throws -> (String, String, String, String) {
//        return try await withCheckedThrowingContinuation { continuation in
//            let geocoder = CLGeocoder()
//            geocoder.reverseGeocodeLocation(location) { placemarks, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                } else if let placemark = placemarks?.first {
//                    let city = placemark.locality ?? ""
//                    let state = placemark.administrativeArea ?? ""
//                    let zipcode = placemark.postalCode ?? ""
//                    let country = placemark.country ?? ""
//                    continuation.resume(returning: (city, state, zipcode, country))
//                } else {
//                    continuation.resume(throwing: NSError(domain: "No placemark found", code: 6, userInfo: nil))
//                }
//            }
//        }
//    }
//    
//    // Request current location asynchronously
//    func getCurrentLocation() async throws -> (CLLocation, String, String, String, String) {
//        guard CLLocationManager.locationServicesEnabled() else {
//            throw NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)
//        }
//        
//        let authorizationStatus = locationManager.authorizationStatus
//        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
//            throw NSError(domain: "Location authorization denied", code: 1, userInfo: nil)
//        }
//        
//        let location = try await getLocationUpdate()
//        let (city, state, zipcode, country) = try await fetchAddress(for: location)
//        
//        return (location, city, state, zipcode, country)
//    }
//
//
//      // Helper method to get location update asynchronously
//    private func getLocationUpdate() async throws -> CLLocation {
//        return try await withCheckedThrowingContinuation { continuation in
//            locationManager.requestLocation()
//            
//            var locationRequestCompleted = false
//
//            locationCompletion = { result in
//                guard !locationRequestCompleted else { return }
//                
//                switch result {
//                case .success(let location):
//                    locationRequestCompleted = true
//                    continuation.resume(returning: location)
//                case .failure(let error):
//                    locationRequestCompleted = true
//                    continuation.resume(throwing: error)
//                }
//            }
//            
//            Task {
//                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
//                guard !locationRequestCompleted else { return }
//                locationRequestCompleted = true
//                continuation.resume(throwing: NSError(domain: "Location request timed out", code: 2, userInfo: nil))
//            }
//        }
//    }
//    
//    // CLLocationManagerDelegate method: handles location updates
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else {
//            locationCompletion?(.failure(NSError(domain: "Location not available", code: 3, userInfo: nil)))
//            return
//        }
//        
//        locationCompletion?(.success(location)) // Return only CLLocation
//    }
//    
//    // CLLocationManagerDelegate method: handles authorization changes
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        DispatchQueue.main.async {
//            self.isLocationDenied = (status == .denied || status == .restricted)
//        }
//    }
//
//    // CLLocationManagerDelegate method: handles location errors
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        locationCompletion?(.failure(error))
//    }
//    
//    // Calculate distance between two locations in kilometers
//    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
//        return from.distance(from: to) / 1000 // Convert meters to kilometers
//    }
//}


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
