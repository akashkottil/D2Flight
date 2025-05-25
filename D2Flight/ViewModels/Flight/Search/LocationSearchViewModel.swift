import Foundation
import Combine

class LocationSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [LocationData] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] term in
                guard let self = self, !term.isEmpty else {
                    self?.suggestions = []
                    return
                }
                self.fetchAutocomplete(for: term)
            }
            .store(in: &cancellables)
    }

    func fetchAutocomplete(for term: String) {
        LocationAPI.shared.fetchLocations(search: term) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.suggestions = data
                case .failure:
                    self.suggestions = []
                }
            }
        }
    }
}
