import SwiftUI
import Siesta

@MainActor
struct LoginView: View {
    @State private var pat = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 10) {
            TextField(text: $pat, prompt: Text("Personal access token")) { }
                .textFieldStyle(.roundedBorder)

            Text("You can create an personal access token at https://github.com/settings/tokens")
            .font(.footnote)
            
            Spacer()
        }
        .padding()
        .background(Color(white: 0.9))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Log in") {
                    if !pat.isEmpty {
                        GitHubAPI.logIn(personalAccessToken: pat)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        #if !os(macOS)
        .navigationTitle("Log In to Github")
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
 
#Preview {
    NavigationStack {
        LoginView()
    }
}
