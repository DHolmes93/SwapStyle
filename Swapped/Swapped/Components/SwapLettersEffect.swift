//
//  SwapLettersEffect.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/10/24.
//

import Foundation

import SwiftUI

struct SwapLettersEffect: ViewModifier {
    @State private var letters: [Character]
    @State private var offset: Int = 0
    private let originalText: String
    private let animation: Animation
    
    init(text: String, animation: Animation = .easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
        self._letters = State(initialValue: Array(text))
        self.originalText = text
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Text(String(letters))
                    .onAppear {
                        withAnimation(animation) {
                            offset = 1
                        }
                    }
                    .onChange(of: offset) { _ in
                        swapLetters()
                    }
            )
    }
    
    private func swapLetters() {
        guard letters.count > 1 else { return }
        let firstIndex = Int.random(in: 0..<letters.count)
        let secondIndex = (firstIndex + 1) % letters.count
        
        letters.swapAt(firstIndex, secondIndex)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(animation) {
                offset = offset == 0 ? 1 : 0
            }
        }
    }
}

extension View {
    func swapLettersEffect(text: String, animation: Animation = .easeInOut(duration: 0.5).repeatForever(autoreverses: true)) -> some View {
        self.modifier(SwapLettersEffect(text: text, animation: animation))
    }
}
