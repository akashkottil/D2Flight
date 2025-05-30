import Foundation

struct SearchLeg: Codable {
    let origin: String
    let destination: String
    let date: String // Format: "YYYY-MM-DD"
}

struct SearchRequest: Codable {
    let legs: [SearchLeg]
    let cabin_class: String
    let adults: Int
    let children_ages: [Int]
}

struct SearchResponse: Codable {
    let search_id: String
    let language: String
    let currency: String
    let mode: Int
    // Add other response fields as needed
}
