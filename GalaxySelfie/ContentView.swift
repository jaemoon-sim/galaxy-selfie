import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SelfieCaptureViewModel()

    var body: some View {
        ZStack {
            if viewModel.isCameraReady {
                CameraPreviewView(session: viewModel.cameraSession.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                topStatus
                Spacer()
                countdown
                Spacer()
                bottomControls
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var topStatus: some View {
        HStack {
            Circle()
                .fill(viewModel.isPalmCurrentlyDetected ? Color.green : Color.white.opacity(0.35))
                .frame(width: 10, height: 10)

            Text(viewModel.permissionMessage ?? viewModel.statusText)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()
        }
        .padding(12)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var countdown: some View {
        if let countdownText = viewModel.countdownText {
            Text(countdownText)
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 12)
                .monospacedDigit()
        }
    }

    private var bottomControls: some View {
        HStack {
            Spacer()

            if viewModel.canCancelCountdown {
                Button("Cancel") {
                    viewModel.cancelCountdown()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.55), in: Capsule())
            }
        }
        .frame(height: 56)
    }
}

#Preview {
    ContentView()
}
