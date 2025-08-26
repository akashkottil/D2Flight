//
//  FilterViewModel+BuildRequestUpdate.swift
//  D2Flight
//
//  Extension to update the buildPollRequest method with proper price parameter support
//

import Foundation

extension FilterViewModel {
    
    // ✅ UPDATED: Enhanced buildPollRequest method with price support
    func buildPollRequestEnhanced() -> PollRequest {
        var request = PollRequest()
        
        print("\n🔧 ===== BUILDING ENHANCED POLL REQUEST =====")
        
        // Sort options
        if selectedSortOption != .best {
            switch selectedSortOption {
            case .best:
                request.sort_by = "quality"
                request.sort_order = "desc"
            case .cheapest:
                request.sort_by = "price"
                request.sort_order = "asc"
            case .quickest:
                request.sort_by = "duration"
                request.sort_order = "asc"
            case .earliest:
                request.sort_by = "departure"
                request.sort_order = "asc"
            }
            print("   ✓ Sort: \(request.sort_by!) \(request.sort_order!)")
        }
        
        // Duration filter
        if maxDuration < 1440 {
            request.duration_max = Int(maxDuration)
            print("   ✓ Duration: ≤ \(Int(maxDuration)) minutes")
        }
        
        // Stop count filter
        if isExactStopsFilter && exactStops != nil {
            request.stop_count_exact = exactStops
            print("   ✓ Exact Stops: \(exactStops!)")
        } else if maxStops < 3 {
            request.stop_count_max = maxStops
            print("   ✓ Max Stops: ≤ \(maxStops)")
        }
        
        // Time range filters
        var timeRanges: [ArrivalDepartureRange] = []
        
        let hasDepartureFilter = departureTimeRange != 0...86400
        let hasArrivalFilter = arrivalTimeRange != 0...86400
        
        if hasDepartureFilter || hasArrivalFilter {
            let departure = hasDepartureFilter ?
                TimeRange(min: Int(departureTimeRange.lowerBound), max: Int(departureTimeRange.upperBound)) :
                TimeRange(min: 0, max: 86400)
            
            let arrival = hasArrivalFilter ?
                TimeRange(min: Int(arrivalTimeRange.lowerBound), max: Int(arrivalTimeRange.upperBound)) :
                TimeRange(min: 0, max: 86400)
            
            timeRanges.append(ArrivalDepartureRange(arrival: arrival, departure: departure))
            print("   ✓ Outbound time filters applied")
        }
        
        // Return leg time filters (if round trip)
        if isRoundTrip {
            let hasReturnDepartureFilter = returnDepartureTimeRange != 0...86400
            let hasReturnArrivalFilter = returnArrivalTimeRange != 0...86400
            
            if hasReturnDepartureFilter || hasReturnArrivalFilter {
                let returnDeparture = hasReturnDepartureFilter ?
                    TimeRange(min: Int(returnDepartureTimeRange.lowerBound), max: Int(returnDepartureTimeRange.upperBound)) :
                    TimeRange(min: 0, max: 86400)
                
                let returnArrival = hasReturnArrivalFilter ?
                    TimeRange(min: Int(returnArrivalTimeRange.lowerBound), max: Int(returnArrivalTimeRange.upperBound)) :
                    TimeRange(min: 0, max: 86400)
                
                if timeRanges.isEmpty {
                    timeRanges.append(ArrivalDepartureRange(
                        arrival: TimeRange(min: 0, max: 86400),
                        departure: TimeRange(min: 0, max: 86400)
                    ))
                }
                
                timeRanges.append(ArrivalDepartureRange(arrival: returnArrival, departure: returnDeparture))
                print("   ✓ Return time filters applied")
            }
        }
        
        if !timeRanges.isEmpty {
            request.arrival_departure_ranges = timeRanges
        }
        
        // Airline filters
        if !selectedAirlines.isEmpty {
            request.iata_codes_include = Array(selectedAirlines)
            print("   ✓ Include Airlines: \(selectedAirlines.joined(separator: ", "))")
        }
        
        if !excludedAirlines.isEmpty {
            request.iata_codes_exclude = Array(excludedAirlines)
            print("   ✓ Exclude Airlines: \(excludedAirlines.joined(separator: ", "))")
        }
        
        // ✅ CRITICAL: Enhanced price filters with proper logic
        if shouldApplyPriceFilter() {
            request.price_min = Int(priceRange.lowerBound)
            request.price_max = Int(priceRange.upperBound)
            
            print("   ✅ PRICE FILTER APPLIED:")
            print("     price_min: \(request.price_min!)")
            print("     price_max: \(request.price_max!)")
            print("     Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        } else {
            print("   ❌ Price filter NOT applied")
            if !hasAPIDataLoaded {
                print("     Reason: No API data loaded yet")
            } else if !userHasModifiedPrice {
                print("     Reason: User hasn't modified price range")
            } else {
                print("     Reason: Price range matches API defaults")
            }
        }
        
        print("🔧 Built Enhanced PollRequest with \(request.hasFilters() ? "filters" : "no filters")")
        print("🔧 ===== END BUILDING ENHANCED POLL REQUEST =====\n")
        
        return request
    }
    
    // ✅ Override the original buildPollRequest to use enhanced version
    func buildPollRequestWithPriceSupport() -> PollRequest {
        return buildPollRequestEnhanced()
    }
}
