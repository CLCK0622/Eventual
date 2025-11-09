//
//  Item.swift
//  Eventual
//
//  Created by Yi Zhong on 11/9/25.
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
