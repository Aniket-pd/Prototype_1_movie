import SwiftUI
import Combine

struct TrackingView: View {
    let store: SyncTableStore
    @State private var riderProgress: CGFloat = 0.08

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SyncFlowLayout.sectionSpacing) {
                    TrackingFlowHeader(
                        tableID: store.table.id,
                        title: store.sharedMilestone.title,
                        status: honestStatus
                    )

                    TrackingArrivalCard(predictedDifference: store.predictedDifference)

                    if store.table.orders.count == 2 {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ORDER STATUS")
                                .font(.system(size: 11.5, weight: .bold))
                                .tracking(1.1)
                                .foregroundStyle(SyncFlowPalette.rose)
                            orderCard(order: store.table.orders[0], participant: store.table.host)
                            Divider().overlay(SyncFlowPalette.rose.opacity(0.1))
                            orderCard(order: store.table.orders[1], participant: store.table.partner)
                        }
                        .syncFlowCard(cornerRadius: 26, padding: 18)
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Label("Live delivery", systemImage: "location.fill")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(SyncFlowPalette.ink)
                            Spacer()
                            Text("Simulated live location")
                                .font(.system(size: 12.5))
                                .foregroundStyle(SyncFlowPalette.muted)
                        }
                        .padding(16)

                        DeliveryTrackingMap(
                            customerName: store.localParticipant.name,
                            riderProgress: riderProgress
                        )
                            .frame(height: 220)
                            .clipShape(.rect(cornerRadius: 18))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                    .syncFlowCard(cornerRadius: 26, padding: 0)

                    #if DEBUG
                    Button("Demo: Advance delivery") { store.advanceSimulation() }
                        .buttonStyle(.bordered)
                        .tint(SyncFlowPalette.rose)
                    #endif
                }
                .padding(.horizontal, SyncFlowLayout.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)

        }

        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.table.orders.count == 2,
               store.table.orders.allSatisfy({ $0.status == .delivered }) {
                Button("Continue to first bite", systemImage: "fork.knife") {
                    store.go(.firstBite)
                }
                .buttonStyle(SyncFlowPrimaryButtonStyle())
                .padding(.horizontal, SyncFlowLayout.screenPadding)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .syncMotion(value: store.table.orders)
        .syncMotion(value: store.sharedMilestone)
        .onReceive(Timer.publish(every: 1.35, on: .main, in: .common).autoconnect()) { _ in
            // The demo receives a fresh coordinate at a regular interval, then
            // interpolates to it so the rider never jumps between updates.
            let nextProgress = riderProgress > 0.91 ? 0.08 : riderProgress + 0.075
            withAnimation(.smooth(duration: 1.22)) {
                riderProgress = nextProgress
            }
        }
    }

    private var honestStatus: String {
        guard store.table.orders.count == 2 else { return "The orders are being linked." }
        let local = store.table.orders.first(where: { $0.ownerID == store.localParticipant.id })?.status ?? .authorized
        let remote = store.table.orders.first(where: { $0.ownerID == store.remoteParticipant.id })?.status ?? .authorized
        if local > remote {
            return "Your order is \(local.title.lowercased()). Waiting for \(store.remoteParticipant.name)’s restaurant."
        }
        if remote > local {
            return "\(store.remoteParticipant.name)’s order is \(remote.title.lowercased()). Your restaurant is catching up."
        }
        return "Both individual orders have reached this shared milestone."
    }

    private func orderCard(order: LinkedOrder, participant: Participant) -> some View {
        HStack(spacing: 14) {
            TrackingAvatar(participant: participant)
            VStack(alignment: .leading, spacing: 5) {
                Text(order.restaurantName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                Text(order.estimate.window)
                    .font(.system(size: 13))
                    .foregroundStyle(SyncFlowPalette.muted)
                Label(order.status.title, systemImage: order.status.symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SyncFlowPalette.rose)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(order.total.rupees)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                ProgressView(value: Double(order.status.rawValue), total: 6)
                    .frame(width: 68)
                    .tint(SyncFlowPalette.rose)
            }
        }
        .accessibilityElement(children: .combine)
    }

}

