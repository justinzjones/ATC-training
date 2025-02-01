import Foundation

@MainActor
final class LessonsViewModel: ObservableObject {
    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private let section: String
    private let subsection: String
    
    init(section: String, subsection: String) {
        self.section = section
        self.subsection = subsection
        print("📚 LessonsView: Initialized for \(section) - \(subsection)")
    }
    
    func loadLessons() async {
        print("📚 LessonsView: Loading lessons for \(section) - \(subsection)...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allLessons = try await ContentLoader.shared.loadLessons()
            lessons = allLessons
                .filter { $0.section == section && $0.subsection == subsection }
                .sorted { $0.lessonNumber < $1.lessonNumber }
            
            print("📚 LessonsView: Loaded \(lessons.count) lessons")
            lessons.forEach { lesson in
                print("  📖 Lesson \(lesson.lessonNumber): \(lesson.title)")
            }
        } catch {
            print("❌ LessonsView: Error loading lessons - \(error.localizedDescription)")
            self.error = error
        }
    }
} 