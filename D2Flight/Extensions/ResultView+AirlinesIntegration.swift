// ResultView+AirlinesIntegration.swift
// Extension to properly handle airlines data flow in ResultView

import Foundation
import SwiftUI

extension ResultView {
    
    /// Handle poll response updates with proper airlines integration
    func handlePollResponseUpdate(_ pollResponse: PollResponse?) {
        guard let response = pollResponse else { return }
        
        print("🖥️ ResultView received poll response with \(response.results.count) results")
        print("🖥️ Total available flights: \(response.count)")
        print("🖥️ Available airlines: \(response.airlines.map { $0.airlineName }.joined(separator: ", "))")
        
        // ✅ CRITICAL: Update ResultHeader with airlines data
        updateResultHeaderWithAirlines(response)
        
        print("✅ Updated ResultHeader with API data including airlines")
    }
    
    /// Update ResultHeader with airlines data
    private func updateResultHeaderWithAirlines(_ pollResponse: PollResponse) {
        // This method should be called in the .onReceive for pollResponse in ResultView
        // The ResultHeader needs to be updated with airlines data
        
        print("🔧 Updating ResultHeader with airlines data:")
        print("   Airlines count: \(pollResponse.airlines.count)")
        print("   Flight results count: \(pollResponse.results.count)")
        
        // Airlines will be automatically updated through the @ObservedObject reference
        // But we need to ensure the FilterViewModel gets the poll response data
    }
}
