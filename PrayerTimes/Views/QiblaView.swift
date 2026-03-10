import SwiftUI
import CoreLocation

struct QiblaView: View {
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel = QiblaViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    if viewModel.isLoading {
                        ProgressView("Calculating Qibla…")
                    } else {
                        QiblaCompass(
                            needleAngle: viewModel.needleAngle,
                            isAligned: viewModel.isAligned,
                            qiblaDirection: viewModel.qiblaDirection,
                            heading: viewModel.compassHeading
                        )
                    }

                    VStack(spacing: 8) {
                        if viewModel.isAligned {
                            Label("Facing the Qibla", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                        } else {
                            Text("Rotate \(Int(viewModel.needleAngle))° to face Qibla")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }

                        Text("Qibla: \(Int(viewModel.qiblaDirection))° · Heading: \(Int(viewModel.compassHeading))°")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Point the top of your phone toward the highlighted direction")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Qibla Direction")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: locationService.location) { location in
            guard let coord = location?.coordinate else { return }
            Task { await viewModel.load(for: coord) }
        }
        .onChange(of: locationService.heading) { heading in
            guard let heading else { return }
            viewModel.updateHeading(heading)
        }
        .onAppear {
            if let coord = locationService.location?.coordinate {
                Task { await viewModel.load(for: coord) }
            }
        }
    }
}

// MARK: - Compass View

private struct QiblaCompass: View {
    let needleAngle: Double
    let isAligned: Bool
    let qiblaDirection: Double
    let heading: Double

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color(.systemFill), lineWidth: 2)
                .frame(width: 280, height: 280)

            // Cardinal directions
            ForEach(["N", "E", "S", "W"].indices, id: \.self) { i in
                let angle = Double(i) * 90.0
                let label = ["N", "E", "S", "W"][i]
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(label == "N" ? .red : .secondary)
                    .rotationEffect(.degrees(-heading))
                    .offset(y: -120)
                    .rotationEffect(.degrees(angle))
            }

            // Degree ticks
            ForEach(0..<36, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(.systemFill))
                    .frame(width: 1, height: i % 9 == 0 ? 12 : 6)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(i) * 10))
            }

            // Qibla needle
            ZStack {
                // Tail (points away from Qibla)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.4))
                    .frame(width: 6, height: 80)
                    .offset(y: 48)

                // Head (points to Qibla)
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isAligned ? Color.green : Color.green)
                        .frame(width: 6, height: 80)
                        .offset(y: -48)

                    // Kaaba icon at tip
                    Image(systemName: "square.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isAligned ? Color.green : Color.primary)
                                .frame(width: 24, height: 24)
                        )
                        .offset(y: -92)
                }
            }
            .rotationEffect(.degrees(needleAngle))
            .animation(.easeInOut(duration: 0.3), value: needleAngle)

            // Center circle
            Circle()
                .fill(isAligned ? Color.green : Color(.systemBackground))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle().stroke(Color(.systemFill), lineWidth: 2)
                )
        }
    }
}
