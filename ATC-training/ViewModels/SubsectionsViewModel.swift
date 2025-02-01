import Foundation

@MainActor
final class SubsectionsViewModel: ObservableObject {
    @Published private(set) var subsections: [Subsection] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private let section: AppContent
    
    init(section: AppContent) {
        self.section = section
        print("📑 SubsectionsView: Initialized for \(section.title)")
    }
    
    func loadSubsections() async {
        print("📑 SubsectionsView: Loading subsections for \(section.title)...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allSubsections = try await ContentLoader.shared.loadSubsections()
            let sectionName = section.title.replacingOccurrences(of: " Training", with: "")
            
            subsections = allSubsections
                .filter { $0.section == sectionName }
                .filter { $0.title != nil }
            
            print("📑 SubsectionsView: Loaded \(subsections.count) subsections for \(section.title)")
            subsections.forEach { subsection in
                print("  📱 Subsection: \(subsection.title ?? "Untitled")")
            }
        } catch {
            print("❌ SubsectionsView: Error loading subsections - \(error.localizedDescription)")
            self.error = error
        }
    }
} 