//
//  FlightDeeplinkSanitizer.swift
//  D2Flight
//
//  Created by Akash Kottil on 09/09/25.
//


import Foundation

enum FlightDeeplinkSanitizer {

    static func clean(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it starts with //example.com... → assume https
        if s.hasPrefix("//") { s = "https:" + s }

        // If missing scheme entirely → assume https
        if URL(string: s)?.scheme == nil {
            s = "https://" + s
        }

        // Fix common double slash path after host (https://host//path → https://host/path)
        if var comps = URLComponents(string: s),
           let host = comps.host,
           comps.path.hasPrefix("//") {
            comps.path = String(comps.path.dropFirst())
            s = comps.string ?? s
        }

        // Some partners encode an internal URL parameter; if that param itself is http(s) after decoding, prefer it
        if let extracted = firstHTTPURLInsideQuery(s) {
            s = extracted
        }

        // Replace spaces
        s = s.replacingOccurrences(of: " ", with: "%20")

        return s
    }

    private static func firstHTTPURLInsideQuery(_ s: String) -> String? {
        guard var comps = URLComponents(string: s),
              let items = comps.queryItems, !items.isEmpty else { return nil }

        // Common param keys that carry an inner link
        let keys = ["url", "u", "target", "redirect", "redirect_uri", "r", "dest", "destination"]
        for key in keys {
            if let val = items.first(where: { $0.name == key })?.value {
                // Try raw value first
                if let inner = URL(string: val),
                   let scheme = inner.scheme?.lowercased(),
                   scheme == "http" || scheme == "https" {
                    return inner.absoluteString
                }
                // Then try a percent-decoded pass
                if let decoded = val.removingPercentEncoding,
                   let inner2 = URL(string: decoded),
                   let scheme2 = inner2.scheme?.lowercased(),
                   scheme2 == "http" || scheme2 == "https" {
                    return inner2.absoluteString
                }
            }
        }
        return nil
    }

    static func toSafeURL(_ s: String) -> URL {
        let cleaned = clean(s)
        if let u = URL(string: cleaned),
           let scheme = u.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return u
        }
        // Never pass non-http(s) into SFSafariViewController
        return URL(string: "https://www.google.com")!
    }
}
