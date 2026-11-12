import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMotion
import Photos
import ImageIO
import UIKit

@main
struct ChromaCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - 1. Perfiles de Película Cinematográficos
enum FilmProfile: String, CaseIterable, Identifiable {
    case chromagraph = "Chroma"
    case portra400 = "Portra 400"
    case cinestill800T = "800T"
    case triX400 = "Tri-X B&W"
    
    var id: String { self.rawValue }
    
    var badgeColor: Color {
        switch self {
        case .chromagraph: return Color(red: 0.90, green: 0.74, blue: 0.45)
        case .portra400: return Color(red: 0.95, green: 0.55, blue: 0.32)
        case .cinestill800T: return Color(red: 0.30, green: 0.78, blue: 0.92)
        case .triX400: return Color(white: 0.82)
        }
    }
}

// MARK: - 2. Motor de Revelado RAW Cinematográfico
class CinematicPipeline {
    static let shared = CinematicPipeline()
    
    let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
    lazy var ciContext: CIContext = {
        CIContext(options: [
            .workingColorSpace: colorSpace,
            .outputColorSpace: colorSpace,
            .workingFormat: CIFormat.RGBAh,
            .cacheIntermediates: false
        ])
    }()
    
    func applyCinematicLook(to input: CIImage, profile: FilmProfile, bloomAmount: Float, isRAW: Bool) -> CIImage {
        var current = input
        let extent = current.extent
        guard extent.width > 0, extent.height > 0 else { return input }
        
        // 1. Compresión suave de Altas Luces (Highlight Roll-off) y sombras limpias
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        hs.highlightAmount = 0.38
        hs.shadowAmount = isRAW ? 0.36 : 0.25
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 2. Curvas de Cine y Matrices de Color
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        switch profile {
        case .chromagraph:
            curve.point0 = CGPoint(x: 0.00, y: 0.04)
            curve.point1 = CGPoint(x: 0.22, y: 0.16)
            curve.point2 = CGPoint(x: 0.50, y: 0.52)
            curve.point3 = CGPoint(x: 0.78, y: 0.81)
            curve.point4 = CGPoint(x: 1.00, y: 0.91)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.08, y: 0.02, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 1.02, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.02, z: 0.92, w: 0)
            matrix.biasVector = CIVector(x: -0.01, y: 0.00, z: 0.015, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .portra400:
            curve.point0 = CGPoint(x: 0.00, y: 0.06)
            curve.point1 = CGPoint(x: 0.25, y: 0.22)
            curve.point2 = CGPoint(x: 0.50, y: 0.55)
            curve.point3 = CGPoint(x: 0.75, y: 0.82)
            curve.point4 = CGPoint(x: 1.00, y: 0.93)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.14, y: 0.03, z: -0.03, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.03, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: -0.02, z: 0.88, w: 0)
            matrix.biasVector = CIVector(x: 0.01, y: 0.005, z: -0.01, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .cinestill800T:
            curve.point0 = CGPoint(x: 0.00, y: 0.03)
            curve.point1 = CGPoint(x: 0.25, y: 0.15)
            curve.point2 = CGPoint(x: 0.50, y: 0.48)
            curve.point3 = CGPoint(x: 0.75, y: 0.81)
            curve.point4 = CGPoint(x: 1.00, y: 0.94)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 0.92, y: 0.02, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 1.04, z: 0.04, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: 0.06, z: 1.15, w: 0)
            matrix.biasVector = CIVector(x: -0.015, y: 0.01, z: 0.025, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .triX400:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = current
            if let out = noir.outputImage?.cropped(to: extent) { current = out }
            
            curve.inputImage = current
            curve.point0 = CGPoint(x: 0.00, y: 0.03)
            curve.point1 = CGPoint(x: 0.25, y: 0.16)
            curve.point2 = CGPoint(x: 0.50, y: 0.50)
            curve.point3 = CGPoint(x: 0.75, y: 0.84)
            curve.point4 = CGPoint(x: 1.00, y: 0.95)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 3. Halation / Bloom seguro
        if bloomAmount > 0.05 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = 10.0
            bloom.intensity = bloomAmount * 0.50
            if let out = bloom.outputImage?.cropped(to: extent) {
                current = out
            }
        }
        
        // 4. Viñeteado suave
        let vignette = CIFilter.vignette()
        vignette.inputImage = current
        vignette.intensity = 0.38
        vignette.radius = 1.6
        if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        
        // 5. Grano orgánico de 35mm
        if let noise = CIFilter.randomGenerator().outputImage {
            let grainIntensity: CGFloat = isRAW ? 0.028 : 0.022
            let monoNoise = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: grainIntensity)
            ]).cropped(to: extent)
            current = monoNoise.composited(over: current).cropped(to: extent)
        }
        
        return current
    }
    
    func developFinalPhoto(
        data: Data,
        wasCapturedAsRAW: Bool,
        profile: FilmProfile,
        bloomAmount: Float,
        deviceOrientation: UIDeviceOrientation
    ) -> (jpegData: Data?, previewImage: UIImage?, debugStatus: String) {
        return autoreleasepool {
            var baseImage: CIImage?
            var usedCIRAW = false
            
            let targetExifOrientation: CGImagePropertyOrientation
            switch deviceOrientation {
            case .landscapeLeft: targetExifOrientation = .up
            case .landscapeRight: targetExifOrientation = .down
            case .portraitUpsideDown: targetExifOrientation = .left
            default: targetExifOrientation = .right
            }
            
            // 1. Revelado RAW directo del sensor saltándose el procesado de Apple
            if wasCapturedAsRAW, let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
                rawFilter.luminanceNoiseReductionAmount = 0.72
                rawFilter.colorNoiseReductionAmount = 0.88
                rawFilter.sharpnessAmount = 0.08
                rawFilter.localToneMapAmount = 0.0
                rawFilter.boostAmount = 0.30
                rawFilter.baselineExposure = 0.25
                rawFilter.scaleFactor = 0.5
                
                if var rawOut = rawFilter.outputImage {
                    if rawOut.extent.width > rawOut.extent.height {
                        rawOut = rawOut.oriented(targetExifOrientation)
                    } else if deviceOrientation == .landscapeLeft {
                        rawOut = rawOut.oriented(.left)
                    } else if deviceOrientation == .landscapeRight {
                        rawOut = rawOut.oriented(.right)
                    }
                    baseImage = rawOut
                    usedCIRAW = true
                }
            }
            
            // 2. Decodificación estándar con rotación física garantizada
            if baseImage == nil, var std = CIImage(data: data, options: [.applyOrientationProperty: true]) {
                if std.extent.width > std.extent.height && !deviceOrientation.isLandscape {
                    std = std.oriented(.right)
                }
                let maxDim = max(std.extent.width, std.extent.height)
                if maxDim > 3500 {
                    let scale = 3024.0 / maxDim
                    std = std.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                }
                baseImage = std
            }
            
            guard let input = baseImage else {
                return (nil, nil, "ERROR AL LEER DATOS")
            }
            
            let normalizedInput = input.transformed(by: CGAffineTransform(translationX: -input.extent.origin.x, y: -input.extent.origin.y))
            let processed = applyCinematicLook(to: normalizedInput, profile: profile, bloomAmount: bloomAmount, isRAW: usedCIRAW)
            
            let qualityKey = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
            guard let jpegData = ciContext.jpegRepresentation(
                of: processed,
                colorSpace: colorSpace,
                options: [qualityKey: 0.95]
            ) else {
                return (nil, nil, "ERROR AL CODIFICAR JPEG")
            }
            
            let previewUI = UIImage(data: jpegData)
            let status = usedCIRAW ? "RAW GUARDADO EN FOTOS" : "CINE 16-BIT GUARDADO"
            return (jpegData, previewUI, status)
        }
    }
}

// MARK: - 3. Controlador de Cámara Blindado Contra Cras