private struct DeliveryTrackingMap: View {
    let customerName: String
    let riderProgress: CGFloat

    private var coordinateText: String {
        let latitude = 19.0771 + Double(riderProgress) * 0.0028
        let longitude = 72.8774 + Double(riderProgress) * 0.0036
        return String(format: "%.4f, %.4f", latitude, longitude)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let riderPoint = routePoint(progress: riderProgress, in: size)

            ZStack(alignment: .topLeading) {
                DummyMapGrid()

                DeliveryRoute()
                    .stroke(SyncFlowPalette.rose.opacity(0.18), style: .init(lineWidth: 10, lineCap: .round))
                DeliveryRoute()
                    .stroke(SyncFlowPalette.rose, style: .init(lineWidth: 3, lineCap: .round, dash: [7, 6]))

                mapPin(icon: "fork.knife", title: "Pickup")
                    .position(x: size.width * 0.16, y: size.height * 0.76)

                mapPin(icon: "house.fill", title: customerName)
                    .position(x: size.width * 0.84, y: size.height * 0.22)

                Circle()
                    .fill(SyncFlowPalette.rose.opacity(0.16))
                    .frame(width: 50, height: 50)
                    .position(riderPoint)
                    .scaleEffect(1.12)
                Text("🏍️")
                    .font(.system(size: 31))
                    .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
                    .position(riderPoint)
                    .accessibilityLabel("Delivery partner is moving")

                HStack(spacing: 6) {
                    Circle().fill(SyncFlowPalette.success).frame(width: 7, height: 7)
                    Text("LIVE  •  \(coordinateText)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(SyncFlowPalette.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: Capsule())
                .padding(10)
            }
        }
        .background(Color(red: 0.95, green: 0.91, blue: 0.82))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Simulated delivery map. (customerName)'s address and the delivery partner are shown together. The delivery partner location updates live.")
    }

    private func mapPin(icon: String, title: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(SyncFlowPalette.rose, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 3))
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.white.opacity(0.9), in: Capsule())
        }
    }

    private func routePoint(progress: CGFloat, in size: CGSize) -> CGPoint {
        let start = CGPoint(x: size.width * 0.16, y: size.height * 0.76)
        let end = CGPoint(x: size.width * 0.84, y: size.height * 0.22)
        let control1 = CGPoint(x: size.width * 0.36, y: size.height * 0.98)
        let control2 = CGPoint(x: size.width * 0.61, y: size.height * 0.02)
        let t = progress
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * inverse * start.x + 3 * inverse * inverse * t * control1.x + 3 * inverse * t * t * control2.x + t * t * t * end.x,
            y: inverse * inverse * inverse * start.y + 3 * inverse * inverse * t * control1.y + 3 * inverse * t * t * control2.y + t * t * t * end.y
        )
    }
}

private struct DeliveryRoute: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.width * 0.16, y: rect.height * 0.76))
            path.addCurve(
                to: CGPoint(x: rect.width * 0.84, y: rect.height * 0.22),
                control1: CGPoint(x: rect.width * 0.36, y: rect.height * 0.98),
                control2: CGPoint(x: rect.width * 0.61, y: rect.height * 0.02)
            )
        }
    }
}

private struct DummyMapGrid: View {
    var body: some View {
        Canvas { context, size in
            let roads: [(CGPoint, CGPoint)] = [
                (.init(x: 0, y: size.height * 0.24), .init(x: size.width, y: size.height * 0.42)),
                (.init(x: 0, y: size.height * 0.75), .init(x: size.width, y: size.height * 0.58)),
                (.init(x: size.width * 0.22, y: 0), .init(x: size.width * 0.37, y: size.height)),
                (.init(x: size.width * 0.68, y: 0), .init(x: size.width * 0.56, y: size.height))
            ]
            for (start, end) in roads {
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(.white.opacity(0.78)), lineWidth: 13)
                context.stroke(path, with: .color(Color(red: 0.79, green: 0.75, blue: 0.65)), style: .init(lineWidth: 1, dash: [5, 5]))
            }
        }
    }
}

