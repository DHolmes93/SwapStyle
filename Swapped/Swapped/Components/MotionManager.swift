//
//  MotionManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//

import Foundation
import CoreMotion
import SwiftUI
import Combine

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var motionUpdateInterval: TimeInterval = 1.0 / 60.0

    @Published var xRotation: Double = 0
    @Published var yRotation: Double = 0

    init() {
        startMotionUpdates()
    }

    private func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = motionUpdateInterval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let motion = motion else { return }
                self?.xRotation = motion.attitude.roll
                self?.yRotation = motion.attitude.pitch
            }
        }
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
