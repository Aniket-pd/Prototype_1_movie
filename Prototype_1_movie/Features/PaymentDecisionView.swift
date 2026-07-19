import SwiftUI

struct PaymentDecisionView: View {
    let store: SyncTableStore

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SyncFlowLayout.sectionSpacing) {
                    PaymentFlowHeader()
                    PaymentTotalsCard(store: store)

                    Text("CHOOSE AN ARRANGEMENT")
                        .font(.system(size: 11.5, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(SyncFlowPalette.rose)

                    VStack(spacing: 12) {
                        ForEach(PaymentArrangement.allCases) { arrangement in
                            Button {
                                store.selectPayment(
                                    arrangement,
                                    payerID: arrangement == .onePays ? store.localParticipant.id : nil
                                )
                            } label: {
                                PaymentChoiceRow(
                                    arrangement: arrangement,
                                    selected: store.table.paymentDecision.arrangement == arrangement
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if store.table.paymentDecision.arrangement == .onePays {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Who is paying?")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(SyncFlowPalette.ink)
                            payerButton(store.table.host)
                            payerButton(store.table.partner)
                        }
                        .syncFlowCard(cornerRadius: 24, padding: 18)
                    }

                    if store.table.paymentDecision.arrangement != nil {
                        PaymentConfirmationsCard(store: store)
                    }
                }
                .padding(.horizontal, SyncFlowLayout.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: primaryAction) {
                Label(primaryActionTitle, systemImage: primaryActionSymbol)
            }
            .buttonStyle(SyncFlowPrimaryButtonStyle())
            .disabled(!isPrimaryActionEnabled)
            .padding(.horizontal, SyncFlowLayout.screenPadding)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .syncMotion(value: store.table.paymentDecision.arrangement)
        .syncMotion(value: store.table.paymentDecision.payerID)
        .syncMotion(value: store.table.paymentDecision.confirmedBy)
    }

    private var isPaymentSelectionComplete: Bool {
        store.table.paymentDecision.arrangement != nil
            && (store.table.paymentDecision.arrangement != .onePays
                || store.table.paymentDecision.payerID != nil)
    }

    private var isPrimaryActionEnabled: Bool {
        store.bothPaymentConfirmed
            || (isPaymentSelectionComplete
                && !store.table.paymentDecision.isConfirmed(by: store.localParticipant))
    }

    private var primaryActionTitle: String {
        if store.bothPaymentConfirmed { return "Continue to checkout" }
        if store.table.paymentDecision.isConfirmed(by: store.localParticipant) { return "Waiting for confirmation" }
        return "Confirm payment decision"
    }

    private var primaryActionSymbol: String {
        store.bothPaymentConfirmed ? "creditcard.fill" : "checkmark.shield.fill"
    }

    private func primaryAction() {
        if store.bothPaymentConfirmed {
            store.go(.checkout)
        } else {
            store.confirmPaymentDecision()
        }
    }

    private func payerButton(_ participant: Participant) -> some View {
        Button {
            store.selectPayment(.onePays, payerID: participant.id)
        } label: {
            PaymentPayerChoiceRow(
                participant: participant,
                detail: "Pays \(store.combinedFinalAmount.rupees)",
                isSelected: store.table.paymentDecision.payerID == participant.id
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(participant.name) pays for everything")
    }
}

private struct PaymentPayerChoiceRow: View {
    let participant: Participant
    let detail: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            PaymentAvatar(participant: participant)
            VStack(alignment: .leading, spacing: 3) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(SyncFlowPalette.muted)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(isSelected ? SyncFlowPalette.success : SyncFlowPalette.muted)
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(
            isSelected ? SyncFlowPalette.success.opacity(0.08) : SyncFlowPalette.blush.opacity(0.5),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PaymentFlowHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHARED PAYMENT DECISION")
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(SyncFlowPalette.rose)

            Text("How should we pay?")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(SyncFlowPalette.ink)

            Text("The arrangement becomes final only after both people confirm.")
                .font(.system(size: 14))
                .foregroundStyle(SyncFlowPalette.muted)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PaymentTotalsCard: View {
    let store: SyncTableStore

    var body: some View {
        VStack(spacing: 18) {
            participantTotal(
                store.table.host,
                subtotal: store.table.hostCart.total,
                delivery: store.hostDeliveryCharge,
                tax: store.hostTax,
                final: store.hostFinalAmount
            )
            Divider().overlay(SyncFlowPalette.rose.opacity(0.1))
            participantTotal(
                store.table.partner,
                subtotal: store.table.partnerCart.total,
                delivery: store.partnerDeliveryCharge,
                tax: store.partnerTax,
                final: store.partnerFinalAmount
            )
            Divider().overlay(SyncFlowPalette.rose.opacity(0.1))
            HStack {
                Text("Combined total")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                Spacer()
                Text(store.combinedFinalAmount.rupees)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.rose)
            }
        }
        .syncFlowCard(cornerRadius: 26, padding: 18)
    }

    private func participantTotal(
        _ participant: Participant,
        subtotal: Int,
        delivery: Int,
        tax: Int,
        final: Int
    ) -> some View {
        VStack(spacing: 9) {
            HStack(spacing: 12) {
                PaymentAvatar(participant: participant)
                Text(participant.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                Spacer()
                Text(final.rupees)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
            }
            totalRow("Food subtotal", value: subtotal.rupees)
            totalRow("Delivery", value: delivery.rupees)
            totalRow("Taxes", value: tax.rupees)
        }
    }

    private func totalRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .font(.system(size: 14))
        .foregroundStyle(SyncFlowPalette.muted)
    }
}

private struct PaymentChoiceRow: View {
    let arrangement: PaymentArrangement
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: paymentSymbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(selected ? .white : SyncFlowPalette.rose)
                .frame(width: 48, height: 48)
                .background(selected ? SyncFlowPalette.rose : SyncFlowPalette.rose.opacity(0.1), in: Circle())
                .accessibilityHidden(true)
            Text(arrangement.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SyncFlowPalette.ink)
                .lineLimit(2)
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selected ? SyncFlowPalette.success : SyncFlowPalette.muted)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .syncFlowCard(cornerRadius: 22, padding: 15)
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(selected ? SyncFlowPalette.rose.opacity(0.58) : .clear, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var paymentSymbol: String {
        switch arrangement {
        case .ownOrder: "person.2.fill"
        case .onePays: "person.crop.circle.badge.checkmark"
        }
    }
}

private struct PaymentAvatar: View {
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

private struct PaymentConfirmationsCard: View {
    let store: SyncTableStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confirmations")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(SyncFlowPalette.ink)
            PaymentConfirmationRow(
                participant: store.table.host,
                isConfirmed: store.table.paymentDecision.isConfirmed(by: store.table.host)
            )
            PaymentConfirmationRow(
                participant: store.table.partner,
                isConfirmed: store.table.paymentDecision.isConfirmed(by: store.table.partner)
            )
            if let arrangement = store.table.paymentDecision.arrangement {
                Label(arrangement.title, systemImage: "creditcard.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SyncFlowPalette.rose)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .syncFlowCard(cornerRadius: 24, padding: 18)
    }
}

private struct PaymentConfirmationRow: View {
    let participant: Participant
    let isConfirmed: Bool

    var body: some View {
        HStack(spacing: 11) {
            PaymentAvatar(participant: participant)
                .scaleEffect(0.75, anchor: .leading)
                .frame(width: 38, height: 38, alignment: .leading)
            Text(participant.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SyncFlowPalette.ink)
            Spacer()
            Label(
                isConfirmed ? "Confirmed" : "Waiting",
                systemImage: isConfirmed ? "checkmark.circle.fill" : "clock"
            )
            .font(.system(size: 12.5, weight: .bold))
            .foregroundStyle(isConfirmed ? SyncFlowPalette.success : SyncFlowPalette.muted)
        }
        .accessibilityElement(children: .combine)
    }
}
