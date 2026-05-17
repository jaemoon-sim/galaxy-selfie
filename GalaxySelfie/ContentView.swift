import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SelfieCaptureViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("GalaxySelfie")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text(viewModel.statusText)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
