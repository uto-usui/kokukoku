//
//  Item.swift
//  Kokukoku
//
//  Created by uto note on 2026/02/24.
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
