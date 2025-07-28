//
//  HotelWebView.swift
//  D2Flight
//
//  Created by Akash Kottil on 28/07/25.
//


import SwiftUI
import SafariServices

// MARK: - Hotel Web View
struct HotelWebView: UIViewControllerRepresentable {
    let url: String
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        let safari = SFSafariViewController(url: URL(string: url)!, configuration: config)
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}