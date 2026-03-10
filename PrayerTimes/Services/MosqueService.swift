import Foundation
import MapKit
import CoreLocation

class MosqueService {
    static let shared = MosqueService()

    func searchNearby(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance = 5000
    ) async throws -> [Mosque] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "mosque"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return response.mapItems.map { item in
            makeMosque(from: item, userLocation: userLocation)
        }.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
    }

    func searchByCity(_ cityName: String) async throws -> [Mosque] {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(cityName)

        guard let location = placemarks.first?.location else {
            throw MosqueServiceError.cityNotFound(cityName)
        }

        return try await searchNearby(coordinate: location.coordinate, radiusMeters: 10_000)
    }

    func searchByQuery(_ query: String, near coordinate: CLLocationCoordinate2D) async throws -> [Mosque] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(query) mosque"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 20_000,
            longitudinalMeters: 20_000
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return response.mapItems.map { makeMosque(from: $0, userLocation: userLocation) }
    }

    // MARK: - Private

    private func makeMosque(from item: MKMapItem, userLocation: CLLocation) -> Mosque {
        let mosqueLocation = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )

        return Mosque(
            id: "\(item.placemark.coordinate.latitude),\(item.placemark.coordinate.longitude)",
            name: item.name ?? "Unknown Mosque",
            address: item.placemark.formattedAddress,
            coordinate: item.placemark.coordinate,
            distance: userLocation.distance(from: mosqueLocation),
            phoneNumber: item.phoneNumber,
            website: item.url,
            isHandicapAccessible: false,
            hasParking: false,
            transitScore: nil,
            mapItem: item
        )
    }
}

enum MosqueServiceError: LocalizedError {
    case cityNotFound(String)

    var errorDescription: String? {
        switch self {
        case .cityNotFound(let city):
            return "Could not find the city: \(city)"
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String {
        [subThoroughfare, thoroughfare, locality, administrativeArea, country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
