//
//  ScrambleEffect.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/3/24.
//

import Foundation
import SwiftUI


struct ScrambleEffect: ViewModifier {
    @State private var displayText: String
    private var text: String
    private var interval: TimeInterval
    private var characterSet: String
    
    init(text: String, interval: TimeInterval = 0.05, characterSet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
        self.text = text
        self.interval = interval
        self.characterSet = characterSet
        _displayText = State(initialValue: text)
    }
    func body(content: Content) -> some View {
        content
            .overlay(
                Text(displayText)
                    .onAppear(perform: startScrambling)
            )
    }
    private func startScrambling() {
        let letters = Array(text)
        let characters = Array(characterSet)
        var currentIndex = 0
        var scrambleTimer: Timer?
        
        func startTimer() {
            scrambleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if currentIndex >= letters.count {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        currentIndex = 0
                        startTimer()
                    }
                } else {
                    var newDisplayText = letters.map { String($0) }
                    newDisplayText[currentIndex] = String(characters.randomElement() ?? letters[currentIndex])
                    displayText = newDisplayText.joined()
                    
                    if Int.random(in: 0...5) == 0 {
                        currentIndex += 1
                    }
                }
                
            }
        }
        startTimer()
    }
}
extension View {
    func scrambleEffect(text: String, interval: TimeInterval = 0.05, characterSet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ") -> some View {
        self.modifier(ScrambleEffect(text: text, interval: interval, characterSet: characterSet))
    }
}
