//
//  CameraService.swift
//  FlashGuideV2
//

import Foundation

protocol CameraServicing {
    func currentDepthSupportState() -> DepthSupportState
}

struct CameraService: CameraServicing {
    func currentDepthSupportState() -> DepthSupportState {
        .unknown
    }
}
