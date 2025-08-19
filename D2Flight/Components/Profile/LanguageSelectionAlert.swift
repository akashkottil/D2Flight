//
//  LanguageSelectionAlert.swift
//  D2Flight
//
//  Created by Akash Kottil on 19/08/25.
//


import SwiftUI

// MARK: - Language Selection Alert
struct LanguageSelectionAlert: View {
    let countryName: String
    let currentLanguage: String
    let suggestedLanguage: String
    let onLanguageSelected: (String) -> Void
    let onCancel: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAlert()
                }
            
            // Alert card
            VStack(spacing: 20) {
                // Title
                Text("which.language.do.you.prefer".localized)
                    .font(CustomFont.font(.large, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                // Country context
                Text("language.change.for.country".localized(with: countryName))
                    .font(CustomFont.font(.medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                // Language options
                VStack(spacing: 12) {
                    // Suggested language button
                    Button(action: {
                        selectLanguage(suggestedLanguage)
                    }) {
                        HStack {
                            Text(getLanguageDisplayText(for: suggestedLanguage))
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color("Violet"))
                        .cornerRadius(12)
                    }
                    
                    // Stay in current language
                    Button(action: {
                        selectLanguage(currentLanguage)
                    }) {
                        HStack {
                            Text("stay.in.current.language".localized(with: getLanguageDisplayName(currentLanguage)))
                                .font(CustomFont.font(.medium))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Cancel button
                    Button(action: {
                        dismissAlert()
                    }) {
                        Text("cancel".localized)
                            .font(CustomFont.font(.medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
    
    private func selectLanguage(_ languageCode: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onLanguageSelected(languageCode)
        }
    }
    
    private func dismissAlert() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onCancel()
        }
    }
    
    private func getLanguageDisplayText(for languageCode: String) -> String {
        switch languageCode {
        case "ar": return "العربية (Arabic)"
        case "es": return "Español (Spanish)"
        case "fr": return "Français (French)"
        case "de": return "Deutsch (German)"
        case "it": return "Italiano (Italian)"
        case "pt": return "Português (Portuguese)"
        case "ru": return "Русский (Russian)"
        case "zh-Hans": return "中文 (Chinese)"
        case "ja": return "日本語 (Japanese)"
        case "ko": return "한국어 (Korean)"
        case "nl": return "Nederlands (Dutch)"
        case "pl": return "Polski (Polish)"
        case "cs": return "Čeština (Czech)"
        case "he": return "עברית (Hebrew)"
        case "tr": return "Türkçe (Turkish)"
        case "th": return "ไทย (Thai)"
        case "vi": return "Tiếng Việt (Vietnamese)"
        case "id": return "Bahasa Indonesia (Indonesian)"
        case "ms": return "Bahasa Melayu (Malay)"
        case "nb": return "Norsk (Norwegian)"
        case "sv": return "Svenska (Swedish)"
        case "da": return "Dansk (Danish)"
        case "fi": return "Suomi (Finnish)"
        case "el": return "Ελληνικά (Greek)"
        case "ro": return "Română (Romanian)"
        case "uk": return "Українська (Ukrainian)"
        default: return getLanguageDisplayName(languageCode)
        }
    }
    
    private func getLanguageDisplayName(_ languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode)?.capitalized ?? languageCode.uppercased()
    }
}

// MARK: - Alert Modifier
struct LanguageSelectionAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let countryName: String
    let currentLanguage: String
    let suggestedLanguage: String
    let onLanguageSelected: (String) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        LanguageSelectionAlert(
                            countryName: countryName,
                            currentLanguage: currentLanguage,
                            suggestedLanguage: suggestedLanguage,
                            onLanguageSelected: { language in
                                isPresented = false
                                onLanguageSelected(language)
                            },
                            onCancel: {
                                isPresented = false
                            }
                        )
                        .zIndex(1000)
                    }
                }
            )
    }
}

extension View {
    func languageSelectionAlert(
        isPresented: Binding<Bool>,
        countryName: String,
        currentLanguage: String,
        suggestedLanguage: String,
        onLanguageSelected: @escaping (String) -> Void
    ) -> some View {
        modifier(LanguageSelectionAlertModifier(
            isPresented: isPresented,
            countryName: countryName,
            currentLanguage: currentLanguage,
            suggestedLanguage: suggestedLanguage,
            onLanguageSelected: onLanguageSelected
        ))
    }
}