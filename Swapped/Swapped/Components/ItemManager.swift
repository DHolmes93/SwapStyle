//
//  ItemModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import Foundation

import FirebaseFirestoreSwift


struct Item: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var details: String
    var price: String
    var photoURL: String
    var timestamp: Date
}



