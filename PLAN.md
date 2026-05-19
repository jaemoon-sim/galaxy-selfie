# PLAN

## Goal

iOS용 전면 카메라 셀피 앱을 만든다. 화면 속 인물이 손바닥을 펼쳐 보이면 앱이 이를 인식하고, iPhone 기본 카메라 앱에서 5초 타이머를 실행한 것처럼 5초 카운트다운 후 사진 3장을 연속 촬영하여 iPhone 사진 앱에 저장한다.

## Current Context

- 프로젝트 루트는 `/Users/jmsim/Documents/galaxy-selfie`이다.
- 초기에는 폴더가 비어 있었고 `.git` 저장소가 아니었다.
- 현재는 git 저장소가 초기화되어 있고, SwiftUI 기반 `GalaxySelfie.xcodeproj`, 앱 소스, 테스트, README가 생성되어 있다.
- 로컬 개발 환경:
  - `xcodebuild -version`: Xcode 26.4.1, Build version 17E202
  - 사용 가능한 시뮬레이터: iOS 26.4 계열 iPhone/iPad 시뮬레이터
- 시뮬레이터는 실제 전면 카메라 입력을 제공하지 않으므로, 빌드/일부 UI 검증은 시뮬레이터에서 가능하지만 손바닥 인식 및 사진 저장 end-to-end 검증은 실제 iPhone에서 수행해야 한다.
- 참고한 공식 문서:
  - Samsung Galaxy Camera settings: `Show palm`은 손바닥을 보이면 셀피를 찍는 Shooting method로 설명된다. https://www.samsung.com/us/support/answer/ANS10001353/
  - Samsung Show Palm guide: Camera settings > Shooting methods > Show Palm 활성화 후 손바닥으로 셀피를 촬영한다. https://www.samsung.com/levant/support/mobile-devices/how-do-i-take-selfies-using-show-palm-on-my-samsung-phone/
  - Apple iPhone Camera timer: Timer에서 3s, 5s, 10s를 선택하고 Shutter를 누르면 타이머가 시작된다. https://support.apple.com/en-ca/guide/iphone/iph3dc593597/ios
  - Apple iPhone Burst: 전면/후면 카메라 모두 Burst photos를 촬영할 수 있다. https://support.apple.com/en-mide/guide/iphone/ipha42c55cd0/ios
  - Apple Vision `VNDetectHumanHandPoseRequest`: 이미지에서 손 포즈를 감지한다. https://developer.apple.com/documentation/vision/vndetecthumanhandposerequest
  - Apple AVFoundation `AVCapturePhotoOutput`: still photo capture workflow를 제공한다. https://developer.apple.com/documentation/avfoundation/avcapturephotooutput

## Decisions

- 새 네이티브 iOS 앱으로 만든다.
- UI 프레임워크는 SwiftUI를 기본으로 사용한다.
- 카메라 파이프라인은 AVFoundation을 사용한다.
- 손 포즈 인식은 Apple Vision의 `VNDetectHumanHandPoseRequest`를 사용한다.
- 타깃 최소 iOS 버전은 `iOS 17+`로 잡는다.
- 전면 카메라만 지원한다.
- 손바닥이 1초 동안 안정적으로 감지되면 트리거한다.
- 트리거 후 5초 카운트다운을 시작한다.
- 카운트다운 종료 후 사진 3장을 연속 촬영한다.
- 촬영된 사진은 앱 내부 선택 화면 없이 iPhone 사진 앱에 자동 저장한다.
- 1차 버전 범위는 전면 카메라 셀피, 손바닥 트리거, 5초 카운트다운, 3장 연속 촬영, 사진 앱 저장까지로 제한한다.

## Assumptions

- 앱 이름은 폴더명을 따라 `GalaxySelfie`로 둔다. 사용자가 원하면 이후 표시 이름만 쉽게 바꿀 수 있다.
- 번들 식별자는 임시로 `com.jmsim.galaxyselfie`를 사용한다. 실제 배포 전 Apple Developer Team/Bundle ID에 맞게 조정한다.
- 연속 촬영은 Apple 기본 카메라의 Burst 앨범 UI를 완전히 복제하지 않고, AVFoundation으로 3장의 개별 사진을 빠르게 촬영해 Photos에 저장하는 방식으로 구현한다.
- `VNDetectHumanHandPoseRequest`는 "손 포즈 키포인트"를 제공하지만 "손바닥이 카메라를 향함"이라는 의미를 직접 반환하지 않는다. 따라서 초기 버전에서는 손목/손가락 관절 좌표와 confidence를 이용해 열린 손 모양을 판정한다.
- 손바닥 트리거는 한 번 시작되면 카운트다운/촬영이 끝날 때까지 재트리거하지 않는다.
- 촬영 중 사용자가 화면의 취소 버튼을 누르면 카운트다운은 취소 가능하게 한다. 이미 시작된 개별 사진 저장은 안전하게 완료하거나 실패 상태를 표시한다.
- 음성 안내, 필터, 보정, 공유, 앱 내부 갤러리, 사진 선택/삭제 UI는 1차 버전에 포함하지 않는다.

