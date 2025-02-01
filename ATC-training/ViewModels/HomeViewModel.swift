import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var intro: AppContent?
    @Published private(set) var sections: [AppContent] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    func loadContent() async {
        print("🏠 HomeView: Loading main content...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let content = try await ContentLoader.shared.loadContent()
            intro = content.first { $0.type == .appIntro }
            sections = content.filter { $0.type == .section }
                .sorted { $0.order < $1.order }
            
            print("🏠 HomeView: Loaded \(sections.count) sections")
            sections.forEach { section in
                print("  📱 Section: \(section.title)")
            }
        } catch {
            print("❌ HomeView: Error loading content - \(error.localizedDescription)")
            self.error = error
        }
    }
} 