//
//  LanguageSelectionAlert.swift
//  D2Flight
//
//  Custom alert for language selection when changing countries
//

import SwiftUI

// MARK: - Language Selection Alert View Modifier
struct LanguageSelectionAlert: ViewModifier {
    @Binding var isPresented: Bool
    let countryName: String
    let currentLanguage: String
    let suggestedLanguage: String
    let onLanguageSelected: (String) -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Language Change", isPresented: $isPresented) {
                Button("Keep \(getLanguageDisplayName(currentLanguage))") {
                    onLanguageSelected(currentLanguage)
                }
                
                Button("Switch to \(getLanguageDisplayName(suggestedLanguage))") {
                    onLanguageSelected(suggestedLanguage)
                }
                
                Button("Cancel", role: .cancel) {
                    // Do nothing, just dismiss
                }
            } message: {
                Text("You've selected \(countryName). Would you like to switch to \(getLanguageDisplayName(suggestedLanguage)) or keep \(getLanguageDisplayName(currentLanguage))?")
            }
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        switch code {
        case "en": return "English"
        case "ar": return "العربية"
        case "de": return "Deutsch"
        case "es": return "Español"
        case "fr": return "Français"
        case "hi": return "हिन्दी"
        case "it": return "Italiano"
        case "ja": return "日本語"
        case "ko": return "한국어"
        case "pt": return "Português"
        case "ru": return "Русский"
        case "zh": return "中文"
        case "th": return "ไทย"
        case "tr": return "Türkçe"
        case "vi": return "Tiếng Việt"
        case "id": return "Bahasa Indonesia"
        case "ms": return "Bahasa Melayu"
        case "nl": return "Nederlands"
        case "sv": return "Svenska"
        case "da": return "Dansk"
        case "no": return "Norsk"
        case "fi": return "Suomi"
        case "pl": return "Polski"
        case "cs": return "Čeština"
        case "hu": return "Magyar"
        case "ro": return "Română"
        case "bg": return "Български"
        case "hr": return "Hrvatski"
        case "sk": return "Slovenčina"
        case "sl": return "Slovenščina"
        case "et": return "Eesti"
        case "lv": return "Latviešu"
        case "lt": return "Lietuvių"
        default: return code.capitalized
        }
    }
}

// MARK: - View Extension for Easy Usage
extension View {
    func languageSelectionAlert(
        isPresented: Binding<Bool>,
        countryName: String,
        currentLanguage: String,
        suggestedLanguage: String,
        onLanguageSelected: @escaping (String) -> Void
    ) -> some View {
        modifier(LanguageSelectionAlert(
            isPresented: isPresented,
            countryName: countryName,
            currentLanguage: currentLanguage,
            suggestedLanguage: suggestedLanguage,
            onLanguageSelected: onLanguageSelected
        ))
    }
}
