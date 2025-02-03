import SwiftUI

struct PhraseElement: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
            .foregroundColor(color)
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
            )
    }
} 