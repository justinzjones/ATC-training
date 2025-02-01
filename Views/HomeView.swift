import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let intro = viewModel.intro {
                        IntroSection(intro: intro)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.sections) { section in
                            SectionCard(section: section)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("ATC Training")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
        .task {
            await viewModel.loadContent()
        }
    }
}

struct IntroSection: View {
    let intro: AppContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(intro.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(intro.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct SectionCard: View {
    let section: AppContent
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: sectionIcon(for: section.title))
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                Text(section.title)
                    .font(.headline)
                
                Text(section.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
        }
    }
    
    private func sectionIcon(for title: String) -> String {
        switch title {
        case "VFR Training":
            return "airplane"
        case "IFR Training":
            return "cloud.rain"
        default:
            return "book.fill"
        }
    }
} 