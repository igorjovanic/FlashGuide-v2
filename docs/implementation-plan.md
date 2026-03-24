# FlashAssist MVP Implementation Plan

## 1. Current Repository Baseline

The current project is still the default Xcode SwiftUI scaffold:

- App target: `FlashGuideV2`
- Unit test target: `FlashGuideV2Tests`
- UI test target: `FlashGuideV2UITests`
- Main app files: `FlashGuideV2App.swift`, `ContentView.swift`, `Item.swift`
- Current architecture: single-screen sample app using `SwiftData`
- Gap to MVP: none of the product-specific capture, calculation, camera, depth, or recommendation flows exist yet

This means the MVP should be implemented as a clean replacement of the scaffold, not as an incremental extension of the sample list app.

## 2. MVP Goal

Ship a first usable iPhone app that helps a photographer with a manual flash get a credible starting exposure recommendation by combining:

- user camera constraints
- lens constraints
- flash power data
- subject distance
- ambient brightness estimated from the live camera feed
- tapped subject point on preview

The MVP should produce:

- recommended shutter speed
- recommended aperture
- recommended ISO
- recommended flash power
- reasoning text
- confidence/warnings

The MVP must enforce the product rules from `AGENTS.md`, especially sync speed, ISO bounds, aperture bounds, tap-to-subject selection, and graceful fallback when depth is unavailable.

## 3. MVP Scope Boundary

### In scope

- iPhone-only SwiftUI app
- onboarding/configuration for one camera/lens/flash setup
- live camera preview with tap-to-select subject region
- ambient estimation from preview image
- optional depth-assisted distance estimation on supported devices
- manual distance entry fallback
- deterministic recommendation engine
- recommendation summary screen/card with warnings
- local persistence for saved gear profile and last-used values
- unit tests for calculation logic
- basic UI tests for critical happy path

### Out of scope for MVP

- iPad-specific layout work
- multiple saved gear kits with sync/import/export
- advanced scene metering modes
- image capture or photo library workflows
- Apple Watch / macOS / visionOS support
- LiDAR-only features
- cloud sync
- polished tutorial system
- localization beyond English

## 4. Product Assumptions For MVP

These assumptions keep the first version implementable and testable:

- Ambient estimation will be approximate and based on a sampled preview region, not a full professional meter.
- Recommendation logic will optimize for a safe, explainable starting point, not perfect physical simulation.
- Subject distance can come from either:
  - depth estimate near the tapped point, or
  - explicit manual entry
- Flash capability will be modeled using guide number plus supported power levels rather than brand-specific flash protocols.
- The app should recommend only settings the user can actually dial in from the configured ranges.

## 5. Proposed App Architecture

Use a modular SwiftUI architecture with clear separation between UI, capture services, domain logic, and persistence.

### App layers

- `App`
  - app entry, dependency wiring, root navigation
- `Features`
  - user-facing flows and view models
- `Domain`
  - recommendation engine, constraints, data models, validation
- `Services`
  - camera preview, ambient sampling, depth sampling, persistence adapters
- `Shared`
  - reusable UI components, formatting, utilities
- `Tests`
  - engine tests, mapper tests, service fakes, UI smoke tests

### State management approach

- Use SwiftUI + `@Observable` view models for feature state.
- Keep AVFoundation code out of views.
- Inject service protocols into view models for testability.
- Make the recommendation engine pure and synchronous wherever possible.

### Persistence approach

For MVP, prefer a lightweight local persistence layer using `UserDefaults` or a small file-backed store for:

- camera profile
- lens profile
- flash profile
- last manual distance
- last chosen power level

Do not keep the scaffold `SwiftData` model unless a real persisted domain model justifies it. Right now it adds noise and no product value.

## 6. Proposed Project Structure

Replace the sample files with a structure closer to this:

```text
FlashGuideV2/
  App/
    FlashAssistApp.swift
    AppCoordinator.swift
    AppDependencies.swift
  Features/
    Setup/
      SetupView.swift
      SetupViewModel.swift
    Meter/
      MeterView.swift
      MeterViewModel.swift
      CameraPreviewView.swift
      SubjectSelectionOverlay.swift
    Recommendation/
      RecommendationCardView.swift
      RecommendationDetailsView.swift
  Domain/
    Models/
      CameraProfile.swift
      LensProfile.swift
      FlashProfile.swift
      ExposureRecommendation.swift
      MeteringSample.swift
      SubjectDistance.swift
    Engine/
      ExposureRecommendationEngine.swift
      ExposureConstraintSolver.swift
      AmbientEstimateMapper.swift
    Validation/
      ProfileValidators.swift
  Services/
    Camera/
      CameraSessionController.swift
      CameraFrameAnalyzer.swift
      DepthEstimator.swift
      SubjectRegionSampler.swift
    Persistence/
      SettingsStore.swift
      LocalProfileStore.swift
  Shared/
    Components/
    Formatting/
    Extensions/
```

