@MainActor
class HomeViewModel: ObservableObject {
    @Published private(set) var intro: AppContent?
    @Published private(set) var sections: [AppContent] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    func loadContent() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let content = try await ContentLoader.shared.loadContent()
            intro = content.first { $0.type == .appIntro }
            sections = content.filter { $0.type == .section }
                .sorted { $0.order < $1.order }
        } catch {
            self.error = error
        }
    }
} 