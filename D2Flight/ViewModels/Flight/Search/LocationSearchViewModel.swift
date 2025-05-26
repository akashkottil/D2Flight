import Foundation
import Combine

class LocationViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var locations: [Location] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard !text.isEmpty else {
                    self?.locations = []
                    return
                }
                
                LocationAPI.fetchLocations(searchQuery: text) { results in
                    DispatchQueue.main.async {
                        self?.locations = results
                    }
                }
            }
            .store(in: &cancellables)
    }
}
