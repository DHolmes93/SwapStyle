//
//  LocationManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/14/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private var locationManager: CLLocationManager
    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
    
    
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    func requestLocationAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(NSError(domain: "Location services are not enabled", code: 0, userInfo: nil)))
            return
        }
        self.locationCompletion = completion
        self.locationManager.requestLocation()
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            print("Location authroization status not determined")
        case .restricted, .denied:
            print("Location authorization denied or restricted")
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location authorized")
        @unknown default:
            print("Unknown location authorization status")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationCompletion = locationCompletion {
            locationCompletion(.failure(error))
            self.locationCompletion = nil
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationCompletion = locationCompletion, let location = locations.first {
            locationCompletion(.success(location))
            self.locationCompletion = nil
        }
    }
}
