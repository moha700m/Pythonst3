import Foundation
import CoreGraphics
import ImageIO
import Darwin

func fail(_ message: String, _ code: Int32) -> Never {
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
    exit(code)
}

func sample(_ image: CGImage, _ x: Int, _ y: Int) -> (Int, Int, Int) {
    var pixel = [UInt8](repeating: 0, count: 4)
    let space = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: &pixel,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return (-1, -1, -1)
    }
    context.interpolationQuality = .none
    context.translateBy(x: CGFloat(-x), y: CGFloat(-(image.height - 1 - y)))
    context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
    return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
}

func isProbeColor(_ color: (Int, Int, Int)) -> Bool {
    color.0 > 180 && color.1 < 90 && color.2 > 180
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2 else {
    fail("usage: pixel_probe.swift <screenshot.png> <WIDTHxHEIGHT>", 64)
}

let path = arguments[0]
let expected = arguments[1]

guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fail("cannot decode \(path)", 65)
}

let actual = "\(image.width)x\(image.height)"
guard actual == expected else {
    fail("\(path): expected \(expected), got \(actual)", 66)
}

let points: [(String, Int, Int)] = [
    ("top-left", image.width / 4, 1),
    ("top-right", image.width * 3 / 4, 1),
    ("bottom-center", image.width / 2, image.height - 2)
]

var failures = 0
for (name, x, y) in points {
    let color = sample(image, x, y)
    let ok = isProbeColor(color)
    print("\(ok ? "OK" : "FAIL") \(path) \(name) @\(x),\(y) rgb=\(color.0),\(color.1),\(color.2)")
    if !ok { failures += 1 }
}

if failures > 0 {
    fail("\(path): app content does not reach the screen edges (letterboxed layout)", 67)
}
print("OK \(path): full-screen layout verified (\(actual))")
