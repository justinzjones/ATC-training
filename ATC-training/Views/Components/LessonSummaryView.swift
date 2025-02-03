import SwiftUI

struct LessonSummaryView: View {
    let lesson: Lesson
    let completedSteps: [CompletedStep]
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text(lesson.objective)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .opacity(showContent ? 1 : 0)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(completedSteps.enumerated()), id: \.element.id) { index, step in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .scaleEffect(showContent ? 1 : 0)
                            .animation(.spring(dampingFraction: 0.7).delay(Double(index) * 0.2), value: showContent)
                        
                        Text(step.title)
                            .font(.body)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -20)
                            .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.2), value: showContent)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
            )
            
            Text("Exercise Complete")
                .font(.headline)
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(dampingFraction: 0.7).delay(0.5), value: showContent)
            
            Text("All requirements met")
                .font(.subheadline)
                .foregroundColor(.green)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.6), value: showContent)
            
            Button(action: {
                dismiss()
            }) {
                Text("Continue to Next Exercise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.3).delay(0.7), value: showContent)
        }
        .padding(.vertical)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

struct CompletedStep: Identifiable {
    let id = UUID()
    let title: String
} 