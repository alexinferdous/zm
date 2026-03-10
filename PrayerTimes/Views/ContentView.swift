import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationService: LocationService

    var body: some View {
        TabView {
            PrayerTimesView()
                .tabItem {
                    Label("Prayer Times", systemImage: "clock.fill")
                }

            QiblaView()
                .tabItem {
                    Label("Qibla", systemImage: "location.north.fill")
                }

            MosqueFinderView()
                .tabItem {
                    Label("Mosques", systemImage: "building.columns.fill")
                }
        }
        .tint(.green)
    }
}
