import CoreGraphics
import Foundation

struct HandPose: Equatable {
    var points: [HandJoint: HandJointPoint]

    init(points: [HandJoint: HandJointPoint]) {
        self.points = points
    }

    subscript(_ joint: HandJoint) -> HandJointPoint? {
        points[joint]
    }
}

struct HandJointPoint: Equatable {
    var location: CGPoint
    var confidence: Float

    init(x: CGFloat, y: CGFloat, confidence: Float) {
        self.location = CGPoint(x: x, y: y)
        self.confidence = confidence
    }
}

enum HandJoint: Hashable {
    case wrist
    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip
    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip
    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip
    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip
    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip
}

struct HandPoseClassifier {
    var confidenceThreshold: Float = 0.35

    func isOpenPalm(_ pose: HandPose) -> Bool {
        false
    }
}
