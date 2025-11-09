// Image+Resizing.swift
import SwiftUI

// We'll use platform-specific types (UIImage/NSImage) for resizing
#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

extension PlatformImage {
    
    // We'll set a max dimension (e.g., 1024 pixels)
    // This keeps us safely under the 2.6M pixel limit
    func resized(toMaxDimension maxDimension: CGFloat) -> PlatformImage? {
        
        #if os(iOS)
        let scale = maxDimension / max(self.size.width, self.size.height)
        guard scale < 1.0 else { return self } // Don't scale up
        
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage

        #elseif os(macOS)
        guard let tiffData = self.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        let scale = maxDimension / max(CGFloat(imageRep.pixelsWide), CGFloat(imageRep.pixelsHigh))
        guard scale < 1.0 else { return self } // Don't scale up

        let newSize = NSSize(
            width: CGFloat(imageRep.pixelsWide) * scale,
            height: CGFloat(imageRep.pixelsHigh) * scale
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: .zero,
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
        #endif
    }
    
    // Helper to get JPEG data
    func toJpegData(compressionQuality: CGFloat = 0.8) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        guard let tiffData = self.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return imageRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }
}
