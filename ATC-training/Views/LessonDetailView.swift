import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    @StateObject private var viewModel: LessonDetailViewModel
    @State private var showingSuccess = false
    @Environment(\.dismiss) private var dismiss
    @State private var scrollProxy: ScrollViewProxy?
    
    init(lesson: Lesson) {
        self.lesson = lesson
        self._viewModel = StateObject(wrappedValue: LessonDetailViewModel(lesson: lesson))
    }
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    // Title and step indicator row
                    HStack {
                        Text("Lesson \(lesson.lessonNumber)")
                            .font(.title)  // Changed from .title2
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        StepIndicator(
                            totalSteps: viewModel.totalSteps,
                            currentStep: viewModel.currentStep
                        )
                    }
                    .padding(.horizontal)
                    
                    // Lesson objective
                    Text(lesson.objective)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if viewModel.currentState == .complete {
                        LessonSuccessView(
                            lesson: lesson,
                            completedSteps: completedSteps,
                            onContinue: { dismiss() }
                        )
                        .transition(.opacity)
                    } else {
                        // Current step content
                        VStack(spacing: 24) {
                            // Situation Card
                            SituationCard(situationText: viewModel.situationText)
                                .padding(.horizontal)
                                .transition(.opacity)
                            
                            // Pilot Request
                            if viewModel.currentState >= .pilotRequest,
                               let pilotRequest = viewModel.pilotRequest {
                                RequestCard(
                                    title: "Your Request",
                                    isCompleted: viewModel.currentState > .pilotRequest,
                                    pilotRequest: pilotRequest,
                                    onSuccess: {
                                        withAnimation {
                                            viewModel.advanceToNextState()
                                        }
                                    },
                                    currentStep: viewModel.currentStep
                                )
                                .padding(.horizontal)
                            }
                            
                            // ATC Response and Readback section
                            if viewModel.currentState >= .atcResponse {
                                VStack(spacing: 16) {
                                    ATCResponseCard(responseText: viewModel.atcResponse ?? "")
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    
                                    if let readback = viewModel.pilotReadback {
                                        RequestCard(
                                            title: "Pilot Readback",
                                            isCompleted: viewModel.currentState > .pilotReadback,
                                            pilotRequest: readback,
                                            onSuccess: {
                                                withAnimation(.easeInOut) {
                                                    viewModel.completeReadback()
                                                }
                                            },
                                            currentStep: viewModel.currentStep
                                        )
                                        .id("readback-step-\(viewModel.currentStep)")
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal)
                                .onChange(of: viewModel.currentStep) { _ in
                                    withAnimation {
                                        proxy.scrollTo("readback-step-\(viewModel.currentStep)", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)  // Remove large navigation title
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
            await viewModel.loadContent()
        }
        .animation(.easeInOut, value: viewModel.currentStep)
        .animation(.easeInOut, value: viewModel.currentState)
    }
    
    var completedSteps: [CompletedStep] {
        var steps = [CompletedStep(title: "Situation Review")]
        
        // Add steps based on lesson content
        if viewModel.pilotRequest != nil {
            steps.append(CompletedStep(title: "Initial Request"))
        }
        
        if viewModel.atcResponse != nil {
            steps.append(CompletedStep(title: "ATC Response"))
        }
        
        if viewModel.pilotReadback != nil {
            steps.append(CompletedStep(title: "Pilot Readback"))
        }
        
        return steps
    }
}

struct SituationCard: View {
    let situationText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title with plane icon
            HStack {
                Image(systemName: "airplane")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Situation")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.blue)
            }
            
            // Situation text
            Text(situationText)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, y: 2)
        )
    }
}

#Preview {
    NavigationView {
        LessonDetailView(lesson: Lesson(
            id: "preview",
            section: "VFR",
            subsection: "Taxi Out",
            lessonNumber: 1,
            title: "Self announce Taxi",
            objective: "Practice announcing taxi intentions to the runway in use at a non-towered airport.",
            communicationType: "Broadcast Only",
            isControlled: false
        ))
    }
} 