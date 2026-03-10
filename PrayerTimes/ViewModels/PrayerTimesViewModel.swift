import Foundation
import CoreLocation
import Combine

@MainActor
class PrayerTimesViewModel: ObservableObject {
    @Published var prayerDay: PrayerDay?
    @Published var isLoading = false
    @Published var error: String?
    @Published var locationName = ""
    @Published var selectedMethod: CalculationMethod = .muslimWorldLeague

    private let service = PrayerTimeService.shared
    private var refreshTask: Task<Void, Never>?

    var nextPrayer: Prayer? { prayerDay?.nextPrayer }

    var timeUntilNextPrayer: String {
        guard let next = nextPrayer else { return "" }
        let diff = next.time.timeIntervalSinceNow
        guard diff > 0 else { return "Now" }
        let hours = Int(diff) / 3600
        let minutes = Int(diff) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    func load(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil

        async let prayerDayResult = service.fetchPrayerTimes(for: coordinate, method: selectedMethod)
        async let locationNameResult = reverseGeocode(coordinate)

        do {
            prayerDay = try await prayerDayResult
            locationName = await locationNameResult
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func startAutoRefresh(coordinate: CLLocationCoordinate2D) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await load(for: coordinate)
                // Refresh every minute to keep "next prayer" accurate
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else { return "" }
        return [placemark.locality, placemark.country].compactMap { $0 }.joined(separator: ", ")
    }
}
