# GalaxySelfie

Native iOS selfie camera prototype. The intended flow is:

1. Show the front camera preview.
2. Detect an open palm held for 1 second.
3. Start a 5 second countdown.
4. Capture 10 photos in sequence.
5. Save the photos to the iPhone Photos app.

## Build

```sh
xcodebuild -project GalaxySelfie.xcodeproj -scheme GalaxySelfie -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Test

```sh
xcodebuild -project GalaxySelfie.xcodeproj -scheme GalaxySelfie -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Device Validation

Simulator builds verify compilation and pure logic. End-to-end camera, Vision, and Photos behavior must be tested on a physical iPhone.

- Launch on an iPhone running iOS 17 or later.
- Allow camera access.
- Allow add-only Photos access.
- Hold an open palm toward the front camera for at least 1 second.
- Confirm the countdown runs from 5 to 1.
- Confirm 10 photos are captured and saved to Photos.
- Check that a fist, partially open hand, or low-confidence hand pose does not trigger capture.
