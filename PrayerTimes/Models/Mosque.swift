import Foundation
import CoreLocation
import MapKit

struct Mosque: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance?
    let phoneNumber: String?
    let website: URL?
    let isHandicapAccessible: Bool
    let hasParking: Bool
    let transitScore: Int?
    var mapItem: MKMapItem?

    var distanceString: String {
        guard let distance else { return "Unknown distance" }
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    var accessibilityLabel: String {
        isHandicapAccessible ? "Wheelchair accessible" : "Accessibility unknown"
    }

    var parkingLabel: String {
        hasParking ? "Parking available" : "Parking unknown"
    }

    var transitLabel: String {
        guard let score = transitScore else { return "Transit info unavailable" }
        switch score {
        case 80...: return "Excellent transit"
        case 60...: return "Good transit"
        case 40...: return "Some transit"
        default: return "Minimal transit"
        }
    }
}

enum MosqueSortOption: String, CaseIterable, Identifiable {
    case distance = "Distance"
    case accessibility = "Accessibility"
    case transit = "Transit"
    case parking = "Parking"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .distance: return "location.fill"
        case .accessibility: return "figure.roll"
        case .transit: return "bus.fill"
        case .parking: return "p.circle.fill"
        }
    }
}
