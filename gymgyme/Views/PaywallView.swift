import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("pocket pt")
                            .font(.custom("Menlo-Bold", size: 28))
                            .foregroundStyle(DoodleTheme.yellow)
                        Text("your personal trainer, always in your pocket")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    .padding(.top, 8)

                    // features list
                    featureRow(icon: "sparkles", title: "ai program builder", desc: "programs built from your exercises, goals, and schedule", color: DoodleTheme.purple)
                    featureRow(icon: "chart.line.uptrend.xyaxis", title: "progressive overload", desc: "weekly weight and rep suggestions based on your history", color: DoodleTheme.green)
                    featureRow(icon: "exclamationmark.triangle", title: "muscle neglect alerts", desc: "warns you when a muscle group is being ignored", color: DoodleTheme.red)
                    featureRow(icon: "list.clipboard", title: "expert templates", desc: "PPL, Upper/Lower, Full Body — science-backed programs", color: DoodleTheme.blue)
                    featureRow(icon: "arrow.triangle.2.circlepath", title: "deload reminders", desc: "auto-suggests recovery weeks to prevent burnout", color: DoodleTheme.teal)

                    Text("").frame(height: 8)

                    // subscription card
                    if let ptProduct = store.pocketPTProduct {
                        purchaseCard(
                            title: "pocket pt",
                            subtitle: "unlimited programs + all features",
                            price: ptProduct.displayPrice + "/month",
                            color: DoodleTheme.yellow,
                            isFeatured: true
                        ) {
                            await purchaseProduct(ptProduct)
                        }
                    }

                    // single program card
                    if let singleProduct = store.singleProgramProduct {
                        purchaseCard(
                            title: "single program",
                            subtitle: "one ai-generated program",
                            price: singleProduct.displayPrice,
                            color: DoodleTheme.purple,
                            isFeatured: false
                        ) {
                            await purchaseProduct(singleProduct)
                        }
                    }

                    if store.products.isEmpty {
                        Text("loading products...")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.dim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 4) {
                            Text("!")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.red)
                            Text(error)
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                    }

                    // restore
                    Button {
                        Task { await store.restorePurchases() }
                    } label: {
                        Text("restore purchases")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)

                    // legal
                    Text("payment will be charged to your Apple ID account. subscription auto-renews monthly unless cancelled at least 24 hours before the end of the current period.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(DoodleTheme.dim.opacity(0.6))
                        .padding(.top, 4)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
            .overlay {
                if isPurchasing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(DoodleTheme.yellow)
                        Text("processing...")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DoodleTheme.bg.opacity(0.9))
                }
            }
            .overlay {
                if showSuccess {
                    VStack(spacing: 12) {
                        Text("★")
                            .font(.system(size: 60))
                            .foregroundStyle(DoodleTheme.yellow)
                        Text("welcome to pocket pt!")
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.yellow)
                        Text("your personal trainer is ready")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DoodleTheme.bg.opacity(0.95))
                    .onTapGesture { dismiss() }
                }
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, desc: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(DoodleTheme.fg)
                Text(desc)
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
    }

    // MARK: - Purchase Card

    private func purchaseCard(title: String, subtitle: String, price: String, color: Color, isFeatured: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(isFeatured ? DoodleTheme.bg : DoodleTheme.fg)
                        Text(subtitle)
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(isFeatured ? DoodleTheme.bg.opacity(0.7) : DoodleTheme.dim)
                    }
                    Spacer()
                    Text(price)
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(isFeatured ? DoodleTheme.bg : color)
                }
            }
            .padding(16)
            .background(isFeatured ? color : DoodleTheme.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFeatured ? .clear : color.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isPurchasing)
    }

    // MARK: - Purchase Action

    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            let success = try await store.purchase(product)
            if success {
                withAnimation { showSuccess = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        } catch {
            errorMessage = "purchase failed. please try again."
        }
        isPurchasing = false
    }
}
