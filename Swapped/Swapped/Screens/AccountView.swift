//
//  AccountView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
import SwiftUI
import CoreLocation

struct AccountView: View {
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var itemManager: ItemManager
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
    @StateObject private var locationManager = LocationManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isImagePickerPresented = false
    @State private var showImageSourceDialog = false
    @State private var showDeleteConfirmation = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var navigateToCreateProfile = false
//    var allItems: [Item] // List of all items
//    var userName: String
//    var currentUserId: String // Current user's ID
    
    var body: some View {
        ScrollView {
            NavigationStack {
                VStack(spacing: 20) {
                    ProfileImageView(
                        rating: $viewModel.rating, isImagePickerPresented: $isImagePickerPresented,
                        showImageSourceDialog: $showImageSourceDialog,
                        sourceType: $sourceType, userAccountModel: UserAccountModel.shared
                    )
                    
                    UserFormView(
                        name: $viewModel.name,
                        email: authManager.currentUser?.email,
                        phone: authManager.currentUser?.phoneNumber,
                        city: locationManager.city,
                        state: locationManager.state,
                        zipcode: locationManager.zipcode,
                        country: locationManager.country
                    )
                    
                    ActionButtonsView(
                        onSave: {
                            Task {
                                await viewModel.saveUserDetails() // Call saveUserDetails asynchronously
                            }
                        },
                        onSignOut: {
                            Task {
                                do {
                                    try await authManager.signOut() // Sign out asynchronously
                                    resetToSignInView() // Navigate back to sign-in view
                                } catch {
                                    print("Error signing out: \(error.localizedDescription)")
                                }
                            }
                        },
                        onDelete: {
                            // Show delete confirmation
                            showDeleteConfirmation.toggle()
                        }
                    )
                    
                    Divider()
                    
                    Text("My Items")
                        .font(.headline)
                    
                    UserItemsView(
                        items: $itemManager.items,  // Bind to the items from ItemManager
                        userName: viewModel.name,   // The current user's name from the ViewModel
                        currentUserId: authManager.currentUser?.id ?? "unknown" // The current user ID from AuthManager
                    )
                }
                .padding()
                .navigationTitle("\(viewModel.name)'s Account")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.isProfileCompleted == false {
                                   createProfileButton
                        }
                    }
                }
                .onChange(of: viewModel.isProfileCompleted) { isCompleted in
                    // This will be triggered when isProfileCompleted changes.
                    print("Profile completion status updated: \(isCompleted)")
                }

                .onAppear {
                    Task {
                        await fetchUserDetails() // Fetch user details asynchronously
                        await fetchUserLocation()       // Fetch location when the view appears
                    }
                }
                .alert(isPresented: $locationManager.isLocationDenied) { // Handle denied location
                                Alert(title: Text("Location Access Denied"),
                                      message: Text("Please enable location services in Settings to use this feature."),
                                      dismissButton: .default(Text("OK")))
                            }
                .fullScreenCover(isPresented: $isImagePickerPresented) {
                    ImagePicker(image: $viewModel.profileImage, images: .constant([]), selectionLimit: 1)
                }
            }
        }
    }
    
    private var createProfileButton: some View {
            Button(action: {
                navigateToCreateProfile = true
            }) {
                VStack {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                    Text("Create Profile")
                        .font(.caption)
                }
            }
            .background(
            NavigationLink(destination: CreateProfileView(), isActive: $navigateToCreateProfile) {
                EmptyView() // Placeholder view to trigger navigation
        }
            )
    }
    
    private func fetchUserDetails() async {
        guard (await authManager.currentUser) != nil else {
            print("No current user found.")
            return
        }

        // Fetch user details
        await viewModel.fetchUserDetails()

        // Check if location permission is granted before requesting
        if LocationManager.shared.authorizationStatus == .notDetermined {
            do {
                try await LocationManager.shared.requestLocationAuthorization()
            } catch {
                print("Failed to request location authorization: \(error.localizedDescription)")
                // Handle the error gracefully (e.g., show an alert or fallback behavior)
            }
        }
    }
    private func handleLocationAuthorizationChange(_ newStatus: CLAuthorizationStatus) {
        if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            Task {
                await fetchUserLocation()
            }
        } else if newStatus == .denied || newStatus == .restricted {
            print("Location permission denied or restricted")
        }
    }
    
    // Fetch location and update the user location properties
    private func fetchUserLocation() async {
        do {
            let (location, city, state, zipcode, country) = try await locationManager.getCurrentLocation()
            
            // Populate the view with fetched location data
            DispatchQueue.main.async {
                self.locationManager.city = city
                self.locationManager.state = state
                self.locationManager.zipcode = zipcode
                self.locationManager.country = country
            }
        } catch {
            print("Error fetching location: \(error.localizedDescription)")
        }
    }
    
    private func handleSignInChange(_ newValue: Bool) {
        if !newValue {
            resetToSignInView()
        }
    }
    
    private func resetToSignInView() {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: SignInView().environmentObject(authManager))
            window.makeKeyAndVisible()
        }
    }
}
// Interest and Skill Picker Methods...
struct InterestsSkillsGoalsView: View {
    @ObservedObject var userAccountModel = UserAccountModel(authManager: AuthManager())
    @State private var isEditing = false  // State to track sheet presentation

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 20) {
                // Interests
                VStack(alignment: .leading) {
                    Text("Interests")
                        .font(.headline)
                        .foregroundColor(.black)
                        .bold()
                    // Display interests in a horizontal scrollable view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(userAccountModel.interests, id: \.self) { interest in
                                Text("• \(interest)")
                                    .padding(5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                // Skills
                VStack(alignment: .leading) {
                    Text("Skills")
                        .font(.headline)
                        .foregroundColor(.black)
                        .bold()
                    // Display skills in a horizontal scrollable view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(userAccountModel.skills, id: \.self) { skill in
                                Text("• \(skill)")
                                    .padding(5)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                // Goals
                VStack(alignment: .leading) {
                    Text("Goals")
                        .font(.headline)
                        .foregroundColor(.black)
                        .bold()
                    // Display goals in a horizontal scrollable view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(userAccountModel.goals, id: \.self) { goal in
                                Text("• \(goal)")
                                    .padding(5)
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding()

            // Edit button
            Button("Edit") {
                isEditing.toggle()  // Open sheet
            }
            .sheet(isPresented: $isEditing) {
                EditInterestsSkillsGoalsView(userAccountModel: userAccountModel)
            }
        }
        .onAppear {
            Task {
                let success = await userAccountModel.fetchProfile()
                if !success {
                    print("Failed to load profile data.")
                }
            }
        }
    }
}
struct ProfileImageView: View {
    @Binding var rating: Double
    @Binding var isImagePickerPresented: Bool
    @Binding var showImageSourceDialog: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var userAccountModel: UserAccountModel
    
    var body: some View {
        HStack {
            Button(action: {
                showImageSourceDialog.toggle()
            }) {
                // Check if profile image URL is available, and if so, load it using AsyncImage
                if let profileImageUrl = userAccountModel.profileImageUrl {
                    AsyncImage(url: URL(string: profileImageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(50)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        case .failure:
                            defaultProfileImageView
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 100, height: 100)
                } else if let profileImage = userAccountModel.profileImage {
                    // Use the UIImage if it's available
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                } else {
                    defaultProfileImageView
                }
            }
        }
        .onAppear {
            // Fetch the profile image URL when the view appears
            Task {
                await userAccountModel.fetchProfileImageUrl()
            }
        }
        .confirmationDialog("Select Image Source", isPresented: $showImageSourceDialog, titleVisibility: .visible) {
            Button("Camera") {
                sourceType = .camera
                isImagePickerPresented.toggle()
            }
            Button("Photo Library") {
                sourceType = .photoLibrary
                isImagePickerPresented.toggle()
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $userAccountModel.profileImage, images: .constant([]), selectionLimit: 1)
                .onDisappear {
                    Task {
                        if let image = userAccountModel.profileImage {
                            await uploadProfileImage(image)
                        }
                    }
                }
        }
    }
    
    private var defaultProfileImageView: some View {
        Image(systemName: "person.circle")
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .foregroundColor(.gray)
    }
    
    /// Upload a new profile image to Firebase Storage and update Firestore
    private func uploadProfileImage(_ image: UIImage) async {
        guard (authManager.currentUser?.id) != nil else {
            print("Current user UID not found.")
            return
        }
        
        let success = await userAccountModel.uploadProfileImage(image: image)
        if success {
            // Re-fetch profile image after upload
            Task {
                await userAccountModel.fetchProfileImageUrl()
            }
        } else {
            print("Failed to upload profile image.")
        }
    }
}

struct UserFormView: View {
    @Binding var name: String
    var email: String? // Email is optional
    var phone: String? // Phone is optional
    var city: String
    var state: String
    var zipcode: String
    var country: String

    @State private var isEditingName = false
    @State private var selectedInterestIndex: Int = 0
    @State private var selectedSkillIndex: Int = 0
    @StateObject private var userAccountModel = UserAccountModel(authManager: AuthManager())

    var body: some View {
        VStack(spacing: 20) {
            // Editable Name Field
            HStack {
                if isEditingName {
                    TextField("Enter your name", text: $name, onCommit: {
                        isEditingName = false
                    })
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text(name.isEmpty ? "No Name Set" : name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        isEditingName = true
                    }) {
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            // Display Email (Non-editable)
            if let email = email {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text(email)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal)
            } else {
                Text("Email: N/A")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Optional Phone Display
            if let phone = phone {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                    Text(phone)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            } else {
                Text("Phone: N/A")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Location Information
            Section(header: Text("Location").font(.headline)) {
                HStack {
                    Text("City:")
                    Spacer()
                    Text(city.isEmpty ? "N/A" : city)
                        .foregroundColor(city.isEmpty ? .gray : .primary)
                        .fontWeight(city.isEmpty ? .regular : .bold)
                }

                HStack {
                    Text("State:")
                    Spacer()
                    Text(state.isEmpty ? "N/A" : state)
                        .foregroundColor(state.isEmpty ? .gray : .primary)
                }

                HStack {
                    Text("Country:")
                    Spacer()
                    Text(country.isEmpty ? "N/A" : country)
                        .foregroundColor(country.isEmpty ? .gray : .primary)
                }

                HStack {
                    Text("Zipcode:")
                    Spacer()
                    Text(zipcode.isEmpty ? "N/A" : zipcode)
                        .foregroundColor(zipcode.isEmpty ? .gray : .primary)
                }
            }
            .padding(.horizontal)

            // Interests, Skills, and Goals View
            InterestsSkillsGoalsView(userAccountModel: userAccountModel)

            Spacer()
        }
        .padding()
    }
}
struct ActionButtonsView: View {
    var onSave: () -> Void
    var onSignOut: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 50) {
            VStack(spacing: 8) {
                Button(action: onSave) {
                    VStack {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Save")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
                .padding()
//                .background(Color.blue)
//                .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                Button(action: onSignOut) {
                    VStack {
                        Image(systemName: "figure.wave")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Sign Out")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }
            
            VStack(spacing: 8) {
                Button(action: onDelete) {
                    VStack {
                        Image(systemName: "trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Delete Account")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
                .padding()
//                .background(Color.red)
//                .cornerRadius(8)
            }
        }
    }
}

struct UserItemsView: View {
    @Binding var items: [Item] // The list of items
    var userName: String
    var currentUserId: String // The current user's ID

    var body: some View {
        // Filter items to only include those belonging to the current user
        let userItems = items.filter { $0.uid == currentUserId }
        
        ScrollView(.horizontal, showsIndicators: false) { // Horizontal scroll view
            HStack(spacing: 16) { // Items in HStack with spacing
                ForEach(userItems) { item in
                    NavigationLink(destination: EditItemView(item: item)) {
                        VStack { // VStack to stack the image and name vertically
                            // Display the first image from the imageUrls array if available
                            if let firstImageUrl = item.imageUrls.first, let url = URL(string: firstImageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        // Placeholder while loading
                                        ProgressView()
                                            .frame(width: 80, height: 80)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80) // Larger image size
                                            /*.clipShape(Circle())*/ // Circular image shape
                                            .clipped()
                                    case .failure:
                                        // Placeholder image if loading fails
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(.gray)
                                            .clipShape(Circle())
                                    @unknown default:
                                        // Fallback for unknown cases
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(.gray)
                                            .clipShape(Circle())
                                    }
                                }
                            } else {
                                // Placeholder image if item image is not available
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                            }

                            // Display item name
                            Text(item.name)
                                .font(.headline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: 80) // Limit the width of the name for consistent layout
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

//struct AccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountView()
//            .environmentObject(AuthManager())
//            .environmentObject(ItemManager())
//    }
//}
