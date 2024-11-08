//
//  GoogleSignInButton.swift
//  Swapped
//
//  Created by Donovan Holmes on 9/23/24.

import SwiftUI
import GoogleSignInSwift

struct SignInWithGoogleButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Image("google_logo") // Add your Google logo image asset
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24) // Adjust size of the logo
                Text("Sign in with Google")
                    .font(.system(size: 14)) // Adjust font size if needed
                    .foregroundColor(.black) // Set text color
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white) // Button background color
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2) // Optional shadow
        }
        .frame(width: 50) // Set a fixed width for the button
    }
}

#Preview {
    SignInWithGoogleButton {
        print("Sign In With Google")
    }
}


