//
//  HomeScreenGridView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/15/24.
//

import SwiftUI
import CoreLocation

struct HomeScreenGridView: View {
    @EnvironmentObject private var itemManager: ItemManager
    @State private var userLocation: CLLocation?
    @State private var isLoading = true
    var body: some View {
        NavigationView {
                    ScrollView {
                        if isLoading {
                            ProgressView("Loading items...")
                        } else {
                            VStack(alignment: .leading) {
                                ForEach(["5km", "15km", "25km", "50km+"], id: \.self) { distanceCategory in
                                    if let items = itemManager.itemsByDistance[distanceCategory], !items.isEmpty {
                                        Text("Within \(distanceCategory)")
                                            .font(.headline)
                                            .padding([.top, .leading])
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 150))], spacing: 20) {
                                            ForEach(items) { item in
                                                VStack {
                                                    if let imageUrl = item.imageUrls.first, let url = URL(string: imageUrl) {
                                                        AsyncImage(url: url) { image in
                                                            image.resizable().aspectRatio(contentMode: .fill)
                                                        } placeholder: {
                                                            ProgressView()
                                                        }
                                                        .frame(height: 150)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                    }
                                                    Text(item.name)
                                                        .font(.headline)
                                                        .lineLimit(1)
                                                }
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(8)
                                                .shadow(radius: 3)
                                            }
                                        }
                                        .padding([.leading, .trailing, .bottom])
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Nearby Items")
                    .onAppear(perform: loadItems)
                }
            }
    private func loadItems() {
            LocationManager.shared.getCurrentLocation { result in
                switch result {
                case .success(let location):
                    self.userLocation = location
                    itemManager.fetchItemsByDistance(location) { _ in
                        isLoading = false
                    }
                case .failure(let error):
                    print("Failed to get location: \(error)")
                    isLoading = false
            }
        }
    }
}

#Preview {
    HomeScreenGridView()
        .environmentObject(ItemManager.shared)
}
