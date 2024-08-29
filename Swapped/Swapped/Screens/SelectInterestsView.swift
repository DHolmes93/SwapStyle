//
//  SelectInterestsView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//

import SwiftUI

struct SelectInterestsView: View {
    @StateObject private var viewModel = UserAccountModel()
    @StateObject private var motionManager = MotionManager()
    @State private var selectedCategories: [Category] = []
    @ObservedObject private var categoryManager = CategoryManager.shared

    var body: some View {
        VStack {
            Spacer()

            Text("Select Your Interests")
                .font(.largeTitle)
                .padding()

            Spacer()

            HStack {
                ForEach(categoryManager.categories) { category in
                    PreferenceBall(
                        category: category,
                        isSelected: Binding<Bool>(
                            get: { selectedCategories.contains(category) },
                            set: { isSelected in
                                if isSelected {
                                    selectedCategories.append(category)
                                } else {
                                    selectedCategories.removeAll { $0 == category }
                                }
                            }
                        ),
                        motionManager: motionManager
                    )
                    .padding(5)
                }
            }

            Spacer()

            Button(action: {
                viewModel.interests = selectedCategories.map { $0.name }
                viewModel.saveUserDetails()
            }) {
                Text("Save Interests")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.bottom, 30)
        }
        .padding()
        .onTapGesture {
            withAnimation {
                // Trigger the shaking animation on all balls
                startShaking()
            }
        }
    }

    func startShaking() {
        let baseAnimation = Animation.default.repeatForever(autoreverses: true)
        for category in categoryManager.categories {
            if let index = categoryManager.categories.firstIndex(of: category) {
                withAnimation(baseAnimation) {
                    // Trigger the shake by setting a temporary offset
                    _ = index // this is just to illustrate you can use the index if needed
                }
            }
        }
    }
}
#Preview {
    SelectInterestsView()
}
