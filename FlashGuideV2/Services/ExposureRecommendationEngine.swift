//
//  ExposureRecommendationEngine.swift
//  FlashGuideV2
//

import Foundation

protocol ExposureRecommendationEngine {
    func makeRecommendation(
        cameraBody: CameraBody,
        lens: Lens,
        flashUnit: FlashUnit,
        sceneInput: SceneInput
    ) -> ExposureRecommendation
}

struct DefaultExposureRecommendationEngine: ExposureRecommendationEngine {
    private let shutterCalculator = ShutterRecommendationCalculator()
    private let flashCalculator = FlashExposureCalculator()

    func makeRecommendation(
        cameraBody: CameraBody,
        lens: Lens,
        flashUnit: FlashUnit,
        sceneInput: SceneInput
    ) -> ExposureRecommendation {
        let effectiveDistance = sceneInput.manualDistanceOverride
            ?? sceneInput.depthEstimate
            ?? sceneInput.subjectDistanceMeters

        let syncSpeed = ShutterSpeedValue.parse(cameraBody.flashSyncSpeed) ?? .defaultSync
        let shutterResult = shutterCalculator.makeRecommendation(
            syncSpeed: syncSpeed,
            ambientPreference: sceneInput.ambientPreference,
            ambientEstimate: sceneInput.ambientEstimate
        )
        let flashResult = flashCalculator.makeRecommendation(
            cameraBody: cameraBody,
            lens: lens,
            flashUnit: flashUnit,
            subjectDistanceMeters: effectiveDistance,
            shutterSpeed: shutterResult.shutterSpeed,
            ambientPreference: sceneInput.ambientPreference,
            ambientEstimate: sceneInput.ambientEstimate
        )

        var warnings = flashResult.warnings
        var reasoning = shutterResult.reasoning + flashResult.reasoning

        if sceneInput.manualDistanceOverride != nil {
            reasoning.append("Manual distance override was used as the flash distance input.")
        } else if sceneInput.depthEstimate != nil {
            reasoning.append("Depth estimate was used to refine the flash distance input.")
        } else {
            warnings.append("No depth estimate or manual override was available, so subject distance input was used directly.")
        }

        if sceneInput.ambientEstimate == nil {
            warnings.append("Ambient scene estimate is missing, so ambient handling used preference-based defaults.")
        } else {
            reasoning.append("Ambient metering used the tapped subject area plus a wider background sample to estimate EV100 and contrast.")
            if let sceneKind = sceneInput.ambientEstimate?.sceneKind {
                reasoning.append("The scene was classified as \(sceneKind.displayName), so daylight and night conditions use different ambient targets.")
            }
        }

        if !sceneInput.isDepthAvailable {
            warnings.append("Depth data is unavailable, which reduces confidence in subject distance assumptions.")
        }

        if let ambientEstimate = sceneInput.ambientEstimate {
            if ambientEstimate.subjectBackgroundDeltaEV <= -1.0 {
                warnings.append("The selected subject appears darker than the background, so backlighting may require extra flash compensation.")
            }

            if ambientEstimate.ambientContrastEV >= 2.2 {
                warnings.append("Scene contrast is high, which makes the starting recommendation less certain.")
            }

            if ambientEstimate.subjectHighlightRatio >= 0.20 {
                warnings.append("Bright highlight detail is already present on the subject, so highlight clipping is possible.")
            }

            if ambientEstimate.subjectShadowRatio >= 0.55 {
                warnings.append("The tapped subject area is very dark, which raises noise risk if the recommendation needs more ISO.")
            }
        }

        if sceneInput.ambientPreference == .darkerBackground &&
            shutterResult.shutterSpeed == syncSpeed {
            warnings.append("Darker background preference is limited by flash sync speed, so the recommendation stayed at sync.")
        }

        let confidence = ConfidenceScoreCalculator.makeScore(
            ambientEstimate: sceneInput.ambientEstimate,
            hasDepthEstimate: sceneInput.depthEstimate != nil,
            usedManualOverride: sceneInput.manualDistanceOverride != nil,
            isDepthAvailable: sceneInput.isDepthAvailable,
            warningCount: warnings.count
        )

        return ExposureRecommendation(
            shutterSpeed: shutterResult.shutterSpeed.description,
            aperture: "f/\(ExposureValueFormatter.oneDecimal(flashResult.aperture))",
            iso: "ISO \(flashResult.iso)",
            flashPowerStep: flashResult.powerStep.label,
            confidenceScore: confidence,
            reasoning: reasoning,
            warnings: Array(NSOrderedSet(array: warnings)) as? [String] ?? warnings
        )
    }
}

