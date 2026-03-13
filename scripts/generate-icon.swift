#!/usr/bin/env swift
import AppKit

// Hollywood vanity mirror icon — rounded mirror with light bulbs around the frame

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let padding = s * 0.08
    let bounds = CGRect(x: padding, y: padding, width: s - padding * 2, height: s - padding * 2)

    // Background: dark green gradient
    let bgColors = [
        CGColor(red: 0.08, green: 0.12, blue: 0.10, alpha: 1.0),
        CGColor(red: 0.12, green: 0.18, blue: 0.14, alpha: 1.0),
    ]
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: bgColors as CFArray,
                                 locations: [0.0, 1.0])!

    // Rounded square background
    let bgRadius = s * 0.22
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: bgRadius, cornerHeight: bgRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: s/2, y: s),
                           end: CGPoint(x: s/2, y: 0), options: [])

    // Mirror frame (outer rounded rect)
    let frameInset = s * 0.12
    let frameRect = bounds.insetBy(dx: frameInset * 0.4, dy: frameInset * 0.15)
    let frameRadius = s * 0.12
    let framePath = CGPath(roundedRect: frameRect,
                           cornerWidth: frameRadius, cornerHeight: frameRadius, transform: nil)

    // Frame color: warm wood/gold
    ctx.setFillColor(CGColor(red: 0.45, green: 0.32, blue: 0.20, alpha: 1.0))
    ctx.addPath(framePath)
    ctx.fillPath()

    // Inner frame highlight
    let innerFrameRect = frameRect.insetBy(dx: s * 0.015, dy: s * 0.015)
    let innerFramePath = CGPath(roundedRect: innerFrameRect,
                                cornerWidth: frameRadius * 0.9, cornerHeight: frameRadius * 0.9, transform: nil)
    ctx.setFillColor(CGColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1.0))
    ctx.addPath(innerFramePath)
    ctx.fillPath()

    // Mirror surface
    let mirrorInset = s * 0.04
    let mirrorRect = innerFrameRect.insetBy(dx: mirrorInset, dy: mirrorInset)
    let mirrorRadius = frameRadius * 0.7
    let mirrorPath = CGPath(roundedRect: mirrorRect,
                            cornerWidth: mirrorRadius, cornerHeight: mirrorRadius, transform: nil)

    // Mirror gradient (subtle blue-gray reflection)
    ctx.saveGState()
    ctx.addPath(mirrorPath)
    ctx.clip()
    let mirrorColors = [
        CGColor(red: 0.75, green: 0.78, blue: 0.85, alpha: 1.0),
        CGColor(red: 0.55, green: 0.58, blue: 0.68, alpha: 1.0),
        CGColor(red: 0.65, green: 0.70, blue: 0.78, alpha: 1.0),
    ]
    let mirrorGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: mirrorColors as CFArray,
                                     locations: [0.0, 0.5, 1.0])!
    ctx.drawLinearGradient(mirrorGradient,
                           start: CGPoint(x: mirrorRect.minX, y: mirrorRect.maxY),
                           end: CGPoint(x: mirrorRect.maxX, y: mirrorRect.minY),
                           options: [])

    // Subtle shine streak across mirror
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.12))
    let shineRect = CGRect(x: mirrorRect.minX + mirrorRect.width * 0.15,
                           y: mirrorRect.minY + mirrorRect.height * 0.3,
                           width: mirrorRect.width * 0.12,
                           height: mirrorRect.height * 0.5)
    let shinePath = CGPath(roundedRect: shineRect,
                           cornerWidth: shineRect.width * 0.5,
                           cornerHeight: shineRect.width * 0.5, transform: nil)
    ctx.addPath(shinePath)
    ctx.fillPath()
    ctx.restoreGState()

    // Light bulbs around the frame
    let bulbRadius = s * 0.032
    let bulbInset = s * 0.015 // how far bulbs sit from outer frame edge

    // Calculate bulb positions along the frame perimeter
    var bulbPositions: [CGPoint] = []

    let bulbFrameRect = frameRect.insetBy(dx: -bulbInset, dy: -bulbInset)

    // Top row
    let topBulbCount = 5
    for i in 0..<topBulbCount {
        let t = CGFloat(i + 1) / CGFloat(topBulbCount + 1)
        let x = bulbFrameRect.minX + bulbFrameRect.width * t
        bulbPositions.append(CGPoint(x: x, y: bulbFrameRect.maxY))
    }
    // Bottom row
    for i in 0..<topBulbCount {
        let t = CGFloat(i + 1) / CGFloat(topBulbCount + 1)
        let x = bulbFrameRect.minX + bulbFrameRect.width * t
        bulbPositions.append(CGPoint(x: x, y: bulbFrameRect.minY))
    }
    // Left column
    let sideBulbCount = 5
    for i in 0..<sideBulbCount {
        let t = CGFloat(i + 1) / CGFloat(sideBulbCount + 1)
        let y = bulbFrameRect.minY + bulbFrameRect.height * t
        bulbPositions.append(CGPoint(x: bulbFrameRect.minX, y: y))
    }
    // Right column
    for i in 0..<sideBulbCount {
        let t = CGFloat(i + 1) / CGFloat(sideBulbCount + 1)
        let y = bulbFrameRect.minY + bulbFrameRect.height * t
        bulbPositions.append(CGPoint(x: bulbFrameRect.maxX, y: y))
    }

    // Draw warm glow behind each bulb
    for pos in bulbPositions {
        let glowRadius = bulbRadius * 3.5
        let glowColors = [
            CGColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 0.35),
            CGColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 0.0),
        ]
        let glowGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: glowColors as CFArray,
                                       locations: [0.0, 1.0])!
        ctx.saveGState()
        ctx.drawRadialGradient(glowGradient,
                               startCenter: pos, startRadius: 0,
                               endCenter: pos, endRadius: glowRadius,
                               options: [])
        ctx.restoreGState()
    }

    // Draw bulbs
    for pos in bulbPositions {
        // Bulb body: warm white
        let bulbRect = CGRect(x: pos.x - bulbRadius, y: pos.y - bulbRadius,
                              width: bulbRadius * 2, height: bulbRadius * 2)
        ctx.setFillColor(CGColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1.0))
        ctx.fillEllipse(in: bulbRect)

        // Bulb highlight
        let highlightRect = CGRect(x: pos.x - bulbRadius * 0.45, y: pos.y + bulbRadius * 0.05,
                                   width: bulbRadius * 0.9, height: bulbRadius * 0.9)
        ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7))
        ctx.fillEllipse(in: highlightRect)
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Failed to create PNG\n", stderr)
        return
    }
    try! pngData.write(to: URL(fileURLWithPath: path))
}

// Main
guard CommandLine.arguments.count > 1 else {
    fputs("Usage: generate-icon.swift <output-dir>\n", stderr)
    exit(1)
}

let outputDir = CommandLine.arguments[1]
let iconsetDir = "\(outputDir)/AppIcon.iconset"
try! FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in sizes {
    let image = generateIcon(size: entry.px)
    savePNG(image, to: "\(iconsetDir)/\(entry.name).png")
}

print("Generated iconset at \(iconsetDir)")
