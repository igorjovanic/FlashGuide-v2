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
    var ambientMeterValue: Double?
    var depthEstimate: Double?
    var manualDistanceOverride: Double?
    var isDepthAvailable: Bool
    var isSubjectSelectionLocked: Bool

    static let empty = SceneInput(
        selectedCameraBody: .preview,
        selectedLens: .preview,
        selectedFlashUnit: .preview,
        subjectDistanceMeters: 2.0,
        ambientPreference: .balanced,
        selectedTapPoint: nil,
        ambientMeterValue: nil,
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
        ambientMeterValue: 7.5,
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
            ambientMeterValue: 5.5,
            depthEstimate: 4.2,
            manualDistanceOverride: 3.8,
            isDepthAvailable: true,
            isSubjectSelectionLocked: true
        )
    ]
}