private struct ShutterRecommendationCalculator {
    func makeRecommendation(
        syncSpeed: ShutterSpeedValue,
        ambientPreference: AmbientPreference,
        ambientEstimate: AmbientSceneEstimate?
    ) -> ShutterRecommendation {
        let shutterSpeed: ShutterSpeedValue
        var reasoning = [
            "Shutter speed started from the camera sync speed of \(syncSpeed.description) to keep flash timing safe."
        ]

        switch ambientPreference {
        case .balanced:
            switch ambientEstimate?.sceneKind {
            case .night:
                shutterSpeed = syncSpeed.slower(byStops: 1)
                reasoning.append("Balanced ambient preference slowed the shutter one stop because the scene reads as night.")
            case .indoorLowLight:
                shutterSpeed = syncSpeed.slower(byStops: 1)
                reasoning.append("Balanced ambient preference slowed the shutter slightly because the scene reads as indoor low light.")
            default:
                shutterSpeed = syncSpeed
                reasoning.append("Balanced ambient preference kept the shutter at sync speed.")
            }
        case .darkerBackground:
            shutterSpeed = syncSpeed
            reasoning.append("Darker background preference stayed at sync speed because the flash sync cap cannot be exceeded.")
        case .brighterAmbient:
            let backgroundEV = ambientEstimate?.backgroundEV100 ?? ambientEstimate?.subjectEV100
            let slowerStops: Int
            switch ambientEstimate?.sceneKind {
            case .night:
                slowerStops = 3
            case .indoorLowLight:
                slowerStops = 2
            default:
                slowerStops = backgroundEV.map { $0 < 4.5 ? 2 : 1 } ?? 1
            }
            shutterSpeed = syncSpeed.slower(byStops: slowerStops)
            reasoning.append("Brighter ambient preference slowed the shutter below sync to preserve more of the metered background light.")
        case .freezeMotion:
            shutterSpeed = syncSpeed
            reasoning.append("Freeze motion preference used the fastest flash-safe shutter speed available.")
        }

        return ShutterRecommendation(shutterSpeed: shutterSpeed, reasoning: reasoning)
    }
}

