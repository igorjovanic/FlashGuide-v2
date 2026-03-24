We are building an iOS app in SwiftUI called FlashAssist.

Purpose:
Help photographers using manual flash units without TTL choose a good starting combination of shutter speed, aperture, ISO, and flash power.

Core inputs:
- camera sync speed
- camera ISO range
- lens aperture range
- flash guide number or equivalent flash power data
- flash power levels
- subject distance
- ambient scene brightness estimate from the iPhone camera
- selected subject point from user tap on preview

Core outputs:
- recommended shutter speed
- recommended aperture
- recommended ISO
- recommended flash power
- reasoning text
- confidence/warnings

Important product rules:
- never recommend shutter speed faster than camera sync speed
- stay inside camera ISO min/max
- stay inside lens aperture min/max
- user can tap on the camera preview to select the subject
- the tapped subject region should be used as the primary area for ambient estimation
- support iPhones that provide AVFoundation depth data
- do not rely on LiDAR-only features
- depth is an enhancement, not a requirement
- if depth is unavailable, app should still work with manual distance entry
- recommendations are starting points, not guaranteed perfect exposure
- architecture should be modular and testable