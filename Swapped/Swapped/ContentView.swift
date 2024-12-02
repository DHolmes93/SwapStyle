//
//  ContentView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager.shared
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @StateObject private var swapCart = SwapCart.shared
    @StateObject private var categoryManager = CategoryManager.shared
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var profile = Profile()
    @StateObject private var profileItem = ProfileData()
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                loadingViewContent()
            } else {
                if authManager.isSignedIn {
                    MainView()
                        .environmentObject(userAccountModel)
                        .environmentObject(itemManager)
                        .environmentObject(categoryManager)
                        .environmentObject(swapCart)
                    
                        .onAppear {
                            requestLocation()
                        }
                } else {
                    SignInView()
                        .environmentObject(userAccountModel)// Show sign-in view when not signed in
                        .onAppear {
                            requestLocation()
                        }
                }
            }
        }
        .onAppear {
            checkAuthenticationState()
            // Listen for user signed-in notification
            NotificationCenter.default.addObserver(forName: .userSignedIn, object: nil, queue: .main) { _ in
                // User signed-in notification, no further profile check needed
                isLoading = false // Ensure loading is stopped
            }
        }
        .onDisappear {
            // Remove observer when the view disappears
            NotificationCenter.default.removeObserver(self, name: .userSignedIn, object: nil)
        }
    }

    @ViewBuilder
    func loadingViewContent() -> some View {
        VStack {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()

            Image(systemName: "globe")
                .resizable()
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isLoading)
        }
    }

    private func checkAuthenticationState() {
        // Check if there is a currently signed-in user
        if Auth.auth().currentUser != nil {
            authManager.isSignedIn = true
            isLoading = false
        } else {
            // Simulate loading state for a brief period
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }

    private func requestLocation() {
        Task {
            do {
                let (location, city, state, zip, country) = try await LocationManager.shared.getCurrentLocation()
//                print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                print("City: \(city), State: \(state), Zip: \(zip), Country: \(country)")
            } catch {
                print("Failed to get location: \(error.localizedDescription)")
            }
        }
    }

}

// Extend Notification.Name to create a custom notification for user sign-in
extension Notification.Name {
    static let userSignedIn = Notification.Name("userSignedIn")
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(LocationManager())
}
