//
//  ContentView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var isLoading: Bool = true
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else {
                if authManager.isSignedIn {
                    MainView()
                        .onAppear {
                            requestLocation()
                        }
                } else {
                    SignInView()
                        .onAppear {
                            requestLocation()
                        }
                }
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
    }
    private var loadingView: some View {
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
            // Simulate a delay to check authentication state
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    private func requestLocation() {
        locationManager.requestLocationAuthorization()
    }
}

#Preview {
    ContentView()
}
