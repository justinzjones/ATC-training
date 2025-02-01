import SwiftUI

struct SubsectionsView: View {
    let section: AppContent
    @StateObject private var viewModel: SubsectionsViewModel
    
    init(section: AppContent) {
        self.section = section
        self._viewModel = StateObject(wrappedValue: SubsectionsViewModel(section: section))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.subsections) { subsection in
                    SubsectionCard(subsection: subsection)
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
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
            await viewModel.loadSubsections()
        }
    }
}

struct SubsectionCard: View {
    let subsection: Subsection
    
    var body: some View {
        NavigationLink(destination: LessonsView(subsection: subsection)) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: iconName(for: subsection.title ?? ""))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor(for: subsection.title ?? ""))
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(subsection.title ?? "")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.blue)
                        .dynamicTypeSize(.large ... .accessibility2)
                    
                    Text(subsection.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .dynamicTypeSize(.large ... .accessibility1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
            )
            .accessibilityElement(children: .combine)
            .accessibilityHint("Double tap to view lessons for \(subsection.title ?? "")")
        }
    }
    
    private func iconName(for title: String) -> String {
        switch title {
        case "Taxi Out":
            return "airplane.circle.fill"
        case "Takeoff":
            return "airplane.departure"
        case "Flight Plan":
            return "doc.text.fill"
        case "Flight Following":
            return "binoculars.fill"
        case "Airspace Entry":
            return "map.circle.fill"
        case "Approach":
            return "arrow.down.circle.fill"
        case "Taxi In":
            return "parkingsign.circle.fill"
        case "Request Clearance":
            return "radio.fill"
        case "Departure":
            return "arrow.up.forward.circle.fill"
        case "Enroute (request)":
            return "paperplane.circle.fill"
        case "Enroute (receive)":
            return "antenna.radiowaves.left.and.right.circle.fill"
        case "Approach (request)":
            return "arrow.down.right.circle.fill"
        case "Approach (receive)":
            return "arrow.down.to.line.circle.fill"
        case "Landing":
            return "airplane.arrival"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func iconColor(for title: String) -> Color {
        switch title {
        case "Taxi Out", "Taxi In":
            return .yellow
        case "Takeoff":
            return .green
        case "Flight Plan":
            return .blue
        case "Flight Following":
            return .purple
        case "Airspace Entry":
            return .orange
        case "Approach":
            return .red
        case "Request Clearance":
            return .blue
        case "Departure":
            return .teal
        case "Enroute (request)":
            return .indigo
        case "Enroute (receive)":
            return .purple
        case "Approach (request)":
            return .orange
        case "Approach (receive)":
            return .pink
        case "Landing":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        SubsectionsView(section: AppContent(
            type: .section,
            title: "VFR Training",
            description: "VFR communications training",
            order: 1
        ))
    }
} 