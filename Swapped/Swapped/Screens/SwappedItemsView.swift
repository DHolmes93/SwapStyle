//
//  SwappedItemsView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import SwiftUI

struct SwappedItemsView: View {
    var body: some View {
        VStack {
            List {
                VStack(alignment: .leading) {
                    Text("User: James Evans")
                    Text("Date: 2024-07-04")
                    Text("Review: Great Transaction!")
                    HStack {
                        Text("Rating: ")
                        ForEach(0..<5) { star in
                        Image(systemName: star < 4 ?"star.fill" : "star")}
                }
                    
                }
                
            }
            Spacer()
        }
        .navigationTitle("Swapped Items")
    }
        
    
}



#Preview {
    SwappedItemsView()
}