private struct TrackingFlowHeader: View {
    let tableID: String
    let title: String
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LIVE SYNC  •  \(tableID)")
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(SyncFlowPalette.rose)
            Text(title)
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(SyncFlowPalette.ink)
            Text(status)
                .font(.system(size: 14))
                .foregroundStyle(SyncFlowPalette.muted)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TrackingArrivalCard: View {
    let predictedDifference: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHARED ARRIVAL WINDOW")
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(SyncFlowPalette.rose)
            HStack(alignment: .firstTextBaseline) {
                Text("8:06–8:12 PM")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                Spacer()
                Text("Δ \(predictedDifference) min")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.success)
            }
            Text("Expected within \(predictedDifference) minutes of each other")
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(SyncFlowPalette.success)
        }
        .syncFlowCard(cornerRadius: 26, padding: 18)
        .accessibilityElement(children: .combine)
    }
}

private struct TrackingAvatar: View {
    let participant: Participant

    var body: some View {
        Text(participant.initials)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(
                    colors: participant.isHost
                        ? [SyncFlowPalette.coral, SyncFlowPalette.rose]
                        : [Color.orange.opacity(0.75), Color(red: 1, green: 0.66, blue: 0.48)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Circle()
            )
            .accessibilityHidden(true)
    }
}

struct SharedTimeline: View {
    let current: SharedMilestone

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shared milestones").font(.headline)
            ForEach(SharedMilestone.allCases, id: \.self) { milestone in
                HStack(spacing: 12) {
                    Image(systemName: milestone.rawValue <= current.rawValue ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(milestone.rawValue <= current.rawValue ? Brand.green : .secondary)
                    Text(milestone.title)
                        .font(.subheadline)
                        .foregroundStyle(milestone.rawValue <= current.rawValue ? .primary : .secondary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}

struct LiveActivityPreview: View {
    let store: SyncTableStore

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "fork.knife.circle.fill").foregroundStyle(Brand.red)
                Text("Sync Table").font(.headline)
                Spacer()
                Text(store.table.id).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                activityPerson(store.table.host, order: store.table.orders.first)
                Image(systemName: "link").foregroundStyle(Brand.red)
                activityPerson(store.table.partner, order: store.table.orders.dropFirst().first)
            }
            Text("Expected within \(store.predictedDifference) min of each other")
                .font(.caption.bold()).foregroundStyle(Brand.green)
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activityPerson(_ person: Participant, order: LinkedOrder?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.name).font(.caption.bold())
            Text(order?.status.title ?? "Linked").font(.caption).foregroundStyle(.white.opacity(0.7))
            ProgressView(value: Double(order?.status.rawValue ?? 0), total: 6).tint(person.isHost ? Brand.red : .orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FirstBiteView: View {
    let store: SyncTableStore

    var body: some View {
        ZStack {
            SyncFlowBackground()

            VStack(spacing: 22) {
                Spacer(minLength: 24)
                FirstBiteMoment(countdown: store.countdown)

                VStack(spacing: 8) {
                    Text("BOTH ORDERS ARRIVED")
                        .font(.system(size: 11.5, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(SyncFlowPalette.rose)
                    Text(store.countdown == 0 ? "Your table is ready" : "Ready for the first bite?")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(SyncFlowPalette.ink)
                    Text(firstBiteDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(SyncFlowPalette.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 0) {
                    readyPerson(store.table.host, ready: store.hostReadyToEat)
                    Divider()
                        .frame(height: 58)
                        .overlay(SyncFlowPalette.rose.opacity(0.1))
                    readyPerson(store.table.partner, ready: store.partnerReadyToEat)
                }
                .syncFlowCard(cornerRadius: 24, padding: 14)
                Spacer()
            }
            .padding(.horizontal, SyncFlowLayout.screenPadding)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: firstBiteAction) {
                Label(firstBiteButtonTitle, systemImage: "fork.knife")
            }
            .buttonStyle(SyncFlowPrimaryButtonStyle())
            .disabled(store.localReadyToEat && store.countdown != 0)
            .padding(.horizontal, SyncFlowLayout.screenPadding)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .heavy), trigger: store.countdown)
        .syncMotion(value: store.countdown)
        .syncMotion(value: store.hostReadyToEat)
        .syncMotion(value: store.partnerReadyToEat)
    }

    private var firstBiteDescription: String {
        if store.countdown == 0 { return "Take the first bite together." }
        if store.localReadyToEat { return "You’re ready. Waiting for your tablemate." }
        return "Confirm when you’re settled and we’ll start together."
    }

    private var firstBiteButtonTitle: String {
        if store.countdown == 0 { return "Join the table" }
        if store.localReadyToEat { return "Waiting for your tablemate…" }
        return "I’m Ready to Eat"
    }

    private func firstBiteAction() {
        if store.countdown == 0 {
            store.enterDining()
        } else {
            store.beginFirstBite()
        }
    }

    private func readyPerson(_ participant: Participant, ready: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                ArrivalAvatar(participant: participant, size: 56)
                Image(systemName: ready ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(ready ? SyncFlowPalette.success : SyncFlowPalette.muted)
                    .background(.background, in: Circle())
            }
            Text(participant.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(SyncFlowPalette.ink)
            Text(ready ? "Ready" : "Getting settled")
                .font(.system(size: 12.5))
                .foregroundStyle(SyncFlowPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct FirstBiteMoment: View {
    let countdown: Int?

    var body: some View {
        ZStack {
            Circle()
                .fill(SyncFlowPalette.rose.opacity(0.1))
                .frame(width: 130, height: 130)
            if let countdown, countdown > 0 {
                Text("\(countdown)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.rose)
                    .contentTransition(.numericText())
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(SyncFlowPalette.rose)
            }
        }
        .accessibilityLabel(countdown == 0 ? "Your table is ready" : "Ready for the first bite")
    }
}

struct DiningView: View {
    let store: SyncTableStore
    @State private var selectedReaction = ""

    var body: some View {
        ZStack {
            SyncFlowBackground()

            VStack(spacing: 20) {
                Spacer(minLength: 24)
                HStack(spacing: 16) {
                    ArrivalAvatar(participant: store.table.host, size: 62)
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(SyncFlowPalette.rose)
                    ArrivalAvatar(participant: store.table.partner, size: 62)
                }

                VStack(spacing: 6) {
                    Text("Dinner, together.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(SyncFlowPalette.ink)
                    Text(store.table.selectedPair?.theme ?? "Your Sync Table")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SyncFlowPalette.rose)
                    Text("Mumbai ↔ Bengaluru")
                        .font(.system(size: 13.5))
                        .foregroundStyle(SyncFlowPalette.muted)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("A SMALL QUESTION")
                        .font(.system(size: 11.5, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(SyncFlowPalette.rose)
                    Text("What’s the best bite on your plate?")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(SyncFlowPalette.ink)
                    HStack(spacing: 10) {
                        ForEach(["😍", "🤌", "🌶️", "😂"], id: \.self) { emoji in
                            Button(emoji) {
                                selectedReaction = emoji
                                store.sendReaction(emoji)
                            }
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(
                                selectedReaction == emoji ? SyncFlowPalette.rose.opacity(0.15) : SyncFlowPalette.blush.opacity(0.55),
                                in: Circle()
                            )
                            .accessibilityLabel("Send \(emoji) reaction")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .syncFlowCard(cornerRadius: 24, padding: 18)
                Spacer()
            }
            .padding(.horizontal, SyncFlowLayout.screenPadding)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(store.table.memory == nil ? "Save this table as a memory" : "View table memory") {
                if store.table.memory == nil { store.finishMeal() }
                else { store.openMemory() }
            }
            .buttonStyle(SyncFlowPrimaryButtonStyle())
            .padding(.horizontal, SyncFlowLayout.screenPadding)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: selectedReaction)
        .syncMotion(SyncMotion.controlChange, value: selectedReaction)
    }
}

struct MemoryView: View {
    let store: SyncTableStore

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SyncFlowLayout.sectionSpacing) {
                    MemoryFlowHeader()
                if let memory = store.table.memory {
                    VStack(alignment: .leading, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(SyncFlowPalette.rose.opacity(0.14))
                                .frame(height: 156)
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(SyncFlowPalette.rose)
                                HStack {
                                    ArrivalAvatar(participant: store.table.host, size: 44)
                                    Image(systemName: "heart.fill").foregroundStyle(SyncFlowPalette.rose)
                                    ArrivalAvatar(participant: store.table.partner, size: 44)
                                }
                            }
                        }
                        Text(memory.title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(SyncFlowPalette.ink)
                        Label("\(memory.date.formatted(date: .long, time: .omitted))  •  \(memory.cities)", systemImage: "calendar")
                            .font(.system(size: 13.5))
                            .foregroundStyle(SyncFlowPalette.muted)
                        Label(memory.dishes, systemImage: "fork.knife")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SyncFlowPalette.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        DisclosureGroup("Order details") {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(memory.restaurantInformation, systemImage: "building.2.fill")
                                Label(memory.paymentSummary, systemImage: "creditcard.fill")
                            }
                            .font(.system(size: 13.5))
                            .foregroundStyle(SyncFlowPalette.muted)
                            .padding(.top, 8)
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SyncFlowPalette.rose)
                    }
                    .syncFlowCard(cornerRadius: 26, padding: 18)
                } else {
                    MemoryUnavailableState(connectionState: store.connectionState)
                }
                Button("Back to Zomato home") { store.leaveTable() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SyncFlowPalette.muted)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, SyncFlowLayout.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Recreate this table", systemImage: "arrow.clockwise") {
                store.recreateTable()
            }
            .buttonStyle(SyncFlowPrimaryButtonStyle())
            .padding(.horizontal, SyncFlowLayout.screenPadding)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct MemoryFlowHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SYNC TABLE MEMORY")
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(SyncFlowPalette.rose)
            Text("A table worth keeping")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(SyncFlowPalette.ink)
            Text("A small shared memory from dinner together.")
                .font(.system(size: 14))
                .foregroundStyle(SyncFlowPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ArrivalAvatar: View {
    let participant: Participant
    var size: CGFloat = 48

    var body: some View {
        Text(participant.initials)
            .font(.system(size: size * 0.31, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: participant.isHost
                        ? [SyncFlowPalette.coral, SyncFlowPalette.rose]
                        : [Color.orange.opacity(0.75), Color(red: 1, green: 0.66, blue: 0.48)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Circle()
            )
            .accessibilityHidden(true)
    }
}

private struct MemoryUnavailableState: View {
    let connectionState: BackendConnectionState

    var body: some View {
        switch connectionState {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading your shared memory…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .softCard()
        case .disconnected, .error:
            ContentUnavailableView(
                "Memory unavailable offline",
                systemImage: "wifi.slash",
                description: Text("Reconnect to restore the latest shared table memory.")
            )
            .softCard()
        case .local, .synced:
            ContentUnavailableView(
                "Memory not saved yet",
                systemImage: "fork.knife.circle",
                description: Text("Finish the shared meal to create this memory.")
            )
            .softCard()
        }
    }
}
