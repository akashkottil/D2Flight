//// ResultHeader+Airlines.swift
//// Extension to handle airline updates in ResultHeader
//
//import Foundation
//import SwiftUI
//
//extension ResultHeader {
//    
//    /// Update available airlines from poll response
//    /// This method should be called when poll response is received
//    func updateAirlinesFromPollResponse(_ pollResponse: PollResponse) {
//        print("🔧 ResultHeader: Updating available airlines from poll response")
//        print("   Airlines received: \(pollResponse.airlines.count)")
//        
//        // Use the FilterViewModel extension method
//        filterViewModel.updateAvailableAirlines(from: pollResponse)
//        
//        print("✅ ResultHeader: Airlines updated successfully")
//        print("   Total available: \(filterViewModel.availableAirlines.count)")
//        print("   Currently selected: \(filterViewModel.selectedAirlines.count)")
//    }
//    
//    /// Get airline filter button title based on current selection
//    func getAirlineFilterTitle() -> String {
//        return filterViewModel.getAirlineFilterDisplayText()
//    }
//    
//    /// Check if airline filter is active
//    func isAirlineFilterActive() -> Bool {
//        return !filterViewModel.selectedAirlines.isEmpty
//    }
//}
