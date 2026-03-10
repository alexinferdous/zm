import SwiftUI
import MapKit

struct MosqueFinderView: View {
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel = MosqueViewModel()
    @State private var showingMap = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search city or mosque…", text: $viewModel.cityQuery)
                        .submitLabel(.search)
                        .onSubmit { Task { await viewModel.searchByCity() } }
                    if !viewModel.cityQuery.isEmpty {
                        Button {
                            viewModel.cityQuery = ""
                            Task {
                                if let coord = locationService.location?.coordinate {
                                    await viewModel.loadNearby(coordinate: coord)
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding()

                // Sort picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MosqueSortOption.allCases) { option in
                            SortChip(
                                option: option,
                                isSelected: viewModel.sortOption == option
                            ) {
                                viewModel.sortOption = option
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                Divider()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Finding mosques…")
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle).foregroundStyle(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        Button("Try Again") {
                            Task {
                                if !viewModel.cityQuery.isEmpty {
                                    await viewModel.searchByCity()
                                } else if let coord = locationService.location?.coordinate {
                                    await viewModel.loadNearby(coordinate: coord)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(.green)
                    }
                    Spacer()
                } else if viewModel.sortedMosques.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns").font(.largeTitle).foregroundStyle(.secondary)
                        Text("No mosques found").foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List(viewModel.sortedMosques) { mosque in
                        NavigationLink(destination: MosqueDetailView(mosque: mosque)) {
                            MosqueRow(mosque: mosque)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Mosques")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            if let coord = locationService.location?.coordinate {
                                await viewModel.loadNearby(coordinate: coord)
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .tint(.green)
                }
            }
        }
        .onAppear {
            Task {
                if let coord = locationService.location?.coordinate, viewModel.mosques.isEmpty {
                    await viewModel.loadNearby(coordinate: coord)
                }
            }
        }
        .onChange(of: locationService.location) { loc in
            guard viewModel.mosques.isEmpty, let coord = loc?.coordinate else { return }
            Task { await viewModel.loadNearby(coordinate: coord) }
        }
    }
}

// MARK: - Subviews

private struct SortChip: View {
    let option: MosqueSortOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(option.rawValue, systemImage: option.icon)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green : Color(.systemFill),
                            in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct MosqueRow: View {
    let mosque: Mosque

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mosque.name)
                .font(.headline)

            Text(mosque.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 12) {
                Label(mosque.distanceString, systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(.green)

                if mosque.isHandicapAccessible {
                    Label("Accessible", systemImage: "figure.roll")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if mosque.hasParking {
                    Label("Parking", systemImage: "p.circle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
