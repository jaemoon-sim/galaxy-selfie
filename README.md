# GalaxySelfie

전면 카메라 셀피 앱 프로토타입입니다. 화면 속 사용자가 손바닥을 펼치면 앱이 손바닥 포즈를 인식하고, iPhone 기본 카메라 앱의 타이머 촬영처럼 5초 카운트다운 후 사진을 연속 촬영합니다.

## 현재 상태

- 전면 카메라 프리뷰 구현 완료
- Vision 기반 손 포즈 감지 구현 완료
- 열린 손바닥 1초 유지 시 촬영 트리거 구현 완료
- 5초 카운트다운 구현 완료
- 3장 연속 촬영 구현 완료
- 사진 앱 저장 구현 완료
- 실기기에서 손바닥 인식 동작 확인 완료

## 동작 흐름

1. 앱을 실행하면 전면 카메라 프리뷰가 표시됩니다.
2. 사용자가 손바닥을 펼친 상태를 약 1초 유지합니다.
3. 앱이 열린 손바닥을 인식하면 5초 카운트다운을 시작합니다.
4. 카운트다운이 끝나면 사진 3장을 순차 촬영합니다.
5. 촬영된 사진은 iPhone 사진 앱에 저장됩니다.

## 구현 메모

- 카메라: `AVFoundation`
- 손바닥 인식: `Vision`의 `VNDetectHumanHandPoseRequest`
- 저장: `Photos` 프레임워크의 add-only 권한과 `PHAssetCreationRequest`
- 상태 관리: `SelfieCaptureViewModel`
- 열린 손바닥 판정: 손목, 손가락 관절 confidence, 손가락 확장 상태, 손가락 끝 spread를 조합한 휴리스틱
- 중복 트리거 방지: 열린 손바닥이 1초 동안 유지될 때만 촬영 플로우 시작

## 주요 파일

- `GalaxySelfie/ContentView.swift`: 카메라 프리뷰와 촬영 상태 UI
- `GalaxySelfie/Camera/CameraSessionController.swift`: 전면 카메라 세션 관리
- `GalaxySelfie/Camera/PhotoCaptureCoordinator.swift`: 3장 연속 촬영 조율
- `GalaxySelfie/Vision/PalmGestureDetector.swift`: 카메라 프레임을 Vision 손 포즈 요청으로 분석
- `GalaxySelfie/Vision/HandPoseClassifier.swift`: 열린 손바닥 판정 로직
- `GalaxySelfie/Photos/PhotoLibrarySaver.swift`: 사진 앱 저장
- `GalaxySelfie/State/SelfieCaptureViewModel.swift`: 1초 유지, 5초 타이머, 촬영 상태 전이
- `GalaxySelfieTests/`: 손바닥 판정과 상태 머신 테스트

## 빌드와 테스트

시뮬레이터 빌드:

```sh
xcodebuild -project GalaxySelfie.xcodeproj -scheme GalaxySelfie -destination 'platform=iOS Simulator,name=iPhone 17' build
```

시뮬레이터 테스트:

```sh
xcodebuild -project GalaxySelfie.xcodeproj -scheme GalaxySelfie -destination 'platform=iOS Simulator,name=iPhone 17' test
```

실기기 빌드:

```sh
xcodebuild \
  -project GalaxySelfie.xcodeproj \
  -scheme GalaxySelfie \
  -destination 'id=<DEVICE_ID>' \
  -derivedDataPath /private/tmp/galaxy-selfie-deriveddata-device \
  -allowProvisioningUpdates \
  build
```

실기기 설치:

```sh
xcrun devicectl device install app \
  --device <DEVICE_ID> \
  /private/tmp/galaxy-selfie-deriveddata-device/Build/Products/Debug-iphoneos/GalaxySelfie.app
```

실기기 실행:

```sh
xcrun devicectl device process launch \
  --device <DEVICE_ID> \
  --terminate-existing \
  com.jmsim.galaxyselfie
```

`<DEVICE_ID>`는 `xcrun devicectl list devices` 또는 Xcode의 Devices and Simulators 화면에서 확인합니다.

## 검증 결과

- 시뮬레이터 테스트 통과
- 시뮬레이터에서 앱 설치와 실행 확인
- 시뮬레이터는 실제 전면 카메라가 없어 카메라 프리뷰와 손바닥 인식의 E2E 검증은 불가
- iPhone 14 Pro 실기기에서 빌드, 설치, 실행 성공
- 실기기에서 손바닥 인식 동작 확인 완료

## 실기기 테스트 체크리스트

1. 앱 실행 후 카메라 권한을 허용합니다.
2. 사진 앱 add-only 저장 권한을 허용합니다.
3. 전면 카메라 앞에서 손바닥을 펼친 상태를 1초 이상 유지합니다.
4. 5초 카운트다운이 시작되는지 확인합니다.
5. 카운트다운 후 3장이 촬영되는지 확인합니다.
6. 사진 앱에 촬영 결과가 저장되는지 확인합니다.
7. 주먹, 반쯤 접힌 손, 어두운 조명에서 오인식이 과도하지 않은지 확인합니다.

## 개발 환경 메모

- 최소 iOS 버전: iOS 17.0
- 번들 ID: `com.jmsim.galaxyselfie`
- 현재 실기기 서명을 위해 Xcode 프로젝트에 Development Team `S9RCL2N34F`가 설정되어 있습니다.
- 다른 Apple Developer 계정이나 다른 기기에서 빌드할 경우 Xcode Signing & Capabilities에서 Team과 Bundle Identifier를 조정해야 할 수 있습니다.

## 남은 작업 후보

- 다양한 조명, 거리, 손 크기에서 손바닥 판정 임계값 튜닝
- 촬영 중 UI 피드백과 저장 실패 시 에러 메시지 개선
- 3장 촬영 간격을 설정값으로 분리
- App Store 배포용 signing, icon, privacy 문구 정리
