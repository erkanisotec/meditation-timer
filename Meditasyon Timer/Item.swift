//
//  Item.swift
//  Meditasyon Timer
//
//  Created by Erkan Öztürk on 16.02.2025.
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