private struct FlashExposureCalculator {
    func makeRecommendation(
        cameraBody: CameraBody,
        lens: Lens,
        flashUnit: FlashUnit,
        subjectDistanceMeters: Double,
        shutterSpeed: ShutterSpeedValue,
        ambientPreference: AmbientPreference,
        ambientEstimate: AmbientSceneEstimate?
    ) -> FlashRecommendation {
        let isoCandidates = ISOCandidateBuilder.makeCandidates(
            minISO: cameraBody.minISO,
            maxISO: cameraBody.maxISO
        )
        let powerSteps = PowerStep.parseSupportedSteps(flashUnit.supportedPowerSteps)
        let referenceISO = max(flashUnit.guideNumberISOReference, 1)
        var validCandidates: [FlashCandidate] = []

        for iso in isoCandidates {
            let guideNumberAtISO = flashUnit.guideNumber * sqrt(Double(iso) / Double(referenceISO))

            for powerStep in powerSteps.sorted(by: { $0.fraction < $1.fraction }) {
                let effectiveGuideNumber = guideNumberAtISO * sqrt(powerStep.fraction)
                let requiredAperture = effectiveGuideNumber / subjectDistanceMeters

                if requiredAperture >= lens.minAperture && requiredAperture <= lens.maxAperture {
                    validCandidates.append(
                        FlashCandidate(
                            aperture: requiredAperture,
                            iso: iso,
                            powerStep: powerStep
                        )
                    )
                }
            }
        }

        if let bestCandidate = bestCandidate(
            from: validCandidates,
            cameraBody: cameraBody,
            lens: lens,
            shutterSpeed: shutterSpeed,
            ambientPreference: ambientPreference,
            ambientEstimate: ambientEstimate
        ) {
            let targetAperture = targetAperture(
                for: lens,
                ambientPreference: ambientPreference
            )
            let ambientProfile = ambientTargetProfile(
                for: ambientPreference,
                ambientEstimate: ambientEstimate
            )

            return FlashRecommendation(
                aperture: bestCandidate.aperture,
                iso: bestCandidate.iso,
                powerStep: bestCandidate.powerStep,
                warnings: [],
                reasoning: [
                    "Guide number \(ExposureValueFormatter.noDecimal(flashUnit.guideNumber)) at ISO \(referenceISO) was used as the starting flash exposure estimate.",
                    "The engine compared every valid ISO, aperture, flash power, and ambient retention combination instead of pinning ISO to the first legal result.",
                    "It aimed for about f/\(ExposureValueFormatter.oneDecimal(targetAperture)) while holding the subject near \(ambientProfile.subjectOffsetDescription) and the background near \(ambientProfile.backgroundOffsetDescription).",
                    "That led to ISO \(bestCandidate.iso) with flash power \(bestCandidate.powerStep.label) once flash reach and ambient balance were both considered.",
                    "At \(ExposureValueFormatter.oneDecimal(subjectDistanceMeters))m that places the flash exposure near f/\(ExposureValueFormatter.oneDecimal(bestCandidate.aperture))."
                ]
            )
        }

        let lowestPowerStep = powerSteps.min(by: { $0.fraction < $1.fraction }) ?? .full
        let highestPowerStep = powerSteps.max(by: { $0.fraction < $1.fraction }) ?? .full
        let lowestISO = isoCandidates.first ?? cameraBody.minISO
        let highestISO = isoCandidates.last ?? cameraBody.maxISO

        let weakestGuideNumber = flashUnit.guideNumber
            * sqrt(Double(lowestISO) / Double(referenceISO))
            * sqrt(lowestPowerStep.fraction)
        let weakestRequiredAperture = weakestGuideNumber / subjectDistanceMeters

        if weakestRequiredAperture > lens.maxAperture {
            return FlashRecommendation(
                aperture: lens.maxAperture,
                iso: lowestISO,
                powerStep: lowestPowerStep,
                warnings: [
                    "Subject is close enough that the flash may still overpower the scene even at the lowest available power."
                ],
                reasoning: [
                    "The engine reduced flash power before considering any shutter change beyond sync speed.",
                    "Even the weakest flash step still needs more stop-down than the lens allows, so the recommendation is clamped to the narrowest supported aperture."
                ]
            )
        }

        return FlashRecommendation(
            aperture: lens.minAperture,
            iso: highestISO,
            powerStep: highestPowerStep,
            warnings: [
                "The selected flash and lens cannot deliver a clean flash exposure at this distance without exceeding ISO or aperture limits."
            ],
            reasoning: [
                "The engine increased flash power and ISO only as far as the camera and flash allow.",
                "The recommendation is clamped to the widest supported aperture and maximum ISO because the flash is still short of the required exposure."
            ]
        )
    }

    private func bestCandidate(
        from candidates: [FlashCandidate],
        cameraBody: CameraBody,
        lens: Lens,
        shutterSpeed: ShutterSpeedValue,
        ambientPreference: AmbientPreference,
        ambientEstimate: AmbientSceneEstimate?
    ) -> FlashCandidate? {
        guard !candidates.isEmpty else { return nil }

        let targetAperture = targetAperture(for: lens, ambientPreference: ambientPreference)
        let ambientProfile = ambientTargetProfile(
            for: ambientPreference,
            ambientEstimate: ambientEstimate
        )

        return candidates.min {
            score(
                candidate: $0,
                cameraBody: cameraBody,
                lens: lens,
                shutterSpeed: shutterSpeed,
                targetAperture: targetAperture,
                ambientPreference: ambientPreference,
                ambientEstimate: ambientEstimate,
                ambientProfile: ambientProfile
            ) < score(
                candidate: $1,
                cameraBody: cameraBody,
                lens: lens,
                shutterSpeed: shutterSpeed,
                targetAperture: targetAperture,
                ambientPreference: ambientPreference,
                ambientEstimate: ambientEstimate,
                ambientProfile: ambientProfile
            )
        }
    }

