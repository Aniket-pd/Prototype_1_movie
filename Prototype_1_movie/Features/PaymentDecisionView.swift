import SwiftUI

struct PaymentDecisionView: View {
    let store: SyncTableStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SectionHeader(
                    eyebrow: "Shared payment decision",
                    title: "How should we pay?",
                    subtitle: "The arrangement becomes final only after both people confirm."
                )

                PaymentTotalsCard(store: store)

                VStack(spacing: 10) {
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who is volunteering?").font(.headline)
                        payerButton(store.table.host)
                        payerButton(store.table.partner)
                    }
                    .softCard()
                }

                PaymentConfirmationsCard(store: store)

                Button {
                    store.confirmPaymentDecision()
                } label: {
                    Label(
                        store.table.paymentDecision.isConfirmed(by: store.localParticipant)
                            ? "Your decision is confirmed"
                            : "Confirm payment decision",
                        systemImage: "checkmark.shield.fill"
                    )
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(
                    store.table.paymentDecision.arrangement == nil
                        || (store.table.paymentDecision.arrangement == .onePays
                            && store.table.paymentDecision.payerID == nil)
                        || store.table.paymentDecision.isConfirmed(by: store.localParticipant)
                )

                Button("Continue to checkout", systemImage: "creditcard.fill") {
                    store.go(.checkout)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.green)
                .controlSize(.large)
                .disabled(!store.bothPaymentConfirmed)
            }
            .padding(20)
        }
    }

    private func payerButton(_ participant: Participant) -> some View {
        Button {
            store.selectPayment(.onePays, payerID: participant.id)
        } label: {
            ParticipantChoiceRow(
                participant: participant,
                detail: "Pays \(store.combinedFinalAmount.rupees)",
                isSelected: store.table.paymentDecision.payerID == participant.id
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(participant.name) pays for everything")
    }
}

private struct PaymentTotalsCard: View {
    let store: SyncTableStore

    var body: some View {
        VStack(spacing: 14) {
            participantTotal(
                store.table.host,
                subtotal: store.table.hostCart.total,
                delivery: store.hostDeliveryCharge,
                tax: store.hostTax,
                final: store.hostFinalAmount
            )
            Divider()
            participantTotal(
                store.table.partner,
                subtotal: store.table.partnerCart.total,
                delivery: store.partnerDeliveryCharge,
                tax: store.partnerTax,
                final: store.partnerFinalAmount
            )
            Divider()
            LabeledContent("Combined total") {
                Text(store.combinedFinalAmount.rupees).font(.title3.bold())
            }
        }
        .softCard()
    }

    private func participantTotal(
        _ participant: Participant,
        subtotal: Int,
        delivery: Int,
        tax: Int,
        final: Int
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                AvatarView(participant: participant)
                Text(participant.name).font(.headline)
                Spacer()
                Text(final.rupees).font(.headline)
            }
            LabeledContent("Food subtotal", value: subtotal.rupees)
            LabeledContent("Delivery", value: delivery.rupees)
            LabeledContent("Taxes", value: tax.rupees)
        }
        .font(.subheadline)
    }
}

private struct PaymentChoiceRow: View {
    let arrangement: PaymentArrangement
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: paymentSymbol)
                .font(.title3)
                .foregroundStyle(selected ? .white : Brand.red)
                .frame(width: 44, height: 44)
                .background(selected ? Brand.red : Brand.red.opacity(0.09), in: Circle())
                .accessibilityHidden(true)
            Text(arrangement.title).font(.headline)
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Brand.green : .secondary)
                .accessibilityHidden(true)
        }
        .softCard()
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(selected ? Brand.red : .clear, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var paymentSymbol: String {
        switch arrangement {
        case .splitEqually: "equal.circle.fill"
        case .ownOrder: "person.2.fill"
        case .onePays: "person.crop.circle.badge.checkmark"
        }
    }
}

private struct PaymentConfirmationsCard: View {
    let store: SyncTableStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confirmations").font(.headline)
            ParticipantConfirmationRow(
                participant: store.table.host,
                isConfirmed: store.table.paymentDecision.isConfirmed(by: store.table.host)
            )
            ParticipantConfirmationRow(
                participant: store.table.partner,
                isConfirmed: store.table.paymentDecision.isConfirmed(by: store.table.partner)
            )
            if let arrangement = store.table.paymentDecision.arrangement {
                Label(arrangement.title, systemImage: "creditcard.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Brand.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}
