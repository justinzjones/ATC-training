import SwiftUI

struct LessonsView: View {
    let subsection: Subsection
    @StateObject private var viewModel: LessonsViewModel
    
    init(subsection: Subsection) {
        self.subsection = subsection
        self._viewModel = StateObject(wrappedValue: 
            LessonsViewModel(section: subsection.section, subsection: subsection.title ?? ""))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.lessons) { lesson in
                    LessonCard(lesson: lesson)
                }
            }
            .padding()
        }
        .navigationTitle(subsection.title ?? "Lessons")
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .task {
            await viewModel.loadLessons()
        }
    }
}

struct LessonCard: View {
    let lesson: Lesson
    
    var body: some View {
        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
            HStack(alignment: .top, spacing: 16) {
                // Lesson number circle
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text("\(lesson.lessonNumber)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.blue)
                        .dynamicTypeSize(.large ... .accessibility2)
                    
                    Text(lesson.objective)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .dynamicTypeSize(.large ... .accessibility1)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
            )
            .overlay(alignment: .topTrailing) {
                if lesson.isControlled {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to start lesson \(lesson.lessonNumber): \(lesson.title). \(lesson.isControlled ? "This is a towered airport lesson." : "This is a non-towered airport lesson.")")
    }
}

#Preview {
    NavigationView {
        LessonsView(subsection: Subsection(
            id: "VFR-TaxiOut",
            section: "VFR",
            title: "Taxi Out",
            description: "Learn proper communication for ground operations"
        ))
    }
} 