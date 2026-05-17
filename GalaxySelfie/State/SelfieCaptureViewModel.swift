import Foundation

@MainActor
final class SelfieCaptureViewModel: ObservableObject {
    static let palmHoldDuration: TimeInterval = 1
    static let countdownSeconds = 5
    static let captureCount = 10

    let cameraSession: CameraSessionController

    @Published private(set) var state: SelfieCaptureState = .idle
    @Published private(set) var isPalmCurrentlyDetected = false
    @Published private(set) var isCameraReady = false
    @Published private(set) var permissionMessage: String?

    private let palmDetector: PalmGestureDetector
    private let photoCaptureCoordinator: PhotoCaptureCoordinator
    private let photoLibrarySaver: PhotoLibrarySaver
    private var palmDetectedSince: Date?
    private var countdownTask: Task<Void, Never>?
    private var captureTask: Task<Void, Never>?
    private var isProcessingFrame = false

    init(
        cameraSession: CameraSessionController = CameraSessionController(),
        palmDetector: PalmGestureDetector = PalmGestureDetector(),
        photoCaptureCoordinator: PhotoCaptureCoordinator = PhotoCaptureCoordinator(),
        photoLibrarySaver: PhotoLibrarySaver = PhotoLibrarySaver()
    ) {
        self.cameraSession = cameraSession
        self.palmDetector = palmDetector
        self.photoCaptureCoordinator = photoCaptureCoordinator
        self.photoLibrarySaver = photoLibrarySaver
    }

    var statusText: String {
        state.statusText
    }

    var countdownText: String? {
        if case let .countingDown(seconds) = state {
            return "\(seconds)"
        }
        return nil
    }

    var canCancelCountdown: Bool {
        if case .countingDown = state {
            return true
        }
        return false
    }

    func start() async {
        guard await cameraSession.requestCameraAccess() else {
            permissionMessage = "Camera access is required"
            state = .failed("Camera access is required")
            return
        }

        guard await photoLibrarySaver.requestAddOnlyAccess() else {
            permissionMessage = "Photos access is required"
            state = .failed("Photos access is required")
            return
        }

        do {
            try cameraSession.configure()
        } catch {
            state = .failed("Camera unavailable")
            return
        }

        installFrameHandler()
        cameraSession.start()
        isCameraReady = true
        permissionMessage = nil
    }

    func stop() {
        countdownTask?.cancel()
        captureTask?.cancel()
        cameraSession.stop()
    }

    func handlePalmDetection(_ detected: Bool, at date: Date = Date()) {
        isPalmCurrentlyDetected = detected

        guard state.allowsPalmTrigger else {
            return
        }

        guard detected else {
            palmDetectedSince = nil
            state = .idle
            return
        }

        if palmDetectedSince == nil {
            palmDetectedSince = date
            state = .detectingPalm
            return
        }

        guard let palmDetectedSince else {
            return
        }

        if date.timeIntervalSince(palmDetectedSince) >= Self.palmHoldDuration {
            beginCountdown()
        }
    }

    func cancelCountdown() {
        guard canCancelCountdown else {
            return
        }
        countdownTask?.cancel()
        palmDetectedSince = nil
        state = .idle
    }

    private func installFrameHandler() {
        let detector = palmDetector
        cameraSession.onFrame = { [weak self] frame in
            Task { @MainActor [weak self] in
                guard let self, !self.isProcessingFrame else {
                    return
                }
                self.isProcessingFrame = true

                Task {
                    let detected = await detector.detectPalm(
                        in: frame.pixelBuffer,
                        orientation: frame.orientation
                    )
                    await MainActor.run {
                        self.isProcessingFrame = false
                        self.handlePalmDetection(detected)
                    }
                }
            }
        }
    }

    private func beginCountdown() {
        guard state.allowsPalmTrigger else {
            return
        }

        palmDetectedSince = nil
        countdownTask?.cancel()
        state = .countingDown(Self.countdownSeconds)

        countdownTask = Task { [weak self] in
            for seconds in stride(from: Self.countdownSeconds, through: 1, by: -1) {
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    self?.state = .countingDown(seconds)
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self?.beginCapture()
            }
        }
    }

    private func beginCapture() {
        guard captureTask == nil else {
            return
        }

        state = .capturing(0, total: Self.captureCount)

        captureTask = Task { [weak self] in
            guard let self else {
                return
            }

            let batch = await photoCaptureCoordinator.captureBatch(
                count: Self.captureCount,
                using: cameraSession.photoOutput
            ) { [weak self] completedCount in
                Task { @MainActor [weak self] in
                    self?.state = .capturing(completedCount, total: Self.captureCount)
                }
            }

            await MainActor.run {
                self.state = .saving
            }

            let saveResult = await photoLibrarySaver.save(photoData: batch.photoData)
            let failedCount = saveResult.failedCount + batch.failures.count

            await MainActor.run {
                self.captureTask = nil
                if saveResult.savedCount == Self.captureCount {
                    self.state = .completed(savedCount: saveResult.savedCount)
                } else if saveResult.savedCount > 0 {
                    self.state = .completed(savedCount: saveResult.savedCount)
                } else {
                    self.state = .failed("Capture failed (\(failedCount))")
                }
                self.scheduleIdleReset()
            }
        }
    }

    private func scheduleIdleReset() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                guard let self, self.state.isTerminal else {
                    return
                }
                self.state = .idle
            }
        }
    }
}

enum SelfieCaptureState: Equatable {
    case idle
    case detectingPalm
    case countingDown(Int)
    case capturing(Int, total: Int)
    case saving
    case completed(savedCount: Int)
    case failed(String)

    var statusText: String {
        switch self {
        case .idle:
            return "Show your palm to start"
        case .detectingPalm:
            return "Palm detected"
        case let .countingDown(seconds):
            return "\(seconds)"
        case let .capturing(current, total):
            return "\(current)/\(total)"
        case .saving:
            return "Saving"
        case let .completed(savedCount):
            return "Saved \(savedCount) photos"
        case let .failed(message):
            return message
        }
    }

    var allowsPalmTrigger: Bool {
        switch self {
        case .idle, .detectingPalm:
            return true
        case .countingDown, .capturing, .saving, .completed, .failed:
            return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed:
            return true
        case .idle, .detectingPalm, .countingDown, .capturing, .saving:
            return false
        }
    }
}
