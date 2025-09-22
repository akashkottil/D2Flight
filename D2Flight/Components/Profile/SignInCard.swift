import SwiftUI

struct SignInCard: View {
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showLoginView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile/Welcome Section
            profileSection
                .padding()
                .foregroundColor(.white)
            
            // Action Button Section
            actionButtonSection
                .foregroundColor(.white)
        }
        .background(GradientColor.Primary)
        .cornerRadius(16)
        .padding()
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(isLoggedIn: $isLoggedIn)
                .environmentObject(authManager)
        }
        .onReceive(authManager.$isAuthenticated) { authenticated in
            isLoggedIn = authenticated
        }
    }
    
    // MARK: - Profile Section
    @ViewBuilder
    private var profileSection: some View {
        HStack(spacing: 12) {
            if authManager.isAuthenticated, let user = authManager.currentUser {
                // User Profile
                ProfileImageView(imageURL: user.profileImageURL, userName: user.name)
                
                userInfoView(user: user)
            } else {
                // Welcome Message
                welcomeMessageView
            }
        }
    }
    
    @ViewBuilder
    private func userInfoView(user: User) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(user.name)
                .font(CustomFont.font(.medium, weight: .bold))
                .lineLimit(1)
            
            Text(user.email)
                .font(CustomFont.font(.small))
                .fontWeight(.medium)
                .foregroundColor(Color.gray)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private var welcomeMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("more.offers.awaits.you".localized)
                .font(CustomFont.font(.medium, weight: .bold))
                .lineLimit(2)
            
            Text("sign.up.and.access.to.our.exclusive.deals".localized)
                .font(CustomFont.font(.small))
                .fontWeight(.medium)
                .foregroundColor(Color.gray)
                .lineLimit(3)
        }
    }
    
    // MARK: - Action Button Section
    @ViewBuilder
    private var actionButtonSection: some View {
        VStack(spacing: 0) {
            if authManager.isAuthenticated {
                accountSettingsButton
            } else {
                signInButton
            }
        }
    }
    
    @ViewBuilder
    private var accountSettingsButton: some View {
        NavigationLink(destination: AccountSettings()) {
            HStack {
                Text("account.settings".localized)
                    .font(CustomFont.font(.medium, weight: .medium))
                Spacer()
                Image("RedArrow")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.0))
            .foregroundColor(.white)
        }
    }

    
    @ViewBuilder
    private var signInButton: some View {
        Button(action: {
            showLoginView = true
        }) {
            HStack {
                Text("sign.in.now".localized)
                    .font(CustomFont.font(.medium, weight: .medium))
                Spacer()
                Image("WhiteArrow")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("Violet"))
            .foregroundColor(.white)
        }
        .cornerRadius(12)
    }
}

// MARK: - Profile Image View with Shimmer
struct ProfileImageView: View {
    let imageURL: String?
    let userName: String?
    @State private var isLoading = true
    
    private let imageSize: CGFloat = 56
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        isLoading = false
                    }
                    
            case .failure(_):
                // Fallback to user initials instead of default profile image
                UserInitialsView(userName: userName, size: imageSize)
                    .onAppear {
                        isLoading = false
                    }
                    
            case .empty:
                // Show shimmer while loading
                ShimmerView()
                    .onAppear {
                        isLoading = true
                    }
                    
            @unknown default:
                ShimmerView()
            }
        }
        .frame(width: imageSize, height: imageSize)
        .clipShape(Circle())
    }
}

// MARK: - User Initials View
struct UserInitialsView: View {
    let userName: String?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("Violet"), Color("Violet").opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // User initials text
            Text(getUserInitials())
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
    
    private func getUserInitials() -> String {
        guard let userName = userName, !userName.isEmpty else {
            return "U" // Default fallback if no name
        }
        
        let nameComponents = userName.components(separatedBy: " ")
            .filter { !$0.isEmpty }
        
        if nameComponents.count >= 2 {
            // Get first letter of first name and first letter of last name
            let firstName = nameComponents.first?.prefix(1).uppercased() ?? ""
            let lastName = nameComponents.last?.prefix(1).uppercased() ?? ""
            return firstName + lastName
        } else if nameComponents.count == 1 {
            // If only one name component, take first two letters or just first letter
            let singleName = nameComponents.first ?? ""
            return String(singleName.prefix(2)).uppercased()
        }
        
        return "U" // Ultimate fallback
    }
}

// MARK: - Shimmer Effect
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: 0.3, y: 1, anchor: .leading)
                    .offset(x: isAnimating ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
                    .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            )
            .onAppear {
                isAnimating = true
            }
    }
}
