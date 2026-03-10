import Foundation
import CoreLocation

// MARK: - API Response Models

private struct AladhanTimingsResponse: Decodable {
    let code: Int
    let data: AladhanData
}

private struct AladhanData: Decodable {
    let timings: [String: String]
    let date: AladhanDate
    let meta: AladhanMeta
}

private struct AladhanDate: Decodable {
    let readable: String
    let timestamp: String
}

private struct AladhanMeta: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
}

private struct AladhanQiblaResponse: Decodable {
    let code: Int
    let data: QiblaData
}

private struct QiblaData: Decodable {
    let latitude: Double
    let longitude: Double
    let direction: Double
}

// MARK: - Service

class PrayerTimeService {
    static let shared = PrayerTimeService()
    private let baseURL = "https://api.aladhan.com/v1"

    func fetchPrayerTimes(
        for coordinate: CLLocationCoordinate2D,
        date: Date = Date(),
        method: CalculationMethod = .muslimWorldLeague
    ) async throws -> PrayerDay {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)

        let urlString = "\(baseURL)/timings/\(dateString)?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&method=\(method.rawValue)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AladhanTimingsResponse.self, from: data)
        return parsePrayerTimes(from: response.data, date: date)
    }

    func fetchQiblaDirection(for coordinate: CLLocationCoordinate2D) async throws -> Double {
        let urlString = "\(baseURL)/qibla/\(coordinate.latitude)/\(coordinate.longitude)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AladhanQiblaResponse.self, from: data)
        return response.data.direction
    }

    // MARK: - Parsing

    private func parsePrayerTimes(from data: AladhanData, date: Date) -> PrayerDay {
        let now = Date()
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let prayerKeys: [(PrayerName, String)] = [
            (.fajr, "Fajr"),
            (.sunrise, "Sunrise"),
            (.dhuhr, "Dhuhr"),
            (.asr, "Asr"),
            (.maghrib, "Maghrib"),
            (.isha, "Isha")
        ]

        var prayers: [Prayer] = []

        for (prayerName, key) in prayerKeys {
            guard var timeString = data.timings[key] else { continue }

            // Strip timezone suffix e.g. "05:30 (PKT)"
            if let spaceIndex = timeString.firstIndex(of: " ") {
                timeString = String(timeString[..<spaceIndex])
            }

            guard let parsedTime = timeFormatter.date(from: timeString) else { continue }

            var components = calendar.dateComponents([.hour, .minute], from: parsedTime)
            components.year = dateComponents.year
            components.month = dateComponents.month
            components.day = dateComponents.day

            guard let prayerDate = calendar.date(from: components) else { continue }

            let prayer = Prayer(
                name: prayerName,
                time: prayerDate,
                isNext: false,
                isPast: prayerDate < now
            )
            prayers.append(prayer)
        }

        // Mark the next prayer
        if let nextIndex = prayers.firstIndex(where: { !$0.isPast }) {
            prayers[nextIndex].isNext = true
        }

        return PrayerDay(date: date, prayers: prayers)
    }

    // MARK: - Local Qibla Calculation (offline fallback)

    func calculateQiblaLocally(from coordinate: CLLocationCoordinate2D) -> Double {
        let kaabaLat = 21.4225 * Double.pi / 180
        let kaabaLon = 39.8262 * Double.pi / 180
        let userLat = coordinate.latitude * Double.pi / 180
        let userLon = coordinate.longitude * Double.pi / 180

        let deltaLon = kaabaLon - userLon
        let y = sin(deltaLon) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(deltaLon)

        var bearing = atan2(y, x) * 180 / Double.pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }
}
