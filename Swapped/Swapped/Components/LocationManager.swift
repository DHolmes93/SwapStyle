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
