import SwiftUI

struct PrayerTimesView: View {
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel = PrayerTimesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if !locationService.isAuthorized {
                    LocationPermissionPrompt()
                } else if viewModel.isLoading && viewModel.prayerDay == nil {
                    ProgressView("Loading prayer times…")
                } else if let error = viewModel.error, viewModel.prayerDay == nil {
                    ErrorView(message: error) {
                        Task { await loadIfReady() }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let next = viewModel.nextPrayer {
                                NextPrayerCard(prayer: next, countdown: viewModel.timeUntilNextPrayer)
                            }

                            if let day = viewModel.prayerDay {
                                PrayerListCard(prayers: day.prayers)
                            }

                            MethodPickerCard(selected: $viewModel.selectedMethod)
                        }
                        .padding()
                    }
                    .refreshable { await loadIfReady() }
                }
            }
            .navigationTitle(viewModel.locationName.isEmpty ? "Prayer Times" : viewModel.locationName)
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: locationService.location) { _ in
            Task { await loadIfReady() }
        }
        .onChange(of: viewModel.selectedMethod) { _ in
            Task { await loadIfReady() }
        }
        .onAppear {
            Task { await loadIfReady() }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    private func loadIfReady() async {
        guard let coord = locationService.location?.coordinate else { return }
        await viewModel.load(for: coord)
    }
}

// MARK: - Subviews

private struct NextPrayerCard: View {
    let prayer: Prayer
    let countdown: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Next Prayer")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 12) {
                Image(systemName: prayer.name.icon)
                    .font(.title)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.name.rawValue)
                        .font(.title2.bold())
                    Text(prayer.name.arabicName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(prayer.timeString)
                        .font(.title2.bold())
                    Text("in \(countdown)")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PrayerListCard: View {
    let prayers: [Prayer]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                PrayerRow(prayer: prayer)
                if index < prayers.count - 1 {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PrayerRow: View {
    let prayer: Prayer

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(prayer.isNext ? Color.green.opacity(0.15) : Color.clear)
                    .frame(width: 36, height: 36)
                Image(systemName: prayer.name.icon)
                    .font(.body)
                    .foregroundStyle(prayer.isNext ? .green : prayer.isPast ? .secondary : .primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.name.rawValue)
                    .font(.body.weight(prayer.isNext ? .semibold : .regular))
                    .foregroundStyle(prayer.isPast && !prayer.isNext ? .secondary : .primary)
                Text(prayer.name.arabicName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(prayer.timeString)
                .font(.body.monospacedDigit())
                .foregroundStyle(prayer.isNext ? .green : prayer.isPast ? .secondary : .primary)

            if prayer.isNext {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(prayer.isNext ? Color.green.opacity(0.05) : Color.clear)
    }
}

private struct MethodPickerCard: View {
    @Binding var selected: CalculationMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calculation Method")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.horizontal)

            Picker("Method", selection: $selected) {
                ForEach(CalculationMethod.allCases) { method in
                    Text(method.name).tag(method)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LocationPermissionPrompt: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Location Access Required")
                .font(.headline)
            Text("Please enable location access in Settings to calculate prayer times for your location.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(.green)
        }
        .padding()
    }
}
