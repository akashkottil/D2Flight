import SwiftUI

struct AboutUs: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }

                    Spacer()

                    Text("about.us".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.trailing, 44)
                }
                .padding()

                Divider()

                // Scrollable content (no image here)
                ScrollView {
                    VStack {
                        Image("AboutLogo")
                            .frame(width: 60, height: 60)

                        Text("Last Minute Flights")
                            .font(CustomFont.font(.large, weight: .bold))

                        Text("version.1.02".localized)
                            .font(.system(size: 15))
                            .fontWeight(.light)
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                    .padding(.top,20)

                    VStack(spacing: 16) {
                        Text("welcome.to.our.flight.price.comparison.app.we.know.that.planning.a.trip.can.be.stressful.especially.when.it.comes.to.finding.the.best.deals.on.flights.thats.where.we.come.in.our.app.makes.it.easy.for.you.to.compare.prices.from.multiple.airlines.so.you.can.find.the.best.option.for.your.budget.and.schedule".localized)
                            .multilineTextAlignment(.center)
                            .font(CustomFont.font(.large))
                            .fontWeight(.light)

                        Text("our.team.is.passionate.about.helping.travelers.save.money.and.have.a.great.trip.we.are.constantly.updating.our.app.with.the.latest.deals.and.features.to.make.your.search.even.easier.with.our.user-friendly.interface.and.reliable.price.comparisons.you.can.book.your.next.flight.with.confidence".localized)
                            .multilineTextAlignment(.center)
                            .font(CustomFont.font(.large))
                            .fontWeight(.light)

                        Text("thank.you.for.choosing.our.app.we.hope.you.have.a.wonderful.journey".localized)
                            .multilineTextAlignment(.center)
                            .font(CustomFont.font(.large))
                            .fontWeight(.light)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 0)
            .padding(.bottom, 0)
            // Pin the image to the bottom, independent of content length
            .safeAreaInset(edge: .bottom) {
                Image("AboutImg")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .background(Color(.systemBackground)) // prevents translucency/overlap artifacts
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

#Preview {
    AboutUs()
}
