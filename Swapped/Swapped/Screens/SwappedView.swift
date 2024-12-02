//
//  SwappedItemsView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import SwiftUI

struct SwappedView: View {
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    @EnvironmentObject var swapCart: SwapCart
    @State private var selectedView = "Swapped Items"
    var body: some View {
        VStack {
            Picker("Select View", selection: $selectedView) {
                Text("Swapped Items").tag("Swapped Items")
                Text("Cart").tag("Cart")
                    
                }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedView == "Cart" {
                SwapCartView()
            } else {
                SwappedItemsView()
                
            }
        }
        .navigationTitle("Swapped Items")
    }
        
    
}



#Preview {
    SwappedView()
}