    private func score(
        candidate: FlashCandidate,
        cameraBody: CameraBody,
        lens: Lens,
        shutterSpeed: ShutterSpeedValue,
        targetAperture: Double,
        ambientPreference: AmbientPreference,
        ambientEstimate: AmbientSceneEstimate?,
        ambientProfile: AmbientTargetProfile
    ) -> Double {
        let aperturePenalty = abs(log2(candidate.aperture / targetAperture)) * 1.8
        let powerPenalty = normalizedPowerPenalty(for: candidate.powerStep) * powerPenaltyWeight(for: ambientPreference)
        let apertureEdgePenalty = apertureEdgePenalty(candidate.aperture, lens: lens)
        let maxISOPenalty = candidate.iso == cameraBody.maxISO ? 0.10 : 0
        let noisePenalty = noisePenalty(
            iso: candidate.iso,
            cameraBody: cameraBody,
            ambientEstimate: ambientEstimate
        )
        let ambientPenalty = ambientRetentionPenalty(
            candidate: candidate,
            shutterSpeed: shutterSpeed,
            ambientEstimate: ambientEstimate,
            ambientProfile: ambientProfile
        )

        return aperturePenalty + powerPenalty + apertureEdgePenalty + maxISOPenalty + noisePenalty + ambientPenalty
    }

    private func targetAperture(
        for lens: Lens,
        ambientPreference: AmbientPreference
    ) -> Double {
        let midpoint = sqrt(lens.minAperture * lens.maxAperture)

        let preferredValue: Double
        switch ambientPreference {
        case .darkerBackground:
            preferredValue = max(midpoint, 5.6)
        case .balanced:
            preferredValue = min(max(midpoint, 4.0), 5.6)
        case .brighterAmbient:
            preferredValue = min(max(lens.minAperture * 1.4, lens.minAperture), 4.0)
        case .freezeMotion:
            preferredValue = min(max(midpoint, 4.0), 8.0)
        }

        return min(max(preferredValue, lens.minAperture), lens.maxAperture)
    }

