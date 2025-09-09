import SwiftUI
import SafariServices

struct ResultDetails: View {
    let flight: FlightResult
    @Environment(\.dismiss) private var dismiss

    @State private var showAllDeals = false

    // NEW: full-screen flight webview state
    @State private var showFlightSearchWebView = false
    @State private var pendingDeeplink: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image("DefaultLeftArrow")
                        .padding(.trailing, 10)
                        .frame(width: 24, height: 24)
                }

                Spacer()

                Button(action: {
                    // Share functionality
                }) {
                    Image("ShareIcon")
                        .frame(width: 24, height: 24)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)

            ScrollView {
                VStack(spacing: 0) {
                    // Route and Trip Details Section
                    VStack(spacing: 16) {
                        // Route Header
                        HStack {
                            Text(getRouteText())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(getStopsText())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(flight.legs.first?.stopCount == 0 ? Color.green : Color.red)
                                Text(flight.formattedDuration)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                        }

                        // Trip location names
                        HStack {
                            if let firstLeg = flight.legs.first {
                                Text(firstLeg.origin)
                                Text("to".localized)
                                Text(firstLeg.destination)
                            }
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .semibold))

                        // Trip Details
                        HStack {
                            Text(getTripDetailsText())
                                .font(.system(size: 18))
                                .fontWeight(.light)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)

                    // Booking Platforms Section
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("booking.options".localized)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 8)

                        // Display providers based on expanded state
                        let providersToShow = showAllDeals ? flight.providers : Array(flight.providers.prefix(3))

                        ForEach(Array(providersToShow.enumerated()), id: \.offset) { index, provider in
                            if let splitProvider = provider.splitProviders?.first {
                                BookingPlatformRow(
                                    platform: BookingPlatform(
                                        name: splitProvider.name,
                                        price: provider.price,
                                        imageURL: splitProvider.imageURL,
                                        deeplink: splitProvider.deeplink,
                                        rating: splitProvider.rating,
                                        ratingCount: splitProvider.ratingCount
                                    ),
                                    isFirst: index == 0,
                                    isLast: index == providersToShow.count - 1
                                ) { url in
                                    // Open full-screen like hotel flow
                                    pendingDeeplink = url.absoluteString
                                    withTransaction(Transaction(animation: nil)) {
                                        showFlightSearchWebView = true
                                    }
                                    print("🔗 Open full-screen deeplink for \(splitProvider.name): \(url.absoluteString)")
                                }
                            }
                        }

                        // Show "View more deals" or "Show less" button conditionally
                        if flight.providers.count > 3 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAllDeals.toggle()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    if showAllDeals {
                                        Text("show.less".localized)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.red)
                                        Image(systemName: "chevron.up")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    } else {
                                        Text("\(flight.providers.count - 3) more deal from ₹\(Int(getLowestRemainingPrice()))")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.red)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 12)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.white)

                    Divider()

                    // Price note
                    HStack {
                        Spacer()
                        Text("a.1.inr.per.ticket.including.taxes.fees".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(Color.white)

                    Divider()

                    // Flight Details Section
                    VStack(spacing: 16) {
                        ForEach(flight.legs.indices, id: \.self) { index in
                            FlightDetailCard(
                                leg: flight.legs[index],
                                isRoundTrip: flight.legs.count > 1,
                                legIndex: index
                            )
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.gray.opacity(0.05))
        .onAppear {
            print("📋 Displaying flight details for: \(flight.id)")
            printFlightProviders()
        }
        // Full-screen FlightSearchWebView (no bounce animation)
        .fullScreenCover(isPresented: $showFlightSearchWebView, onDismiss: {
            pendingDeeplink = ""
        }) {
            FlightSearchWebView(urlString: pendingDeeplink)
                .ignoresSafeArea()
                .transaction { $0.disablesAnimations = true }   // avoid up/down slide inside
        }
    }

    private func getRouteText() -> String {
        guard let firstLeg = flight.legs.first else { return "Flight Details" }
        return "\(firstLeg.originCode) → \(firstLeg.destinationCode)"
    }

    private func getStopsText() -> String {
        guard let firstLeg = flight.legs.first else { return "Direct" }
        return firstLeg.stopsText.lowercased()
    }

    private func getTripDetailsText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM"

        var details = ""
        if let firstLeg = flight.legs.first {
            let date = Date(timeIntervalSince1970: TimeInterval(firstLeg.departureTimeAirport))
            details = dateFormatter.string(from: date)
        }

        details += " • Economy • 2 Travelers"
        return details
    }

    private func getLowestRemainingPrice() -> Double {
        if flight.providers.count > 3 {
            let remainingProviders = Array(flight.providers.dropFirst(3))
            return remainingProviders.map { $0.price }.min() ?? flight.min_price
        }
        return flight.min_price
    }

    private func printFlightProviders() {
        print("🏪 ===== FLIGHT PROVIDERS DETAILS =====")
        print("Flight ID: \(flight.id)")
        print("Total Providers: \(flight.providers.count)")
        print("Price Range: ₹\(flight.min_price) - ₹\(flight.max_price)")

        for (index, provider) in flight.providers.enumerated() {
            print("\nProvider \(index + 1):")
            print("  Price: ₹\(provider.price)")
            print("  Is Split: \(provider.isSplit)")
            print("  Transfer Type: \(provider.transferType ?? "N/A")")

            if let splitProviders = provider.splitProviders {
                print("  Split Providers Count: \(splitProviders.count)")
                for (spIndex, splitProvider) in splitProviders.enumerated() {
                    print("    Split Provider \(spIndex + 1):")
                    print("      Name: \(splitProvider.name)")
                    print("      Price: ₹\(splitProvider.price)")
                    print("      Image URL: \(splitProvider.imageURL)")
                    print("      Deep Link: \(splitProvider.deeplink)")
                    print("      Rating: \(splitProvider.rating?.description ?? "N/A")")
                    print("      Rating Count: \(splitProvider.ratingCount?.description ?? "N/A")")
                }
            }
        }
        print("🏪 ===== END PROVIDERS DETAILS =====")
    }
}

// MARK: - Booking Platform Row
struct BookingPlatformRow: View {
    let platform: BookingPlatform
    let isFirst: Bool
    let isLast: Bool
    let onTapViewDeal: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !isFirst {
                Divider().padding(.leading)
            }

            HStack {
                // Provider Logo
                AsyncImage(url: URL(string: platform.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(String(platform.name.prefix(2)))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(platform.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.8))

                    if let rating = platform.rating, let ratingCount = platform.ratingCount {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("\(String(format: "%.1f", rating)) (\(ratingCount))")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                Text("₹\(Int(platform.price))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.leading, 4)

                PrimaryButton(
                    title: "view.deal".localized,
                    font: .system(size: 12),
                    fontWeight: .bold,
                    textColor: .white,
                    width: 90,
                    height: 39,
                    verticalPadding: 12,
                    cornerRadius: 6
                ) {
                    if let url = URL(string: platform.deeplink) {
                        onTapViewDeal(url)  // bubble up to parent
                    } else {
                        print("❌ Invalid booking URL for \(platform.name)")
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Models
struct BookingPlatform {
    let name: String
    let price: Double
    let imageURL: String
    let deeplink: String
    let rating: Double?
    let ratingCount: Int?
}

// (Optional) Old Safari sheet kept here if needed elsewhere
struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredBarTintColor = .systemBackground
        vc.preferredControlTintColor = .label
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
