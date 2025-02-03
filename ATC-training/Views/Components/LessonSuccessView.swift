import SwiftUI

struct LessonSuccessView: View {
    let lesson: Lesson
    let completedSteps: [CompletedStep]
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Lesson Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(completedSteps) { step in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(step.title)
                            .font(.body)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
            )
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
        }
        .padding()
    }
} 