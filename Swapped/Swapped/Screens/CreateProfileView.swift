//
//  SignUpView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//
import GooglePlaces
import CoreLocation
import SwiftUI

struct CreateProfileView: View {
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @State private var isSignUpSuccess = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var moveToGoalsAndInterests = false
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date() // Default to 18 years ago
    @State private var locationAuthorizationAlertShown = false
    @StateObject private var locationManager = LocationManager.shared

    // State variables for Google Places Autocomplete
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipcode: String = ""
    @State private var country: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    profileCompletionForm
                    locationInfoSection
                    proceedButton
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                    navigationLinkToGoalsAndInterests
                }
                .padding()
                .onAppear {
                    loadUserLocation() // Load location on appear
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(isPresented: $locationAuthorizationAlertShown) {
            Alert(title: Text("Location Access Denied"),
                  message: Text("Please enable location access in Settings."),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("Swap-2")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(.top, 40)
            
            Text("Complete Your Profile")
                .font(.title)
                .bold()
                .foregroundColor(.black)
                .padding(.top, 10)
        }
    }

    // MARK: - Profile Completion Form
    private var profileCompletionForm: some View {
        VStack(spacing: 12) {
            TextField("Name", text: $userAccountModel.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("Email: \(authManager.currentUser?.email ?? "Not available")")
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            DatePicker("Birthdate", selection: $birthdate, in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                       displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.horizontal)
//            
//            Text("Purpose Wheel Picker Placeholder")
//                .padding(.horizontal)
//                .foregroundColor(.gray)
        }
    }

    // MARK: - Location Info Section
    private var locationInfoSection: some View {
        VStack(spacing: 4) {
            locationInfoRow(title: "City", value: city)
            locationInfoRow(title: "State", value: state)
            locationInfoRow(title: "Zipcode", value: zipcode)
            locationInfoRow(title: "Country", value: country)
        }
    }

    private func locationInfoRow(title: String, value: String) -> some View {
        HStack {
            Text("\(title):")
                .foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "Not selected" : value)
                .foregroundColor(value.isEmpty ? .gray : .primary)
        }
        .padding(.horizontal)
    }

    // MARK: - Proceed Button
    private var proceedButton: some View {
        Button(action: proceedToGoalsAndInterests) {
            VStack {
                Image("Swap-2")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                Text("Next")
            }
            .disabled(isLoading)
            .padding(.top, 20)
        }
    }

    // MARK: - Navigation Link
    private var navigationLinkToGoalsAndInterests: some View {
        NavigationLink(destination: InterestsGoalsView(), isActive: $moveToGoalsAndInterests) {
            EmptyView()
        }
    }

    // MARK: - Action Methods
    private func proceedToGoalsAndInterests() {
        guard validateFields() else {
            DispatchQueue.main.async {
                self.errorMessage = "Please fill out all fields."
            }
            return
        }
        
        guard isAtLeast18YearsOld(birthdate: birthdate) else {
            DispatchQueue.main.async {
                self.errorMessage = "You must be at least 18 years old to sign up."
            }
            return
        }

        DispatchQueue.main.async {
            // Set userAccountModel properties
            userAccountModel.city = city
            userAccountModel.state = state
            userAccountModel.zipcode = zipcode
            userAccountModel.country = country
            userAccountModel.birthdate = birthdate
            moveToGoalsAndInterests = true
        }
    }

    private func validateFields() -> Bool {
        return !userAccountModel.name.isEmpty &&
               !(authManager.currentUser?.email.isEmpty ?? true) &&
               !city.isEmpty && !state.isEmpty && !zipcode.isEmpty && !country.isEmpty
    }

    private func isAtLeast18YearsOld(birthdate: Date) -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: currentDate)
        return ageComponents.year ?? 0 >= 18
    }

    private func requestLocationAccess() async {
        do {
            try await locationManager.requestLocationAuthorization() // Use `try` to handle the throwing function
            DispatchQueue.main.async {
                if locationManager.isLocationDenied {
                    locationAuthorizationAlertShown = true
                } else {
                    loadUserLocation()
                }
            }
        } catch {
            // Handle the error here
            print("Failed to request location authorization: \(error.localizedDescription)")
            DispatchQueue.main.async {
                locationAuthorizationAlertShown = true
            }
        }
    }


    private func loadUserLocation() {
        Task {
            do {
                let (_, city, state, zip, country) = try await LocationManager.shared.getCurrentLocation()
                self.city = city
                self.state = state
                self.zipcode = zip
                self.country = country

                // Update userAccountModel with fetched values
                userAccountModel.city = city
                userAccountModel.state = state
                userAccountModel.zipcode = zip
                userAccountModel.country = country
            } catch {
                print("Error fetching current location: \(error.localizedDescription)")
            }
        }
    }
}