    private func ambientTargetProfile(
        for ambientPreference: AmbientPreference,
        ambientEstimate: AmbientSceneEstimate?
    ) -> AmbientTargetProfile {
        let isBacklit = (ambientEstimate?.subjectBackgroundDeltaEV ?? 0) <= -1.0
        let contrast = ambientEstimate?.ambientContrastEV ?? 0
        let sceneKind = ambientEstimate?.sceneKind ?? .indoorLowLight

        switch ambientPreference {
        case .darkerBackground:
            switch sceneKind {
            case .daylight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.4 : -0.7,
                    backgroundOffsetEV: contrast > 1.8 ? -2.2 : -1.8
                )
            case .goldenHour:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.3 : -0.6,
                    backgroundOffsetEV: contrast > 1.8 ? -2.0 : -1.6
                )
            case .indoorLowLight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.5 : -0.8,
                    backgroundOffsetEV: contrast > 1.8 ? -2.6 : -2.2
                )
            case .night:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.2 : -0.5,
                    backgroundOffsetEV: contrast > 1.8 ? -1.6 : -1.2
                )
            }
        case .balanced:
            switch sceneKind {
            case .daylight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.2 : -0.5,
                    backgroundOffsetEV: contrast > 1.8 ? -1.2 : -0.9
                )
            case .goldenHour:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.1 : -0.4,
                    backgroundOffsetEV: contrast > 1.8 ? -1.0 : -0.6
                )
            case .indoorLowLight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.3 : -0.6,
                    backgroundOffsetEV: contrast > 1.8 ? -1.8 : -1.3
                )
            case .night:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? 0.0 : -0.2,
                    backgroundOffsetEV: contrast > 1.8 ? -1.0 : -0.6
                )
            }
        case .brighterAmbient:
            switch sceneKind {
            case .daylight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? 0.0 : -0.1,
                    backgroundOffsetEV: contrast > 1.8 ? -0.6 : -0.3
                )
            case .goldenHour:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? 0.1 : 0.0,
                    backgroundOffsetEV: contrast > 1.8 ? -0.5 : -0.2
                )
            case .indoorLowLight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? 0.0 : -0.2,
                    backgroundOffsetEV: contrast > 1.8 ? -1.1 : -0.6
                )
            case .night:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? 0.2 : 0.1,
                    backgroundOffsetEV: contrast > 1.8 ? -0.3 : 0.0
                )
            }
        case .freezeMotion:
            switch sceneKind {
            case .daylight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.5 : -0.9,
                    backgroundOffsetEV: contrast > 1.8 ? -1.8 : -1.4
                )
            case .goldenHour:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.4 : -0.8,
                    backgroundOffsetEV: contrast > 1.8 ? -1.6 : -1.2
                )
            case .indoorLowLight:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.6 : -1.0,
                    backgroundOffsetEV: contrast > 1.8 ? -2.2 : -1.7
                )
            case .night:
                return AmbientTargetProfile(
                    subjectOffsetEV: isBacklit ? -0.3 : -0.6,
                    backgroundOffsetEV: contrast > 1.8 ? -1.2 : -0.9
                )
            }
        }
    }

    private func ambientRetentionPenalty(
        candidate: FlashCandidate,
        shutterSpeed: ShutterSpeedValue,
        ambientEstimate: AmbientSceneEstimate?,
        ambientProfile: AmbientTargetProfile
    ) -> Double {
        guard let ambientEstimate else { return 0.55 }

        let settingsEV100 = log2((candidate.aperture * candidate.aperture) / shutterSpeed.seconds)
        let settingsEVAtISO = settingsEV100 - log2(Double(candidate.iso) / 100.0)
        let subjectOffset = ambientEstimate.subjectEV100 - settingsEVAtISO
        let backgroundOffset = ambientEstimate.backgroundEV100 - settingsEVAtISO

        let subjectPenalty = abs(subjectOffset - ambientProfile.subjectOffsetEV) * 1.25
        let backgroundPenalty = abs(backgroundOffset - ambientProfile.backgroundOffsetEV) * 0.95
        let highlightGuardPenalty = ambientEstimate.subjectHighlightRatio > 0.15 && subjectOffset > 0 ? subjectOffset * 0.6 : 0

        return subjectPenalty + backgroundPenalty + max(highlightGuardPenalty, 0)
    }

    private func noisePenalty(
        iso: Int,
        cameraBody: CameraBody,
        ambientEstimate: AmbientSceneEstimate?
    ) -> Double {
        guard cameraBody.maxISO > cameraBody.minISO else { return 0 }

        let normalizedISO = min(
            max(
                log2(Double(iso) / Double(cameraBody.minISO))
                    / log2(Double(cameraBody.maxISO) / Double(cameraBody.minISO)),
                0
            ),
            1
        )
        let shadowWeight = ambientEstimate?.subjectShadowRatio ?? 0.20
        return normalizedISO * shadowWeight * 0.7
    }

    private func normalizedPowerPenalty(for powerStep: PowerStep) -> Double {
        guard powerStep.fraction > 0 else { return 1 }
        let usageStops = min(max(-log2(powerStep.fraction), 0), 7)
        return 1 - (usageStops / 7)
    }

    private func powerPenaltyWeight(for ambientPreference: AmbientPreference) -> Double {
        switch ambientPreference {
        case .darkerBackground:
            0.55
        case .balanced:
            0.45
        case .brighterAmbient:
            0.30
        case .freezeMotion:
            0.60
        }
    }

    private func apertureEdgePenalty(_ aperture: Double, lens: Lens) -> Double {
        guard lens.maxAperture > lens.minAperture else { return 0 }
        let normalizedPosition = (aperture - lens.minAperture) / (lens.maxAperture - lens.minAperture)
        let distanceFromCenter = abs(normalizedPosition - 0.5) * 2
        return distanceFromCenter * 0.18
    }
}

