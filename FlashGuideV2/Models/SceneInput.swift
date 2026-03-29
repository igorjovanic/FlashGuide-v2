//
//  SceneInput.swift
//  FlashGuideV2
//

import CoreGraphics
import Foundation

enum AmbientPreference: String, Codable, CaseIterable, Hashable, Identifiable {
    case balanced
    case darkerBackground
    case brighterAmbient
    case freezeMotion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .balanced:
            "Balanced"
        case .darkerBackground:
            "Darker Background"
        case .brighterAmbient:
            "Brighter Ambient"
        case .freezeMotion:
            "Freeze Motion"
        }
    }
}

struct SceneInput: Equatable, Hashable, Codable {
    var selectedCameraBody: CameraBody
    var selectedLens: Lens
    var selectedFlashUnit: FlashUnit
    var subjectDistanceMeters: Double
    var ambientPreference: AmbientPreference
    var selectedTapPoint: UserTapSelection?
    var ambientEstimate: AmbientSceneEstimate?
    var depthEstimate: Double?
    var manualDistanceOverride: Double?
    var isDepthAvailable: Bool
    var isSubjectSelectionLocked: Bool

    var ambientMeterValue: Double? {
        ambientEstimate?.subjectEV100
    }

    var subjectAmbientEV: Double? {
        ambientEstimate?.subjectEV100
    }

    var backgroundAmbientEV: Double? {
        ambientEstimate?.backgroundEV100
    }

    var ambientContrastEV: Double? {
        ambientEstimate?.ambientContrastEV
    }

    static let empty = SceneInput(
        selectedCameraBody: .preview,
        selectedLens: .preview,
        selectedFlashUnit: .preview,
        subjectDistanceMeters: 2.0,
        ambientPreference: .balanced,
        selectedTapPoint: nil,
        ambientEstimate: nil,
        depthEstimate: nil,
        manualDistanceOverride: nil,
        isDepthAvailable: false,
        isSubjectSelectionLocked: false
    )

    static let preview = SceneInput(
        selectedCameraBody: .preview,
        selectedLens: .preview,
        selectedFlashUnit: .preview,
        subjectDistanceMeters: 2.5,
        ambientPreference: .balanced,
        selectedTapPoint: .preview,
        ambientEstimate: AmbientSceneEstimate(
            subjectEV100: 7.5,
            backgroundEV100: 6.8,
            ambientContrastEV: 0.7,
            subjectBackgroundDeltaEV: 0.7,
            subjectHighlightRatio: 0.05,
            subjectShadowRatio: 0.10
        ),
        depthEstimate: 2.4,
        manualDistanceOverride: nil,
        isDepthAvailable: true,
        isSubjectSelectionLocked: false
    )

    static let mockData: [SceneInput] = [
        .preview,
        SceneInput(
            selectedCameraBody: CameraBody.mockData[1],
            selectedLens: Lens.mockData[1],
            selectedFlashUnit: FlashUnit.mockData[1],
            subjectDistanceMeters: 4.0,
            ambientPreference: .freezeMotion,
            selectedTapPoint: UserTapSelection.mockData[1],
            ambientEstimate: AmbientSceneEstimate(
                subjectEV100: 5.5,
                backgroundEV100: 4.2,
                ambientContrastEV: 1.3,
                subjectBackgroundDeltaEV: 1.3,
                subjectHighlightRatio: 0.02,
                subjectShadowRatio: 0.18
            ),
            depthEstimate: 4.2,
            manualDistanceOverride: 3.8,
            isDepthAvailable: true,
            isSubjectSelectionLocked: true
        )
    ]
}
