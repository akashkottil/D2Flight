import SwiftUI

// MARK: - Shimmer Effect Modifier
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 300
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - ShimmerLocationTimeColumn Component
struct ShimmerLocationTimeColumn: View {
    var body: some View {
        VStack(alignment: .leading) {
            // Placeholder for time (14pt font)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 35, height: 14)
                .shimmer()
            
            // Placeholder for code (12pt font)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 25, height: 12)
                .shimmer()
        }
    }
}

// MARK: - ShimmerRouteRow Component
struct ShimmerRouteRow: View {
    var body: some View {
        HStack(spacing: 20) {
            // Left location time column
            ShimmerLocationTimeColumn()
            
            // Center duration and stop info
            VStack {
                // Placeholder for "2h 15m" (11pt font)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 11)
                    .shimmer()
                
                // Placeholder for divider line
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 1)
                    .shimmer()
                
                // Placeholder for "1 Stop" (11pt font)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 35, height: 11)
                    .shimmer()
            }
            
            // Right location time column
            ShimmerLocationTimeColumn()
        }
    }
}

// MARK: - ShimmerResultCard Component
struct ShimmerResultCard: View {
    var isRoundTrip: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(spacing: 20) {
                    // First route row
                    ShimmerRouteRow()

                    // Second route row (only if round trip)
                    if isRoundTrip {
                        ShimmerRouteRow()
                    }
                }
                
                Spacer()
                
                // Price section
                VStack(alignment: .trailing) {
                    // Placeholder for "$234" (16pt font)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 16)
                        .shimmer()
                    
                    // Placeholder for "per Adult" (12pt font)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 12)
                        .shimmer()
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Airline info section
            HStack {
                // Placeholder for airline image (21x21 circle)
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 21, height: 21)
                    .shimmer()
                
                // Placeholder for "Indigo Airways" (12pt font)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
                    .shimmer()
                
                Spacer()
            }
            .padding(.leading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        ShimmerResultCard(isRoundTrip: true)
        ShimmerResultCard(isRoundTrip: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