private struct ConfidenceScoreCalculator {
    static func makeScore(
        ambientEstimate: AmbientSceneEstimate?,
        hasDepthEstimate: Bool,
        usedManualOverride: Bool,
        isDepthAvailable: Bool,
        warningCount: Int
    ) -> Double {
        var score = 0.94

        if ambientEstimate == nil {
            score -= 0.16
        } else if let ambientEstimate {
            score -= min(max(ambientEstimate.ambientContrastEV - 1.2, 0) * 0.05, 0.16)
            score -= min(ambientEstimate.subjectHighlightRatio * 0.22, 0.12)
            score -= min(ambientEstimate.subjectShadowRatio * 0.18, 0.10)
        }

        if !hasDepthEstimate && !usedManualOverride {
            score -= 0.14
        }

        if !isDepthAvailable {
            score -= 0.10
        }

        score -= min(Double(warningCount) * 0.04, 0.20)
        return min(max(score, 0.25), 0.98)
    }
}

private struct ISOCandidateBuilder {
    static func makeCandidates(minISO: Int, maxISO: Int) -> [Int] {
        guard minISO < maxISO else {
            return [minISO]
        }

        var candidates = [minISO]
        var value = minISO

        while value < maxISO {
            value *= 2
            if value < maxISO {
                candidates.append(value)
            }
        }

        if candidates.last != maxISO {
            candidates.append(maxISO)
        }

        return candidates
    }
}

private struct ShutterRecommendation {
    let shutterSpeed: ShutterSpeedValue
    let reasoning: [String]
}

private struct FlashRecommendation {
    let aperture: Double
    let iso: Int
    let powerStep: PowerStep
    let warnings: [String]
    let reasoning: [String]
}

private struct FlashCandidate {
    let aperture: Double
    let iso: Int
    let powerStep: PowerStep
}

private struct AmbientTargetProfile {
    let subjectOffsetEV: Double
    let backgroundOffsetEV: Double

    var subjectOffsetDescription: String {
        offsetDescription(subjectOffsetEV)
    }

    var backgroundOffsetDescription: String {
        offsetDescription(backgroundOffsetEV)
    }

    private func offsetDescription(_ value: Double) -> String {
        if value == 0 {
            return "metered ambient"
        }

        let roundedValue = ExposureValueFormatter.oneDecimal(abs(value))
        return "\(roundedValue) stop\(abs(value) >= 1.5 ? "s" : "") \(value < 0 ? "under" : "over") ambient"
    }
}

private struct ShutterSpeedValue: Equatable {
    let seconds: Double

    static let defaultSync = ShutterSpeedValue(seconds: 1.0 / 200.0)

    var description: String {
        if seconds >= 1 {
            return "\(Int(seconds.rounded()))s"
        }

        let denominator = Int((1.0 / seconds).rounded())
        return "1/\(denominator)"
    }

    func slower(byStops stops: Int) -> ShutterSpeedValue {
        ShutterSpeedValue(seconds: seconds * pow(2.0, Double(stops)))
    }

    static func parse(_ value: String) -> ShutterSpeedValue? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if let denominatorString = trimmed.split(separator: "/").last,
           trimmed.contains("/"),
           let denominator = Double(denominatorString),
           denominator > 0 {
            return ShutterSpeedValue(seconds: 1.0 / denominator)
        }

        if let seconds = Double(trimmed.replacingOccurrences(of: "s", with: "")), seconds > 0 {
            return ShutterSpeedValue(seconds: seconds)
        }

        return nil
    }
}

private struct PowerStep: Equatable {
    let label: String
    let fraction: Double

    static let full = PowerStep(label: "1/1", fraction: 1.0)

    nonisolated static func parseSupportedSteps(_ rawSteps: [String]) -> [PowerStep] {
        let parsedSteps = rawSteps.compactMap(parse)
        return parsedSteps.isEmpty ? defaultSteps : parsedSteps
    }

    nonisolated private static var defaultSteps: [PowerStep] {
        ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128"].compactMap(parse)
    }

    nonisolated private static func parse(_ rawValue: String) -> PowerStep? {
        let normalized = rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized == "full" {
            return PowerStep(label: "1/1", fraction: 1.0)
        }

        let parts = normalized.split(separator: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator > 0 else {
            return nil
        }

        return PowerStep(label: rawValue, fraction: numerator / denominator)
    }
}

private enum ExposureValueFormatter {
    nonisolated private static var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }

    nonisolated private static var integerFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }

    nonisolated static func oneDecimal(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    nonisolated static func noDecimal(_ value: Double) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}