## Scope

### In Scope

- 빈 폴더에 SwiftUI 기반 iOS Xcode 프로젝트 생성
- 전면 카메라 권한 요청 및 프리뷰 표시
- Photos 저장 권한 요청 및 저장 처리
- 전면 카메라 프레임을 Vision으로 분석하는 실시간 손 포즈 감지
- 열린 손바닥 판정 로직
- 1초 안정 감지 debouncing
- 5초 카운트다운 UI
- 카운트다운 완료 후 3장 연속 촬영
- 촬영 진행/완료/실패 상태 표시
- 기본적인 단위 테스트 가능한 손바닥 판정 로직 분리
- 실제 iPhone 수동 검증 절차 문서화

### Out of Scope

- 후면 카메라 지원
- 비디오 촬영
- 필터, 얼굴 보정, 뷰티 효과, AR 효과
- 앱 내부 사진 갤러리, 선택, 편집, 삭제, 공유 기능
- iCloud 동기화 상태 제어
- Apple 기본 카메라 앱의 전체 UI 복제
- App Store 배포, 코드 서명 자동화, CI/CD 구축

## Implementation Plan

1. Xcode 프로젝트를 생성한다.
   - SwiftUI App lifecycle 사용
   - Product name: `GalaxySelfie`
   - Organization identifier: `com.jmsim`
   - Minimum deployment target: iOS 17.0
   - Swift 테스트 타깃 포함

2. 권한과 `Info.plist`를 설정한다.
   - `NSCameraUsageDescription`: 전면 카메라로 셀피를 촬영하기 위해 필요
   - `NSPhotoLibraryAddUsageDescription`: 촬영한 사진을 사진 앱에 저장하기 위해 필요
   - Photos는 저장만 필요하므로 가능하면 add-only 권한 흐름을 사용한다.

3. 카메라 세션 계층을 만든다.
   - `AVCaptureSession` 또는 `AVCaptureMultiCamSession`이 아닌 일반 `AVCaptureSession` 사용
   - 전면 `AVCaptureDevice` 선택
   - `AVCaptureVideoPreviewLayer`를 SwiftUI에서 표시하기 위한 `UIViewRepresentable` 작성
   - `AVCaptureVideoDataOutput`으로 Vision 분석용 프레임 제공
   - `AVCapturePhotoOutput`으로 사진 촬영
   - session start/stop은 background queue에서 수행하고 UI 상태 변경은 MainActor에서 처리

4. 손바닥 감지 계층을 만든다.
   - `VNDetectHumanHandPoseRequest.maximumHandCount`는 2로 둔다.
   - Vision 요청은 모든 프레임이 아니라 5-10fps 정도로 throttle하여 배터리/발열을 줄인다.
   - 전면 카메라 orientation/mirroring을 고려해 `VNImageRequestHandler` orientation을 올바르게 전달한다.
   - confidence threshold는 초기값 `0.35` 이상으로 시작하고 실제 기기 테스트로 조정한다.
   - 열린 손 판정:
     - 손목과 주요 손가락 관절 keypoint가 충분히 감지되어야 한다.
     - 최소 4개 손가락의 tip이 해당 finger base/PIP보다 손목에서 더 멀어야 한다.
     - 손가락 tip들이 서로 너무 뭉쳐 있지 않아야 한다.
     - 엄지는 보조 신호로 사용하고, 검지/중지/약지/소지 확장을 우선한다.
   - 단위 테스트를 위해 Vision observation 자체가 아니라 정규화된 keypoint 모델을 입력받는 순수 판정 함수로 분리한다.

