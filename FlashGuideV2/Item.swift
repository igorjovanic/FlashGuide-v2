//
//  Item.swift
//  FlashGuideV2
//
//  Created by Igor Jovanić on 24. 3. 2026..
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
