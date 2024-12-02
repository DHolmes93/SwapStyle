//
//  Interests&GoalsView.swift
//  Just Swap
//
//  Created by Donovan Holmes on 9/26/24.
//
import SwiftUI

struct InterestsGoalsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @EnvironmentObject private var categoryManager: CategoryManager
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false
    @State private var isProfileComplete = false
    @State private var profilePictureAdded = false
    @State private var selectedGoals: [ProfileItem] = []
    @State private var selectedInterests: [ProfileItem] = []
    @State private var selectedSkills: [ProfileItem] = []
    @State private var showingSuccessAlert = false
    @State private var navigateToMainView = false
    @State private var navigateToAddProfilePicture = false

    var body: some View {
        VStack(spacing: 20) {
            Image("Swap-2")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Text("Set Your Goals, Interests, and Skills")
                .font(.largeTitle)
                .foregroundColor(.black)

            goalsSection
            interestsSection
            skillsSection
            Spacer()

            NavigationLink(
                destination: AddProfilePictureView(selectedGoals: selectedGoals, selectedInterests: selectedInterests, selectedSkills: selectedSkills),
                isActive: $navigateToAddProfilePicture
            ) {
                Button("Add Profile Picture") {
                    Task {
                        await saveCompleteProfile()
                    }
                }
                .padding()
                .background(profilePictureAdded ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!profilePictureAdded || isLoading)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showingSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text(successMessage ?? "Profile updated successfully!"),
                dismissButton: .default(Text("OK")) {
                    isProfileComplete = true
                }
            )
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading) {
            Text("Your Goals")
                .font(.headline)
                .padding(.bottom, 5)

            HStack {
                ForEach(selectedGoals) { goal in
                    goalView(goal: goal) {
                        removeGoal(goal)
                    }
                }
                Spacer()
            }

            ScrollView(.horizontal) {
                HStack {
                    ForEach(ProfileData.predefinedGoals) { goal in
                        goalButton(goal: goal) {
                            toggleGoal(goal: goal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var interestsSection: some View {
        VStack(alignment: .leading) {
            Text("Your Interests")
                .font(.headline)
                .padding(.bottom, 5)

            HStack {
                ForEach(selectedInterests) { interest in
                    goalView(goal: interest) {
                        removeInterest(interest)
                    }
                }
                Spacer()
            }

            ScrollView(.horizontal) {
                HStack {
                    ForEach(ProfileData.predefinedInterests + dynamicInterests()) { interest in
                        interestButton(interest: interest)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var skillsSection: some View {
        VStack(alignment: .leading) {
            Text("Your Skills")
                .font(.headline)
                .padding(.bottom, 5)

            HStack {
                ForEach(selectedSkills) { skill in
                    goalView(goal: skill) {
                        removeSkill(skill)
                    }
                }
                Spacer()
            }

            ScrollView(.horizontal) {
                HStack {
                    ForEach(ProfileData.predefinedSkills) { skill in
                        goalButton(goal: skill) {
                            toggleSkill(skill: skill)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func saveCompleteProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        userAccountModel.goals = selectedGoals.map { $0.name }
        userAccountModel.interests = selectedInterests.map { $0.name }
        userAccountModel.skills = selectedSkills.map { $0.name }
        
        let success = await userAccountModel.createProfile()
        
        if success {
            successMessage = "Profile saved successfully!"
            showingSuccessAlert = true
            isProfileComplete = true
        } else {
            errorMessage = "Failed to save profile."
        }
        
        isLoading = false
    }

    private func dynamicInterests() -> [ProfileItem] {
        return categoryManager.categories.map { ProfileItem(name: $0.name) }
    }

    private func goalView(goal: ProfileItem, removeAction: @escaping () -> Void) -> some View {
        HStack {
            Text(goal.name)
                .padding(5)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            Button(action: removeAction) {
                Text("x")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private func goalButton(goal: ProfileItem, addAction: @escaping () -> Void) -> some View {
        Button(action: addAction) {
            Text(goal.name)
                .padding(5)
                .background(selectedGoals.contains(where: { $0.name == goal.name }) ? Color.blue : Color.gray.opacity(0.5))
                .cornerRadius(5)
        }
    }

    private func interestButton(interest: ProfileItem) -> some View {
        Button(action: {
            toggleInterest(interest: interest)
        }) {
            Text(interest.name)
                .padding(5)
                .background(selectedInterests.contains(where: { $0.name == interest.name }) ? Color.blue : Color.gray.opacity(0.5))
                .cornerRadius(5)
        }
    }

    private func toggleGoal(goal: ProfileItem) {
        if let index = selectedGoals.firstIndex(where: { $0.name == goal.name }) {
            selectedGoals.remove(at: index)
        } else {
            selectedGoals.append(goal)
        }
    }

    private func toggleInterest(interest: ProfileItem) {
        if let index = selectedInterests.firstIndex(where: { $0.name == interest.name }) {
            selectedInterests.remove(at: index)
        } else {
            selectedInterests.append(interest)
        }
    }

    private func toggleSkill(skill: ProfileItem) {
        if let index = selectedSkills.firstIndex(where: { $0.name == skill.name }) {
            selectedSkills.remove(at: index)
        } else {
            selectedSkills.append(skill)
        }
    }

    private func removeGoal(_ goal: ProfileItem) {
        if let index = selectedGoals.firstIndex(where: { $0.name == goal.name }) {
            selectedGoals.remove(at: index)
        }
    }

    private func removeInterest(_ interest: ProfileItem) {
        if let index = selectedInterests.firstIndex(where: { $0.name == interest.name }) {
            selectedInterests.remove(at: index)
        }
    }

    private func removeSkill(_ skill: ProfileItem) {
        if let index = selectedSkills.firstIndex(where: { $0.name == skill.name }) {
            selectedSkills.remove(at: index)
        }
    }
}

struct AddProfilePictureView: View {
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var profilePictureAdded = false
    @State private var showingSuccessAlert = false
    @State private var navigateToMainView = false

    // Received from InterestsGoalsView
    var selectedGoals: [ProfileItem]
    var selectedInterests: [ProfileItem]
    var selectedSkills: [ProfileItem]

    var body: some View {
        VStack {
            Text("Choose a Profile Picture")
                .font(.largeTitle)
                .padding()

            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .padding()
            }
            VStack {
                Button(action:  {
                    showingImagePicker = true
                }) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.black)
                   
                }
//                            .background(Color.black)
                            .clipShape(Circle())
            }
                .padding()
            Text("Add Profile Picture")
                
                //            .foregroundColor(.white)
                //            .cornerRadius(10)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            
            Spacer()

            Button("Save Profile") {
                Task {
                    await saveCompleteProfile()
                }
            }
            .padding()
            .background(profileImage != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(profileImage == nil || isLoading)

            Spacer()
        }
        .padding()
        .alert(isPresented: $showingSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text(successMessage ?? "Profile saved successfully!"),
                dismissButton: .default(Text("OK")) {
                    navigateToMainView = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage, images: .constant([]), selectionLimit: 1)
        }
    }

    private func saveCompleteProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        guard let image = profileImage else { return }

        userAccountModel.goals = selectedGoals.map { $0.name }
        userAccountModel.interests = selectedInterests.map { $0.name }
        userAccountModel.skills = selectedSkills.map { $0.name }

        let profileSaveSuccess = await userAccountModel.createProfile()
        let imageUploadSuccess = await userAccountModel.uploadProfileImage(image: image)

        if profileSaveSuccess && imageUploadSuccess {
            successMessage = "Profile and picture saved successfully!"
            showingSuccessAlert = true
            profilePictureAdded = true
            checkProfileCompletion()
        } else {
            errorMessage = "Failed to save profile or upload picture."
        }

        isLoading = false
    }

    private func checkProfileCompletion() {
        if selectedGoals.isEmpty || selectedInterests.isEmpty || selectedSkills.isEmpty || profileImage == nil {
            errorMessage = "Please complete all sections of your profile."
        } else {
            successMessage = "Your profile is complete!"
            showingSuccessAlert = true
        }
    }
}
#Preview {
    InterestsGoalsView()
}