This can be introduced inside the existing single app target first. Splitting into frameworks/modules is not necessary for MVP.

## 7. Core Domain Model Plan

Define the MVP around a small, explicit set of domain types.

### Gear configuration

- `CameraProfile`
  - sync speed
  - ISO min/max
  - preferred ISO step list or increment behavior
- `LensProfile`
  - aperture min/max
  - optionally supported full/third-stop aperture values
- `FlashProfile`
  - guide number reference
  - guide number reference ISO
  - guide number reference zoom assumption if needed
  - available power levels, ordered from full to minimum

### Live metering inputs

- `MeteringSample`
  - ambient brightness estimate
  - confidence
  - sampled timestamp
  - tapped subject point normalized to preview
  - sampled region metadata
- `SubjectDistance`
  - source: `.depth` or `.manual`
  - meters
  - confidence

### Output

- `ExposureRecommendation`
  - shutter speed
  - aperture
  - ISO
  - flash power
  - reasoning lines
  - warnings
  - confidence score

## 8. MVP User Flow

### Step 1: First launch setup

Build a guided setup screen where the user enters:

- camera sync speed
- camera ISO minimum and maximum
- lens aperture minimum and maximum
- flash guide number
- flash supported power levels

Validation should block impossible values and explain corrections.

### Step 2: Live metering screen

Main operational screen should show:

- live camera preview
- tap target/reticle on selected subject point
- ambient estimation status
- depth availability status
- distance source badge: `Depth` or `Manual`
- manual distance input when depth is missing or overridden
- button to generate/update recommendation

### Step 3: Recommendation presentation

Display a prominent result card with:

- shutter speed
- aperture
- ISO
- flash power
- short reasoning
- warnings such as:
  - sync speed cap applied
  - ISO or aperture hit limit
  - low confidence ambient reading
  - depth unavailable, manual distance used

## 9. Camera And Metering Implementation Plan

### Camera preview

Implement an AVFoundation-based camera session that:

- requests camera permission
- provides a live preview layer bridged into SwiftUI
- streams sample buffers for analysis
- supports tap coordinate mapping from SwiftUI space to capture buffer space

### Ambient estimation

For MVP, ambient estimation should be simple and stable:

- sample luminance from a small region around the tapped point
- smooth readings over a short rolling window
- convert sampled brightness into an internal ambient score or approximate EV bucket
- expose a confidence value based on region size, variance, and recency

Do not overfit the first version to absolute EV accuracy. A stable relative estimate is more important.

### Subject selection

Tap on preview should:

- set the active subject point
- redraw the reticle
- update the analysis region
- trigger a fresh ambient estimate
- request depth-based distance if available

### Depth support

Depth is an enhancement, not a dependency:

- check device/camera format support for depth data
- when available, sample depth around the tapped point
- reject noisy or missing depth values
- expose confidence and fallback reason

If depth fails or is unsupported:

- keep the preview flow working
- prompt for manual distance entry

## 10. Exposure Recommendation Engine Plan

This is the core of the MVP and should be implemented as a pure domain service.

### Inputs to engine

- camera profile
- lens profile
- flash profile
- subject distance
- ambient estimate
- optional user preference such as:
  - favor lower ISO
  - favor wider aperture
  - favor darker ambient background

For MVP, keep preferences minimal or omit them entirely.

### Engine responsibilities

- derive candidate exposure combinations
- enforce sync speed limit
- enforce ISO and aperture bounds
- account for flash power levels available on the flash
- balance ambient and flash into a plausible starting point
- pick the best recommendation
- generate warnings and reasoning

### Suggested solving strategy

Implement a deterministic multi-step solver:

1. Normalize the flash model to a comparable guide-number basis.
2. Estimate flash exposure feasibility for each power level at the subject distance.
3. Generate candidate apertures within the lens range.
4. Generate candidate ISOs within the camera range.
5. Clamp shutter speed at or below sync speed.
6. Score candidates by:
   - whether flash exposure is feasible
   - how close ambient sits to a target background brightness
   - preference for moderate ISO and non-extreme aperture
7. Return highest scoring valid candidate.

### Rules to encode explicitly

- Never exceed sync speed.
- Never recommend ISO outside configured min/max.
- Never recommend aperture outside configured min/max.
- If depth confidence is low, lower overall confidence and add warning.
- If no strong candidate exists, still return the safest bounded recommendation plus a warning that it may require adjustment.

