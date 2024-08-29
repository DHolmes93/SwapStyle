//
//  TossLettersEffect.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/10/24.
//

//import Foundation
//import SwiftUI
//
//struct TossLettersEffect: ViewModifier {
//    let sourceWord: String
//    let destinationWord: String
//    let animation: Animation
//    
//    @State private var currentWord: String
//    @State private var letterOffsets: [Int: CGSize] = [:]
//    @State private var isSwapping: Bool = false
//    
//    init(source: String, destination: String, animation: Animation = .easeInOut(duration: 0.5)) {
//        self.sourceWord = source
//        self.destinationWord = destination
//        self.animation = animation
//        self._currentWord = State(initialValue: source)
//    }
//    
//    func body(content: Content) -> some View {
//        content
//            .overlay(
//                ZStack {
//                    ForEach(currentWord.indices, id: \.self) { index in
//                        Text(String(currentWord[index]))
//                            .offset(letterOffsets[index] ?? .zero)
//                    }
//                }
//                .animation(animation)
//                .onChange(of: currentWord) { newWord in
//                    animateLetters(from: newWord == sourceWord ? destinationWord : sourceWord, to: newWord)
//                }
//            )
//            .onAppear {
//                animateLetters(from: sourceWord, to: destinationWord)
//            }
//    }
//    
//    private func animateLetters(from source: String, to destination: String) {
//        guard source != destination else { return }
//        
//        withAnimation(animation) {
//            isSwapping.toggle()
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            currentWord = isSwapping ? destination : source
//        }
//        
//        let sourceLetters = Array(source)
//        let destinationLetters = Array(destination)
//        
//        for (index, letter) in sourceLetters.enumerated() {
//            let destinationIndex = destinationLetters.firstIndex(of: letter) ?? index
//            letterOffsets[index] = computeOffset(from: index, to: destinationIndex)
//        }
//    }
//    
//    private func computeOffset(from sourceIndex: Int, to destinationIndex: Int) -> CGSize {
//        let xOffset = CGFloat(destinationIndex - sourceIndex) * 10 // Adjust as needed for spacing
//        return CGSize(width: xOffset, height: 0)
//    }
//}
//
//extension Text {
//    func tossLettersEffect(source: String, destination: String, animation: Animation = .easeInOut(duration: 0.5)) -> some View {
//        self.modifier(TossLettersEffect(source: source, destination: destination, animation: animation))
//    }
//}





