import Foundation
import CoreLocation
import Combine

@MainActor
class MosqueViewModel: ObservableObject {
    @Published var mosques: [Mosque] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var sortOption: MosqueSortOption = .distance
    @Published var cityQuery = ""
    @Published var selectedMosque: Mosque?

    private let service = MosqueService.shared

    var sortedMosques: [Mosque] {
        switch sortOption {
        case .distance:
            return mosques.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        case .accessibility:
            return mosques.sorted { $0.isHandicapAccessible && !$1.isHandicapAccessible }
        case .transit:
            return mosques.sorted { ($0.transitScore ?? 0) > ($1.transitScore ?? 0) }
        case .parking:
            return mosques.sorted { $0.hasParking && !$1.hasParking }
        }
    }

    func loadNearby(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil
        do {
            mosques = try await service.searchNearby(coordinate: coordinate)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func searchByCity() async {
        guard !cityQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        error = nil
        do {
            mosques = try await service.searchByCity(cityQuery)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
