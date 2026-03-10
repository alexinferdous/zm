import SwiftUI
import AppIntents

@main
struct PrayerTimesApp: App {
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
                .onAppear {
                    locationService.requestPermission()
                    PrayerTimesShortcuts.updateAppShortcutParameters()
                }
                .onChange(of: locationService.location) { location in
                    // Persist last known location so Siri intents can access it
                    guard let coord = location?.coordinate else { return }
                    UserDefaults.standard.set(coord.latitude, forKey: "lastLatitude")
                    UserDefaults.standard.set(coord.longitude, forKey: "lastLongitude")
                }
        }
    }
}
