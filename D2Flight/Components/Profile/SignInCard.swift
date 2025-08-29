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
                ProfileImageView(imageURL: user.profileImageURL)
                
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
                // Fallback to default profile image
                Image("ProfileImg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
                    .offset(x: isAnimating ? 100 : -100)
                    .animation(
                        Animation.linear(duration: 1.2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

// MARK: - Alternative Shimmer Effect (iOS 17+)
@available(iOS 17.0, *)
struct ModernShimmerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .phaseAnimator([false, true]) { content, phase in
                        content
                            .scaleEffect(x: 0.3)
                            .offset(x: phase ? 100 : -100)
                    } animation: { _ in
                        .linear(duration: 1.2).repeatForever(autoreverses: false)
                    }
            )
    }
}


