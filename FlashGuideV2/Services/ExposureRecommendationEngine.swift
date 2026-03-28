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
            ambientMeterValue: sceneInput.ambientMeterValue
        )
        let flashResult = flashCalculator.makeRecommendation(
            cameraBody: cameraBody,
            lens: lens,
            flashUnit: flashUnit,
            subjectDistanceMeters: effectiveDistance,
            ambientPreference: sceneInput.ambientPreference,
            ambientMeterValue: sceneInput.ambientMeterValue
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

        if sceneInput.ambientMeterValue == nil {
            warnings.append("Ambient meter value is missing, so ambient handling used preference-based defaults.")
        }

        if !sceneInput.isDepthAvailable {
            warnings.append("Depth data is unavailable, which reduces confidence in subject distance assumptions.")
        }

        if sceneInput.ambientPreference == .darkerBackground &&
            shutterResult.shutterSpeed == syncSpeed {
            warnings.append("Darker background preference is limited by flash sync speed, so the recommendation stayed at sync.")
        }

        let confidence = ConfidenceScoreCalculator.makeScore(
            hasAmbientMeter: sceneInput.ambientMeterValue != nil,
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
        ambientMeterValue: Double?
    ) -> ShutterRecommendation {
        let shutterSpeed: ShutterSpeedValue
        var reasoning = [
            "Shutter speed started from the camera sync speed of \(syncSpeed.description) to keep flash timing safe."
        ]

        switch ambientPreference {
        case .balanced:
            shutterSpeed = syncSpeed
            reasoning.append("Balanced ambient preference kept the shutter at sync speed.")
        case .darkerBackground:
            shutterSpeed = syncSpeed
            reasoning.append("Darker background preference stayed at sync speed because the flash sync cap cannot be exceeded.")
        case .brighterAmbient:
            shutterSpeed = syncSpeed.slower(byStops: ambientMeterValue == nil ? 1 : 2)
            reasoning.append("Brighter ambient preference slowed the shutter below sync to collect more ambient light.")
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
        ambientPreference: AmbientPreference,
        ambientMeterValue: Double?
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
            ambientPreference: ambientPreference,
            ambientMeterValue: ambientMeterValue
        ) {
            let targetAperture = targetAperture(
                for: lens,
                ambientPreference: ambientPreference
            )
            let targetISO = targetISO(
                for: cameraBody,
                ambientPreference: ambientPreference,
                ambientMeterValue: ambientMeterValue
            )

            return FlashRecommendation(
                aperture: bestCandidate.aperture,
                iso: bestCandidate.iso,
                powerStep: bestCandidate.powerStep,
                warnings: [],
                reasoning: [
                    "Guide number \(ExposureValueFormatter.noDecimal(flashUnit.guideNumber)) at ISO \(referenceISO) was used as the starting flash exposure estimate.",
                    "The engine compared every valid ISO, aperture, and flash power combination instead of pinning ISO to the first legal result.",
                    "It aimed for about f/\(ExposureValueFormatter.oneDecimal(targetAperture)) and ISO \(ExposureValueFormatter.noDecimal(targetISO)) based on the ambient preference, then chose ISO \(bestCandidate.iso) with flash power \(bestCandidate.powerStep.label).",
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
        ambientPreference: AmbientPreference,
        ambientMeterValue: Double?
    ) -> FlashCandidate? {
        guard !candidates.isEmpty else { return nil }

        let targetAperture = targetAperture(for: lens, ambientPreference: ambientPreference)
        let targetISO = targetISO(
            for: cameraBody,
            ambientPreference: ambientPreference,
            ambientMeterValue: ambientMeterValue
        )

        return candidates.min {
            score(
                candidate: $0,
                cameraBody: cameraBody,
                lens: lens,
                targetAperture: targetAperture,
                targetISO: targetISO,
                ambientPreference: ambientPreference
            ) < score(
                candidate: $1,
                cameraBody: cameraBody,
                lens: lens,
                targetAperture: targetAperture,
                targetISO: targetISO,
                ambientPreference: ambientPreference
            )
        }
    }

    private func score(
        candidate: FlashCandidate,
        cameraBody: CameraBody,
        lens: Lens,
        targetAperture: Double,
        targetISO: Double,
        ambientPreference: AmbientPreference
    ) -> Double {
        let aperturePenalty = abs(log2(candidate.aperture / targetAperture)) * 1.8
        let isoPenalty = abs(log2(Double(candidate.iso) / targetISO)) * 1.25
        let powerPenalty = normalizedPowerPenalty(for: candidate.powerStep) * powerPenaltyWeight(for: ambientPreference)
        let apertureEdgePenalty = apertureEdgePenalty(candidate.aperture, lens: lens)
        let maxISOPenalty = candidate.iso == cameraBody.maxISO ? 0.05 : 0

        return aperturePenalty + isoPenalty + powerPenalty + apertureEdgePenalty + maxISOPenalty
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

    private func targetISO(
        for cameraBody: CameraBody,
        ambientPreference: AmbientPreference,
        ambientMeterValue: Double?
    ) -> Double {
        guard cameraBody.maxISO > cameraBody.minISO else {
            return Double(cameraBody.minISO)
        }

        let dynamicRangeStops = log2(Double(cameraBody.maxISO) / Double(cameraBody.minISO))
        let darknessBias = ambientDarknessBias(from: ambientMeterValue)

        let baseBias: Double
        let darknessWeight: Double

        switch ambientPreference {
        case .darkerBackground:
            baseBias = 0.02
            darknessWeight = 0.12
        case .balanced:
            baseBias = 0.10
            darknessWeight = 0.28
        case .brighterAmbient:
            baseBias = 0.28
            darknessWeight = 0.42
        case .freezeMotion:
            baseBias = 0.06
            darknessWeight = 0.18
        }

        let normalizedBias = min(max(baseBias + (darknessBias * darknessWeight), 0), 1)
        return Double(cameraBody.minISO) * pow(2, dynamicRangeStops * normalizedBias)
    }

    private func ambientDarknessBias(from ambientMeterValue: Double?) -> Double {
        guard let ambientMeterValue else { return 0.45 }
        let normalizedBrightness = min(max((ambientMeterValue - 3) / 9, 0), 1)
        return 1 - normalizedBrightness
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
        hasAmbientMeter: Bool,
        hasDepthEstimate: Bool,
        usedManualOverride: Bool,
        isDepthAvailable: Bool,
        warningCount: Int
    ) -> Double {
        var score = 0.94

        if !hasAmbientMeter {
            score -= 0.16
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
