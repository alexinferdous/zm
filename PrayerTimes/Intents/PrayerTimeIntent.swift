import AppIntents
import CoreLocation

// MARK: - "Next Prayer Time" Siri Intent
// Trigger: "Hey Siri, what's the next prayer time?" / "Hey Siri, when is the next prayer?"

struct NextPrayerTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Prayer Time"
    static var description = IntentDescription("Find out when the next prayer time is.")

    static var openAppWhenRun = false

    // Provide Siri phrase suggestions shown in Settings > Siri & Search
    static var suggestedInvocationPhrases: [String] = [
        "When is the next prayer?",
        "What's the next prayer time?",
        "Next prayer time"
    ]

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let location = try await fetchCurrentLocation()
        let prayerDay = try await PrayerTimeService.shared.fetchPrayerTimes(for: location)

        guard let next = prayerDay.nextPrayer else {
            return .result(
                dialog: "All prayers for today are complete. The first prayer tomorrow is Fajr.",
                view: PrayerTimesSnippetView(prayers: prayerDay.prayers, next: nil)
            )
        }

        let dialog: IntentDialog = "\(next.name.rawValue) is at \(next.timeString). That's in \(timeUntil(next.time))."

        return .result(
            dialog: dialog,
            view: PrayerTimesSnippetView(prayers: prayerDay.prayers, next: next)
        )
    }

    private func fetchCurrentLocation() async throws -> CLLocationCoordinate2D {
        // Use stored last known location from UserDefaults (set by the main app)
        let lat = UserDefaults.standard.double(forKey: "lastLatitude")
        let lon = UserDefaults.standard.double(forKey: "lastLongitude")

        guard lat != 0, lon != 0 else {
            throw IntentError.locationUnavailable
        }

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func timeUntil(_ date: Date) -> String {
        let diff = date.timeIntervalSinceNow
        guard diff > 0 else { return "now" }
        let hours = Int(diff) / 3600
        let minutes = Int(diff) % 3600 / 60
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") and \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}

// MARK: - "All Prayer Times" Intent

struct AllPrayerTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's Prayer Times"
    static var description = IntentDescription("Show all prayer times for today.")

    static var suggestedInvocationPhrases: [String] = [
        "Show today's prayer times",
        "What are today's prayer times?",
        "Prayer times for today"
    ]

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let lat = UserDefaults.standard.double(forKey: "lastLatitude")
        let lon = UserDefaults.standard.double(forKey: "lastLongitude")
        guard lat != 0, lon != 0 else {
            throw IntentError.locationUnavailable
        }

        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let prayerDay = try await PrayerTimeService.shared.fetchPrayerTimes(for: coordinate)
        let next = prayerDay.nextPrayer

        let summary = prayerDay.prayers
            .map { "\($0.name.rawValue) at \($0.timeString)" }
            .joined(separator: ", ")

        return .result(
            dialog: "Today's prayer times are: \(summary).",
            view: PrayerTimesSnippetView(prayers: prayerDay.prayers, next: next)
        )
    }
}

// MARK: - Siri Snippet View

struct PrayerTimesSnippetView: View {
    let prayers: [Prayer]
    let next: Prayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(prayers) { prayer in
                HStack {
                    Image(systemName: prayer.name.icon)
                        .foregroundStyle(prayer.id == next?.id ? Color.green : Color.secondary)
                        .frame(width: 20)
                    Text(prayer.name.rawValue)
                        .font(.subheadline.weight(prayer.id == next?.id ? .semibold : .regular))
                    Spacer()
                    Text(prayer.timeString)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(prayer.id == next?.id ? Color.green : Color.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Intent Errors

enum IntentError: Error, LocalizedError {
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "Location not available. Please open the Prayer Times app first."
        }
    }
}

// MARK: - App Shortcuts Provider (registers phrases with Siri)

struct PrayerTimesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPrayerTimeIntent(),
            phrases: [
                "When is the next prayer in \(.applicationName)?",
                "Next prayer time in \(.applicationName)",
                "What is the next prayer in \(.applicationName)?"
            ],
            shortTitle: "Next Prayer",
            systemImageName: "clock.fill"
        )

        AppShortcut(
            intent: AllPrayerTimesIntent(),
            phrases: [
                "Show prayer times in \(.applicationName)",
                "Today's prayer times in \(.applicationName)"
            ],
            shortTitle: "Prayer Times",
            systemImageName: "list.bullet.clipboard.fill"
        )
    }
}
