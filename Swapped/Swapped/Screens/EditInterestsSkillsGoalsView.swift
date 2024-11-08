//
//  EditInterestsSkillsGoalsView.swift
//  Just Swap
//
//  Created by Donovan Holmes on 10/30/24.
//
import SwiftUI

struct EditInterestsSkillsGoalsView: View {
    @ObservedObject var userAccountModel: UserAccountModel
    @StateObject private var profile = Profile() // Manage selections
    @State private var hasChanges = false // Track if there are changes

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Add or Remove Interests, Skills, Goals")
                    .font(.headline)
                    .padding()

                // Unified scrollable view for Interests, Skills, and Goals
                ScrollView {
                    VStack(spacing: 20) {
                        // Interests Section
                        SectionView(
                            title: "Interests",
                            items: ProfileData.predefinedInterests,
                            selectedItems: profile.tempSelectedInterests,
                            addAction: { item in
                                profile.addTempInterest(item)
                                hasChanges = true
                            },
                            removeAction: { item in
                                profile.removeTempInterest(item)
                                hasChanges = true
                            }
                        )

                        // Skills Section
                        SectionView(
                            title: "Skills",
                            items: ProfileData.predefinedSkills,
                            selectedItems: profile.tempSelectedSkills,
                            addAction: { item in
                                profile.addTempSkill(item)
                                hasChanges = true
                            },
                            removeAction: { item in
                                profile.removeTempSkill(item)
                                hasChanges = true
                            }
                        )

                        // Goals Section
                        SectionView(
                            title: "Goals",
                            items: ProfileData.predefinedGoals,
                            selectedItems: profile.tempSelectedGoals,
                            addAction: { item in
                                profile.addTempGoal(item)
                                hasChanges = true
                            },
                            removeAction: { item in
                                profile.removeTempGoal(item)
                                hasChanges = true
                            }
                        )
                    }
                    .padding()
                }

                // Save button at the bottom
                if hasChanges {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Spacer()
            }
            .navigationTitle("Edit Profile Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Optionally handle any finalization (e.g., discard changes)
                    }
                }
            }
            .onAppear {
                loadUserSelections() // Load user selections on appear
            }
        }
    }

    private func loadUserSelections() {
        // Load user's existing interests, skills, and goals into temporary storage
        profile.loadTempInterests(from: userAccountModel.interests)
        profile.loadTempSkills(from: userAccountModel.skills)
        profile.loadTempGoals(from: userAccountModel.goals)
        hasChanges = false // Reset change tracking
    }

    private func saveChanges() {
        Task {
            userAccountModel.interests = profile.getTempSelectedInterests().map { $0.name }
            userAccountModel.skills = profile.getTempSelectedSkills().map { $0.name }
            userAccountModel.goals = profile.getTempSelectedGoals().map { $0.name }
            await userAccountModel.saveUserDetails()
            hasChanges = false // Reset change tracking
        }
    }
}

// Subview for each category section
struct SectionView: View {
    let title: String
    let items: [ProfileItem]
    let selectedItems: [ProfileItem]
    let addAction: (ProfileItem) -> Void
    let removeAction: (ProfileItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .bold()
                .padding(.leading)

            // Selected Items Display - Horizontal ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(selectedItems) { item in
                        HStack {
                            Text(item.name)
                                .padding(5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            Button(action: {
                                removeAction(item)
                            }) {
                                Text("✖")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding(.trailing, 5)
                    }
                }
                .padding(.vertical, 5)
            }

            // Word Bank Display - Tap to Add/Remove
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items) { item in
                        Text(item.name)
                            .padding(5)
                            .background(selectedItems.contains(where: { $0.id == item.id }) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedItems.contains(where: { $0.id == item.id }) ? .white : .black)
                            .cornerRadius(8)
                            .onTapGesture {
                                if selectedItems.contains(where: { $0.id == item.id }) {
                                    removeAction(item)  // Remove if already selected
                                } else {
                                    addAction(item)     // Add if not selected
                                }
                            }
                            .padding(.horizontal, 5)
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.horizontal)
    }
}
