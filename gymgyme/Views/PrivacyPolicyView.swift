import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("privacy policy")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(DoodleTheme.purple)
                        .padding(.bottom, 4)

                    policySection(
                        title: "local storage",
                        body: "all your data (exercises, workouts, meals, programs) is stored locally on your device only. nothing is uploaded to any server."
                    )

                    policySection(
                        title: "network requests",
                        body: "the only network requests this app makes are food search queries to the USDA FoodData Central API. these queries contain only the food name you search for — no personal or device information is sent."
                    )

                    policySection(
                        title: "analytics & tracking",
                        body: "this app does not use any analytics, tracking, or advertising frameworks. we do not collect any usage data."
                    )

                    policySection(
                        title: "account",
                        body: "no account or sign-up is required to use this app. there is no login, no email collection, and no user profiles stored remotely."
                    )

                    policySection(
                        title: "your data, your control",
                        body: "you can export all your data as a CSV file at any time from settings. you can also delete all data from the app using the reset option in settings."
                    )

                    policySection(
                        title: "contact",
                        body: "if you have any questions about this privacy policy, reach out at damla@gymgyme.app"
                    )

                    Text("last updated: march 2026")
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("done") { dismiss() }
                        .font(DoodleTheme.mono)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DoodleTheme.monoBold)
                .foregroundStyle(DoodleTheme.blue)
            Text(body)
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.fg)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DoodleTheme.surface)
        .cornerRadius(6)
    }
}

#Preview {
    PrivacyPolicyView()
}