## 11. SwiftUI Screen Plan

### Root navigation

For MVP, use a simple root flow:

- if no valid profile exists -> `SetupView`
- else -> `MeterView`

From `MeterView`, present recommendation inline or via sheet/navigation push.

### SetupView

Responsibilities:

- gear configuration form
- inline validation
- save and continue action

### MeterView

Responsibilities:

- camera permission handling
- preview display
- tap-to-select subject
- distance source display
- manual distance fallback
- ambient readout
- trigger recommendation

### RecommendationDetailsView

Responsibilities:

- formatted exposure output
- reasoning text
- confidence/warning presentation
- quick action to return and adjust

## 12. Testing Plan

Testing needs to focus on the parts most likely to regress.

### Unit tests

Add deterministic tests for:

- sync speed clamping
- ISO min/max clamping
- aperture min/max clamping
- flash power level selection
- low-confidence depth fallback behavior
- engine output for representative scenarios:
  - bright outdoor fill
  - indoor ambient low light
  - subject far enough to require wider aperture/higher ISO

### Service tests with fakes

- camera permission state mapping
- ambient estimation smoothing behavior
- depth unsupported fallback to manual mode

### UI tests

Add a minimal happy-path suite:

- app launches into setup on first run
- valid setup transitions to meter screen
- meter screen supports manual distance mode
- recommendation view shows required fields

## 13. Implementation Sequence

### Phase 1: Re-baseline the app

- Remove the sample `SwiftData` item-list flow.
- Rename app-facing concepts from `FlashGuideV2` sample scaffolding toward `FlashAssist` where appropriate in code and UI.
- Keep the existing Xcode targets but clean the source tree.
- Add camera usage description and any other required privacy strings.
- Restrict the MVP target to iPhone-first behavior even if the project currently has broader platform defaults.

### Phase 2: Build domain and validation layer

- Add gear profile models.
- Add input validation.
- Add recommendation output model.
- Implement the pure recommendation engine with tests before UI integration.

### Phase 3: Build persistence and setup flow

- Implement local profile storage.
- Build `SetupView` and `SetupViewModel`.
- Load persisted values at app start.

### Phase 4: Build camera and metering infrastructure

- Implement AVFoundation session controller.
- Bridge preview to SwiftUI.
- Add tap point mapping.
- Add ambient region sampling.
- Add optional depth estimation and manual fallback.

### Phase 5: Build meter and recommendation UI

- Build `MeterView`.
- Connect live metering state to the recommendation engine.
- Render recommendation card/details and warnings.

### Phase 6: Harden MVP

- Add UI tests.
- Improve error states and permission messaging.
- Verify on at least:
  - simulator without depth
  - physical iPhone with camera
  - physical iPhone with depth-capable camera if available

## 14. Concrete File Change Plan

When implementation starts, the first code pass should likely:

- replace `FlashGuideV2App.swift`
- replace `ContentView.swift`
- remove `Item.swift`
- add new folders under the app target for `App`, `Features`, `Domain`, `Services`, and `Shared`
- expand `FlashGuideV2Tests` from placeholder tests into domain-engine tests
- update `project.pbxproj` settings only as needed for permissions/platform cleanup

## 15. Risks And Mitigations

### Risk: Ambient estimation is too noisy

Mitigation:

- use rolling smoothing
- sample only around tapped region
- expose low-confidence warnings instead of pretending certainty

### Risk: Depth data support varies by device

Mitigation:

- make manual distance a first-class path
- treat depth only as an enhancement

### Risk: Recommendation feels arbitrary

Mitigation:

- keep engine deterministic
- generate reasoning text from explicit rule decisions
- test representative exposure scenarios

### Risk: AVFoundation complexity leaks into SwiftUI

Mitigation:

- isolate capture logic behind services/protocols
- keep view models platform-aware but testable

## 16. Definition Of Done For MVP

The MVP is complete when all of the following are true:

- user can configure camera, lens, and flash constraints
- user sees a live camera preview
- user can tap the subject on preview
- app uses tapped region for ambient estimation
- app uses depth when available and manual distance when not
- app returns bounded recommendations for shutter, aperture, ISO, and flash power
- recommendation includes reasoning and warnings
- core calculation logic is covered by unit tests
- basic setup-to-recommendation user flow is covered by UI tests
- sample scaffold code is fully removed from the product flow

## 17. Recommended First Build Slice

The fastest useful vertical slice is:

1. setup screen with persisted gear values
2. manual distance entry only
3. pure recommendation engine
4. recommendation result card
5. then add live camera preview
6. then add tap-region ambient estimation
7. then add depth support

This order reduces risk because the core product value can be validated before the camera/depth stack is fully integrated.
