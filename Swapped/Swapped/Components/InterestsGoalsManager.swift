//
//  InterestsGoalsManager.swift
//  Just Swap
//
//  Created by Donovan Holmes on 10/22/24.
//
import Foundation

// Define ProfileItem to hold profile data items
class ProfileItem: Identifiable, Hashable {
    let id = UUID()
    var name: String

    init(name: String) {
        self.name = name
    }
    func hash(into hasher: inout Hasher) {
            hasher.combine(id) // Combine the id for hashing
            hasher.combine(name) // Combine the name for hashing
        }

        // Equatable conformance
        static func == (lhs: ProfileItem, rhs: ProfileItem) -> Bool {
            return lhs.id == rhs.id && lhs.name == rhs.name
        }
}

// Define ProfileData with predefined lists
class ProfileData: ObservableObject {
    static let predefinedGoals: [ProfileItem] = [
        ProfileItem(name: "Declutter"),
        ProfileItem(name: "Collect Hats"),
        ProfileItem(name: "Grow Closet"),
        ProfileItem(name: "Travel More"),
        ProfileItem(name: "Learn a New Skill"),
        ProfileItem(name: "Save Money"),
        ProfileItem(name: "Exercise Regularly")
    ]
    
    static let predefinedInterests: [ProfileItem] = [
        ProfileItem(name: "Minimalism"),
        ProfileItem(name: "Sustainability"),
        ProfileItem(name: "Fashion"),
        ProfileItem(name: "Travel"),
        ProfileItem(name: "Technology"),
        ProfileItem(name: "Fitness")
    ]
    
    static let predefinedSkills: [ProfileItem] = [
        ProfileItem(name: "Programming"),
        ProfileItem(name: "Engineering"),
        ProfileItem(name: "Decorating"),
        ProfileItem(name: "Carpentry")
    ]
}

// Define Profile class to manage selected items
class Profile: ObservableObject {
    // Temporary arrays to store selections until saved
    @Published var tempSelectedInterests: [ProfileItem] = []
    @Published var tempSelectedSkills: [ProfileItem] = []
    @Published var tempSelectedGoals: [ProfileItem] = []
    
    // Load functions for temporary selections
    func loadTempInterests(from interests: [String]) {
        DispatchQueue.main.async {
            self.tempSelectedInterests = interests.map { ProfileItem(name: $0) }
        }
    }

    func loadTempSkills(from skills: [String]) {
        DispatchQueue.main.async {
            self.tempSelectedSkills = skills.map { ProfileItem(name: $0) }
        }
    }

    func loadTempGoals(from goals: [String]) {
        DispatchQueue.main.async {
            self.tempSelectedGoals = goals.map { ProfileItem(name: $0) }
        }
    }

    // Add and remove methods for temporary selections
    func addTempInterest(_ item: ProfileItem) {
        DispatchQueue.main.async {
            if !self.tempSelectedInterests.contains(where: { $0.id == item.id }) {
                self.tempSelectedInterests.append(item)
            }
        }
    }

    func removeTempInterest(_ item: ProfileItem) {
        DispatchQueue.main.async {
            self.tempSelectedInterests.removeAll(where: { $0.id == item.id })
        }
    }

    func addTempSkill(_ item: ProfileItem) {
        DispatchQueue.main.async {
            if !self.tempSelectedSkills.contains(where: { $0.id == item.id }) {
                self.tempSelectedSkills.append(item)
            }
        }
    }

    func removeTempSkill(_ item: ProfileItem) {
        DispatchQueue.main.async {
            self.tempSelectedSkills.removeAll(where: { $0.id == item.id })
        }
    }

    func addTempGoal(_ item: ProfileItem) {
        DispatchQueue.main.async {
            if !self.tempSelectedGoals.contains(where: { $0.id == item.id }) {
                self.tempSelectedGoals.append(item)
            }
        }
    }

    func removeTempGoal(_ item: ProfileItem) {
        DispatchQueue.main.async {
            self.tempSelectedGoals.removeAll(where: { $0.id == item.id })
        }
    }

    // Methods to get final selections for saving
    func getTempSelectedInterests() -> [ProfileItem] {
        return tempSelectedInterests
    }

    func getTempSelectedSkills() -> [ProfileItem] {
        return tempSelectedSkills
    }

    func getTempSelectedGoals() -> [ProfileItem] {
        return tempSelectedGoals
    }
}

