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
        NavigationStack {
            VStack(alignment: .leading, spacing: 16)  {
                Picker("Select View", selection: $selectedView) {
                    Text("Swaps").tag("Swaps")
                    Text("Cart").tag("Cart")
                    
                }
                .pickerStyle(SegmentedPickerStyle())
//                .padding()
                
                if selectedView == "Cart" {
                    SwapCartView()
                } else {
                    SwappedItemsView()
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Just Swap")
                        .font(.headline)
                        .foregroundStyle(Color("thirdColor"))
                }
            }
            
            
        }
    }
}

#Preview {
    SwappedView()
}
