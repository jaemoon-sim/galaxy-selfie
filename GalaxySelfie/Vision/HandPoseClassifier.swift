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
        guard let wrist = confidentPoint(.wrist, in: pose) else {
            return false
        }

        let fingerSpecs: [FingerSpec] = [
            FingerSpec(base: .thumbCMC, middle: .thumbMP, tip: .thumbTip),
            FingerSpec(base: .indexMCP, middle: .indexPIP, tip: .indexTip),
            FingerSpec(base: .middleMCP, middle: .middlePIP, tip: .middleTip),
            FingerSpec(base: .ringMCP, middle: .ringPIP, tip: .ringTip),
            FingerSpec(base: .littleMCP, middle: .littlePIP, tip: .littleTip)
        ]

        let scale = palmScale(from: pose, wrist: wrist, fingerSpecs: fingerSpecs)
        guard scale > 0 else {
            return false
        }

        let extendedTips = fingerSpecs.compactMap { spec -> (joint: HandJoint, point: CGPoint)? in
            guard
                let base = confidentPoint(spec.base, in: pose),
                let middle = confidentPoint(spec.middle, in: pose),
                let tip = confidentPoint(spec.tip, in: pose)
            else {
                return nil
            }

            let tipDistance = distance(tip, wrist)
            let middleDistance = distance(middle, wrist)
            let baseDistance = distance(base, wrist)
            let extensionMargin = scale * 0.18

            guard
                tipDistance > middleDistance + extensionMargin,
                tipDistance > baseDistance + extensionMargin
            else {
                return nil
            }

            return (spec.tip, tip)
        }

        guard extendedTips.count >= 4 else {
            return false
        }

        let nonThumbTips = extendedTips
            .filter { $0.joint != .thumbTip }
            .map(\.point)

        guard nonThumbTips.count >= 3 else {
            return false
        }

        return hasSpreadFingertips(nonThumbTips, scale: scale)
    }

    private struct FingerSpec {
        var base: HandJoint
        var middle: HandJoint
        var tip: HandJoint
    }

    private func confidentPoint(_ joint: HandJoint, in pose: HandPose) -> CGPoint? {
        guard let point = pose[joint], point.confidence >= confidenceThreshold else {
            return nil
        }
        return point.location
    }

    private func palmScale(from pose: HandPose, wrist: CGPoint, fingerSpecs: [FingerSpec]) -> CGFloat {
        let baseDistances = fingerSpecs.compactMap { spec -> CGFloat? in
            guard let base = confidentPoint(spec.base, in: pose) else {
                return nil
            }
            return distance(base, wrist)
        }

        return baseDistances.max() ?? 0
    }

    private func hasSpreadFingertips(_ tips: [CGPoint], scale: CGFloat) -> Bool {
        var largestDistance: CGFloat = 0
        var nearestNeighborDistances: [CGFloat] = []

        for tip in tips {
            let otherDistances = tips
                .filter { $0 != tip }
                .map { distance(tip, $0) }

            if let nearest = otherDistances.min() {
                nearestNeighborDistances.append(nearest)
            }

            if let farthest = otherDistances.max() {
                largestDistance = max(largestDistance, farthest)
            }
        }

        guard !nearestNeighborDistances.isEmpty else {
            return false
        }

        let averageNearestNeighbor = nearestNeighborDistances.reduce(0, +) / CGFloat(nearestNeighborDistances.count)
        return largestDistance >= scale * 0.9 && averageNearestNeighbor >= scale * 0.25
    }

    private func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}
