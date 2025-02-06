import SwiftUI

extension View {
    func atcNavigationTitle(_ title: String) -> some View {
        self
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .padding(.top, 4)
                }
            }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let intro = viewModel.intro {
                        IntroSection(intro: intro)
                            .accessibilityElement(children: .combine)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.sections) { section in
                            NavigationLink(destination: SubsectionsView(section: section)) {
                                SectionCard(section: section)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .atcNavigationTitle("ATC Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        VStack(alignment: .trailing) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .frame(height: 44)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
            }
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
        }
        .navigationViewStyle(.stack)
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
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: sectionIcon(for: section.title))
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(section.title.contains("VFR") ? .blue : .purple)
                .padding(.bottom, 4)
            
            Text(section.title)
                .font(.title3.weight(.semibold))
                .dynamicTypeSize(.large ... .accessibility2)
            
            Text(section.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .dynamicTypeSize(.large ... .accessibility1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to view \(section.title) lessons")
    }
    
    private func sectionIcon(for title: String) -> String {
        switch title {
        case "VFR Training":
            return "airplane.circle.fill"
        case "IFR Training":
            return "cloud.rain.circle.fill"
        default:
            return "book.circle.fill"
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
        }
    }
} 