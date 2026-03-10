import Foundation

enum PrayerName: String, CaseIterable, Codable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var icon: String {
        switch self {
        case .fajr: return "moon.stars.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.fill"
        }
    }

    var color: String {
        switch self {
        case .fajr: return "indigo"
        case .sunrise: return "orange"
        case .dhuhr: return "yellow"
        case .asr: return "green"
        case .maghrib: return "orange"
        case .isha: return "purple"
        }
    }
}

struct Prayer: Identifiable {
    let id = UUID()
    let name: PrayerName
    let time: Date
    var isNext: Bool = false
    var isPast: Bool = false

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

struct PrayerDay {
    let date: Date
    var prayers: [Prayer]

    var nextPrayer: Prayer? {
        prayers.first { !$0.isPast }
    }

    var currentPrayer: Prayer? {
        prayers.last { $0.isPast }
    }
}

enum CalculationMethod: Int, CaseIterable, Identifiable {
    case karachi = 1
    case isna = 2
    case muslimWorldLeague = 3
    case makkah = 4
    case egypt = 5
    case tehran = 7
    case jafari = 0

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .isna: return "ISNA (North America)"
        case .egypt: return "Egyptian General Authority"
        case .makkah: return "Umm Al-Qura (Makkah)"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .tehran: return "Institute of Geophysics, Tehran"
        case .jafari: return "Shia Ithna-Ashari (Jafari)"
        }
    }
}
