import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .chinese:
            return "settings.language.chinese"
        case .english:
            return "settings.language.english"
        }
    }
}
