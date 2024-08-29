//
//  PreferenceBall.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//

import Foundation
import SwiftUI

struct PreferenceBall: View {
    let category: Category
    @Binding var isSelected: Bool
    @ObservedObject var motionManager: MotionManager
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        Text(category.name)
            .padding()
            .background(isSelected ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(Circle())
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .offset(x: CGFloat(motionManager.xRotation * 10) + shakeOffset, y: CGFloat(motionManager.yRotation * 10))
            .animation(.easeInOut, value: isSelected)
            .onTapGesture {
                withAnimation {
                    isSelected.toggle()
                }
            }
            .onAppear {
                startShaking()
            }
    }

    func startShaking() {
        let baseAnimation = Animation.default.repeatForever(autoreverses: true)
        withAnimation(baseAnimation) {
            shakeOffset = 10
        }
    }
}
