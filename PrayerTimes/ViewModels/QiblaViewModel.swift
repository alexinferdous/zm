import Foundation
import CoreLocation
import Combine

@MainActor
class QiblaViewModel: ObservableObject {
    @Published var qiblaDirection: Double = 0
    @Published var compassHeading: Double = 0
    @Published var isLoading = false
    @Published var error: String?

    /// Degrees to rotate compass needle so it points to Qibla
    var needleAngle: Double {
        var angle = qiblaDirection - compassHeading
        if angle < 0 { angle += 360 }
        return angle
    }

    /// True when needle is within ±5° of Qibla
    var isAligned: Bool {
        let diff = abs(needleAngle).truncatingRemainder(dividingBy: 360)
        return diff < 5 || diff > 355
    }

    private let service = PrayerTimeService.shared

    func load(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil
        do {
            qiblaDirection = try await service.fetchQiblaDirection(for: coordinate)
        } catch {
            // Offline fallback — local spherical calculation
            qiblaDirection = service.calculateQiblaLocally(from: coordinate)
        }
        isLoading = false
    }

    func updateHeading(_ heading: CLHeading) {
        compassHeading = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
    }
}
