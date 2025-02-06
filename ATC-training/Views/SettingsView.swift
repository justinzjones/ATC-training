import SwiftUI

struct SettingsView: View {
    @AppStorage("userCallsign") private var callsign = ""
    @AppStorage("isCallsignActive") private var isCallsignActive = false
    @AppStorage("speechRate") private var speechRate: Double = 0.5
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Callsign Settings")) {
                    Toggle("Use Custom Callsign", isOn: $isCallsignActive)
                    
                    if isCallsignActive {
                        TextField("Enter Callsign (e.g., N123AB)", text: $callsign)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .onChange(of: callsign) { newValue in
                                // Limit to 7 characters (standard ICAO format)
                                callsign = String(newValue.filter { $0.isLetter || $0.isNumber }.prefix(7)).uppercased()
                            }
                    }
                }
                
                Section(header: Text("Speech Settings")) {
                    Picker("Speech Rate", selection: $speechRate) {
                        Text("Slow").tag(0.3)
                        Text("Medium").tag(0.5)
                        Text("Fast").tag(0.7)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

enum SpeechRate: String, CaseIterable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"
    
    var rateValue: Float {
        switch self {
        case .slow: return 0.35
        case .medium: return 0.55
        case .fast: return 0.60
        }
    }
    
    var phrasePause: TimeInterval {
        switch self {
        case .slow: return 0.2
        case .medium: return 0.1
        case .fast: return 0.1
        }
    }
} 