5. 트리거 상태 머신을 구현한다.
   - 상태 예시: `idle`, `detectingPalm`, `countingDown`, `capturing`, `saving`, `completed`, `failed`
   - `idle`에서 열린 손바닥이 감지되면 안정 감지 타이머를 시작한다.
   - 열린 손바닥이 1초 연속 유지되면 `countingDown`으로 전환한다.
   - 카운트다운 중에는 손바닥이 사라져도 촬영은 계속 진행한다.
   - 카운트다운 중 취소 버튼을 누르면 `idle`로 돌아간다.
   - 촬영/저장 중에는 중복 트리거를 막는다.

6. 카운트다운 UI를 구현한다.
   - 카메라 프리뷰 위에 큰 숫자 `5`, `4`, `3`, `2`, `1`을 표시한다.
   - 손바닥 감지 성공 순간에는 가벼운 시각 피드백을 준다.
   - 촬영 중에는 `1/3`, `2/3`처럼 진행 상태를 표시한다.
   - 완료 후에는 "사진 앱에 저장됨" 수준의 짧은 상태를 표시하고 자동으로 idle로 복귀한다.

7. 3장 연속 촬영을 구현한다.
   - `AVCapturePhotoOutput.capturePhoto(with:delegate:)`를 3회 순차 호출한다.
   - 각 촬영 사이 간격은 초기값 150-250ms 정도로 시작하고, 실제 기기에서 안정성을 보고 조정한다.
   - 빠른 연속 촬영을 우선하되, capture readiness나 delegate callback을 고려해 세션이 밀리지 않게 한다.
   - 각 사진의 `Data`를 수집하고 `PHPhotoLibrary`에 저장한다.
   - 일부 사진 저장 실패 시 전체 실패로 숨기지 말고 몇 장 성공/실패했는지 표시한다.

8. Photos 저장 계층을 만든다.
   - `PHPhotoLibrary.requestAuthorization(for: .addOnly)` 사용 가능 여부를 확인한다.
   - `PHAssetCreationRequest.forAsset().addResource(with:data:options:)`로 사진 저장
   - 권한 거부 시 설정 앱으로 이동하는 안내 UI 제공

9. 테스트를 추가한다.
   - 손바닥 판정 함수에 대해 열린 손, 주먹, 손가락 일부만 편 상태, 낮은 confidence, keypoint 누락 케이스를 테스트한다.
   - 상태 머신 테스트로 1초 안정 감지, 중복 트리거 방지, 카운트다운 취소를 검증한다.
   - AVFoundation/Vision/Photos 실제 통합은 단위 테스트보다 실제 기기 수동 검증에 둔다.

10. 수동 검증 체크리스트를 README 또는 별도 문서에 남긴다.
    - 권한 최초 요청
    - 손바닥 1초 유지 후 카운트다운 시작
    - 카운트다운 중 손을 내려도 촬영 계속
    - 3장 촬영 및 사진 앱 저장
    - 권한 거부/취소/저조도/손 일부 가림/여러 손 등장 상황

## Files and Areas to Inspect or Change

프로젝트 생성 후 예상 파일:

- `GalaxySelfie.xcodeproj`
- `GalaxySelfie/GalaxySelfieApp.swift`
- `GalaxySelfie/ContentView.swift`
- `GalaxySelfie/Camera/CameraPreviewView.swift`
- `GalaxySelfie/Camera/CameraSessionController.swift`
- `GalaxySelfie/Camera/PhotoCaptureCoordinator.swift`
- `GalaxySelfie/Vision/PalmGestureDetector.swift`
- `GalaxySelfie/Vision/HandPoseClassifier.swift`
- `GalaxySelfie/Photos/PhotoLibrarySaver.swift`
- `GalaxySelfie/State/SelfieCaptureViewModel.swift`
- `GalaxySelfie/Resources/Info.plist` 또는 target build settings의 generated plist 설정
- `GalaxySelfieTests/HandPoseClassifierTests.swift`
- `GalaxySelfieTests/SelfieCaptureStateMachineTests.swift`
- `README.md`

## Acceptance Criteria

