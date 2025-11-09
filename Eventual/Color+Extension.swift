//
//  Color+Extension.swift
//  Eventual
//
//  Created by Yi Zhong on 11/9/25.
//

import SwiftUI

extension Color {
    
    // MARK: - Initializer to create a Color from a Hex String
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    // MARK: - Method to convert a Color back into a Hex String
        
    func toHex() -> String? {
        // 1. Get the platform-specific color representation (UIColor or NSColor)
        #if canImport(UIKit)
        typealias PlatformColor = UIColor
        let platformColor = PlatformColor(self)
        #elseif canImport(AppKit)
        typealias PlatformColor = NSColor
        // 2. For NSColor, we must first convert it to a standard RGB color space
        guard let platformColor = PlatformColor(self).usingColorSpace(.sRGB) else {
            return nil // Failed to convert to sRGB
        }
        #else
        return nil // Platform not supported
        #endif
        
        // 3. Get the RGBA components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        #if canImport(UIKit)
        // 4. On UIKit, getRed() returns a Bool indicating success
        guard platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil // Failed to get components
        }
        #elseif canImport(AppKit)
        // 5. On AppKit, getRed() returns Void (it doesn't fail)
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        // 6. Format the components into a Hex string
        let redInt = Int(red * 255.0)
        let greenInt = Int(green * 255.0)
        let blueInt = Int(blue * 255.0)
        
        return String(format: "#%02lX%02lX%02lX", redInt, greenInt, blueInt)
    }
}
