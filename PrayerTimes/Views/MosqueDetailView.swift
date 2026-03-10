import SwiftUI
import MapKit

struct MosqueDetailView: View {
    let mosque: Mosque
    @State private var region: MKCoordinateRegion
    @State private var showingWebsite = false
    @State private var prayerDay: PrayerDay?
    @State private var isLoadingPrayers = false

    init(mosque: Mosque) {
        self.mosque = mosque
        _region = State(initialValue: MKCoordinateRegion(
            center: mosque.coordinate,
            latitudinalMeters: 800,
            longitudinalMeters: 800
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Map
                Map(coordinateRegion: $region, annotationItems: [mosque]) { m in
                    MapMarker(coordinate: m.coordinate, tint: .green)
                }
                .frame(height: 220)
                .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mosque.name)
                            .font(.title2.bold())
                        Text(mosque.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Label(mosque.distanceString, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Divider()

                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(title: "Directions", icon: "map.fill", color: .blue) {
                            openInMaps()
                        }
                        if let phone = mosque.phoneNumber {
                            ActionButton(title: "Call", icon: "phone.fill", color: .green) {
                                callMosque(phone: phone)
                            }
                        }
                        if mosque.website != nil {
                            ActionButton(title: "Website", icon: "globe", color: .orange) {
                                showingWebsite = true
                            }
                        }
                    }

                    Divider()

                    // Amenities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amenities")
                            .font(.headline)

                        AmenityRow(icon: "figure.roll", label: "Wheelchair Accessible",
                                   value: mosque.isHandicapAccessible ? "Yes" : "Unknown",
                                   color: mosque.isHandicapAccessible ? .blue : .secondary)

                        AmenityRow(icon: "p.circle.fill", label: "Parking",
                                   value: mosque.hasParking ? "Available" : "Unknown",
                                   color: mosque.hasParking ? .orange : .secondary)

                        AmenityRow(icon: "bus.fill", label: "Transit",
                                   value: mosque.transitLabel,
                                   color: .purple)
                    }

                    Divider()

                    // Prayer times for this mosque's location
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Prayer Times")
                                .font(.headline)
                            Spacer()
                            if isLoadingPrayers {
                                ProgressView().scaleEffect(0.8)
                            }
                        }

                        if let day = prayerDay {
                            VStack(spacing: 0) {
                                ForEach(Array(day.prayers.enumerated()), id: \.element.id) { index, prayer in
                                    HStack {
                                        Image(systemName: prayer.name.icon)
                                            .foregroundStyle(prayer.isNext ? .green : .secondary)
                                            .frame(width: 24)
                                        Text(prayer.name.rawValue)
                                            .font(.body.weight(prayer.isNext ? .semibold : .regular))
                                        Spacer()
                                        Text(prayer.timeString)
                                            .font(.body.monospacedDigit())
                                            .foregroundStyle(prayer.isNext ? .green : .primary)
                                    }
                                    .padding(.vertical, 8)
                                    if index < day.prayers.count - 1 {
                                        Divider()
                                    }
                                }
                            }

                            if let website = mosque.website {
                                Text("For official prayer times, visit the mosque's website.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Open \(mosque.name)'s Website") {
                                    showingWebsite = true
                                }
                                .font(.caption)
                                .foregroundStyle(.green)
                                .buttonStyle(.plain)
                            }
                        } else if !isLoadingPrayers {
                            Text("Could not load prayer times.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(mosque.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingWebsite) {
            if let url = mosque.website {
                MosqueWebView(url: url, mosqueName: mosque.name)
            }
        }
        .task {
            await loadPrayerTimes()
        }
    }

    private func loadPrayerTimes() async {
        isLoadingPrayers = true
        if let day = try? await PrayerTimeService.shared.fetchPrayerTimes(for: mosque.coordinate) {
            prayerDay = day
        }
        isLoadingPrayers = false
    }

    private func openInMaps() {
        guard let mapItem = mosque.mapItem else {
            let placemark = MKPlacemark(coordinate: mosque.coordinate)
            let item = MKMapItem(placemark: placemark)
            item.name = mosque.name
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
            return
        }
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    private func callMosque(phone: String) {
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

private struct AmenityRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            Text(label).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary).font(.subheadline)
        }
    }
}