- 앱 실행 시 전면 카메라 프리뷰가 표시된다.
- 카메라 권한이 없으면 권한 요청 또는 설정 이동 안내가 표시된다.
- 사용자가 전면 카메라 앞에서 손바닥을 펼쳐 1초 유지하면 앱이 손바닥을 인식한다.
- 손바닥 인식 후 5초 카운트다운이 시작된다.
- 카운트다운 중 손바닥이 사라져도 촬영은 취소되지 않는다.
- 카운트다운 완료 후 사진 3장이 연속 촬영된다.
- 촬영된 사진 3장이 iPhone 사진 앱에 저장된다.
- 촬영/저장 중 손바닥이 다시 감지되어도 중복 촬영이 시작되지 않는다.
- 카운트다운 중 사용자가 취소하면 촬영하지 않고 대기 상태로 돌아간다.
- 손바닥이 아닌 주먹, 얼굴, 배경, 손가락 1-2개만 편 포즈는 트리거하지 않는다.
- 손바닥 판정 로직과 상태 머신 로직에 단위 테스트가 있다.

## Validation Plan

빌드 검증:

```sh
xcodebuild -project GalaxySelfie.xcodeproj -scheme GalaxySelfie -destination 'platform=iOS Simulator,name=iPhone 17' build
```

테스트 검증:

```sh
xcodebuild -project GalaxySelfie.xcodeproj -scheme GalaxySelfie -destination 'platform=iOS Simulator,name=iPhone 17' test
```

실제 기기 검증:

- iOS 17 이상 iPhone에 설치한다.
- 최초 실행에서 카메라 권한과 사진 추가 권한을 허용한다.
- 전면 카메라 앞에서 손바닥을 1초 이상 펼친다.
- 5초 카운트다운이 표시되는지 확인한다.
- 카운트다운 후 3장 촬영 진행 상태가 표시되는지 확인한다.
- Photos 앱에서 방금 촬영한 사진 3장이 저장됐는지 확인한다.
- 권한 거부 후 앱 UI가 막히지 않고 안내를 표시하는지 확인한다.
- 저조도, 역광, 손 일부 가림, 두 명 이상 등장, 여러 손 등장 상황에서 오탐/미탐을 기록하고 threshold를 조정한다.

## Risks and Mitigations

- Vision 손 포즈 인식은 조명, 손 크기, 프레임 내 위치, 가림에 민감할 수 있다.
  - 완화: 1초 안정 감지, confidence threshold, 실제 기기 테스트 기반 threshold 조정, 사용자에게 감지 상태 피드백 제공
- `VNDetectHumanHandPoseRequest`만으로 손바닥 방향을 완벽히 알 수 없다.
  - 완화: "열린 손 모양"을 1차 기준으로 삼고, tip spread/손가락 확장/관절 confidence를 조합해 주먹과 일부 손가락 포즈를 배제
- 빠른 3장 촬영은 기기 성능과 `AVCapturePhotoOutput` readiness에 영향을 받을 수 있다.
  - 완화: delegate callback 기반 순차 촬영, 촬영 간격 조정, 실패 장수 표시
- Photos 권한이 거부되면 핵심 저장 흐름이 불가능하다.
  - 완화: add-only 권한 요청, 거부 시 Settings 이동 안내, 권한 상태별 UI 분기
- 시뮬레이터에서는 실제 카메라/Vision 통합 검증이 제한된다.
  - 완화: 순수 로직 단위 테스트와 실제 iPhone 수동 검증을 분리
- Apple 기본 카메라의 Burst 결과물 UI와 완전히 동일한 저장/그룹핑은 공개 API로 재현하기 어렵다.
  - 완화: 3장의 개별 사진을 Photos에 저장하는 것을 1차 요구사항의 완료 기준으로 명시

## Dispatch Status

- `dispatch-plan` 실행 중 세 워커를 `/private/tmp` worktree에 배정했다.
  - `dispatch/tmp-vision-palm`: `/private/tmp/galaxy-selfie-dispatch-vision`
  - `dispatch/tmp-camera-photos`: `/private/tmp/galaxy-selfie-dispatch-camera`
  - `dispatch/tmp-ui-state`: `/private/tmp/galaxy-selfie-dispatch-ui`
- 세 워커 모두 장시간 최종 보고 없이 running 상태에 머물러 세션을 중단했다. worktree와 branch는 삭제하지 않고 보존했다.
- Vision worker가 남긴 미커밋 `HandPoseClassifier` 일부 구현은 main worktree에서 검토 후 수동 반영했다.
- Camera/Photos/UI/State 구현은 main worktree에서 통합 완료했다.
- 시뮬레이터 테스트는 통과했다.
- 실제 전면 카메라 입력, Vision 손바닥 인식 품질, Photos 저장은 실제 iPhone에서 추가 검증해야 한다.

## Open Questions

None.
