import SwiftUI
import AVFoundation
import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMotion
import Photos
import PhotosUI
import ImageIO
import UniformTypeIdentifiers
import UIKit

@main
struct oCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - 1. Catálogo de Cámaras Cinematográficas de oCam
enum FilmProfile: String, CaseIterable, Identifiable {
    case ocamMaster = "oCam"
    case nocturnaClub = "Nocturna"
    case portra400 = "Portra 400"
    case cinestill800T = "800T"
    case dispo98 = "Dispo 98"
    case ccd2004 = "CCD 2004"
    case polaroid600 = "Polaroid"
    case superia400 = "Superia"
    case velvia50 = "Velvia 50"
    case gold200 = "Gold 200"
    case bleachBypass = "Bleach"
    case triX400 = "Tri-X B&W"
    
    var id: String { self.rawValue }
    
    var subtitle: String {
        switch self {
        case .ocamMaster: return "GOLDEN S-CURVE"
        case .nocturnaClub: return "NIGHT CLUB & NEON"
        case .portra400: return "WARM SKIN"
        case .cinestill800T: return "TUNGSTEN HALO"
        case .dispo98: return "90s FLASH"
        case .ccd2004: return "Y2K DIGICAM"
        case .polaroid600: return "INSTANT SOFT"
        case .superia400: return "EMERALD GREEN"
        case .velvia50: return "DEEP CHROME"
        case .gold200: return "SUNSET GOLD"
        case .bleachBypass: return "SILVER GRIT"
        case .triX400: return "MONO 400"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .ocamMaster: return Color(red: 0.94, green: 0.78, blue: 0.48)
        case .nocturnaClub: return Color(red: 0.98, green: 0.45, blue: 0.32)
        case .portra400: return Color(red: 0.95, green: 0.62, blue: 0.38)
        case .cinestill800T: return Color(red: 0.38, green: 0.80, blue: 0.96)
        case .dispo98: return Color(red: 0.48, green: 0.92, blue: 0.64)
        case .ccd2004: return Color(red: 0.80, green: 0.64, blue: 0.98)
        case .polaroid600: return Color(red: 0.96, green: 0.78, blue: 0.66)
        case .superia400: return Color(red: 0.34, green: 0.86, blue: 0.56)
        case .velvia50: return Color(red: 0.96, green: 0.44, blue: 0.44)
        case .gold200: return Color(red: 0.98, green: 0.84, blue: 0.32)
        case .bleachBypass: return Color(red: 0.75, green: 0.80, blue: 0.84)
        case .triX400: return Color(white: 0.90)
        }
    }
    
    struct RecommendedSettings {
        let ev: Float
        let contrastSCurve: Float
        let warmth: Float
        let bloom: Float
        let grain: Float
        let vignette: Float
        let nightMode: Bool
    }
    
    var recommended: RecommendedSettings {
        switch self {
        case .ocamMaster:
            return RecommendedSettings(ev: -0.45, contrastSCurve: 0.72, warmth: 0.28, bloom: 0.42, grain: 0.28, vignette: 0.28, nightMode: false)
        case .nocturnaClub:
            return RecommendedSettings(ev: -0.65, contrastSCurve: 0.78, warmth: 0.18, bloom: 0.78, grain: 0.38, vignette: 0.42, nightMode: true)
        case .portra400:
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.58, warmth: 0.32, bloom: 0.35, grain: 0.25, vignette: 0.22, nightMode: false)
        case .cinestill800T:
            return RecommendedSettings(ev: -0.55, contrastSCurve: 0.70, warmth: -0.22, bloom: 0.72, grain: 0.40, vignette: 0.38, nightMode: true)
        case .dispo98:
            return RecommendedSettings(ev: -0.25, contrastSCurve: 0.65, warmth: 0.15, bloom: 0.45, grain: 0.58, vignette: 0.48, nightMode: false)
        case .ccd2004:
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.62, warmth: -0.05, bloom: 0.22, grain: 0.30, vignette: 0.30, nightMode: false)
        case .polaroid600:
            return RecommendedSettings(ev: -0.20, contrastSCurve: 0.48, warmth: 0.36, bloom: 0.52, grain: 0.32, vignette: 0.42, nightMode: false)
        case .superia400:
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.64, warmth: 0.10, bloom: 0.30, grain: 0.32, vignette: 0.28, nightMode: false)
        case .velvia50:
            return RecommendedSettings(ev: -0.45, contrastSCurve: 0.76, warmth: 0.12, bloom: 0.28, grain: 0.18, vignette: 0.32, nightMode: false)
        case .gold200:
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.66, warmth: 0.38, bloom: 0.44, grain: 0.30, vignette: 0.28, nightMode: false)
        case .bleachBypass:
            return RecommendedSettings(ev: -0.50, contrastSCurve: 0.82, warmth: -0.15, bloom: 0.15, grain: 0.48, vignette: 0.52, nightMode: false)
        case .triX400:
            return RecommendedSettings(ev: -0.40, contrastSCurve: 0.78, warmth: 0.0, bloom: 0.25, grain: 0.62, vignette: 0.45, nightMode: false)
        }
    }
}

enum AspectRatioOption: String, CaseIterable {
    case fourThree = "4:3"
    case oneOne = "1:1"
    case sixteenNine = "16:9"
    case anamorphic = "2.39:1"
    
    var portraitRatio: CGFloat {
        switch self {
        case .fourThree: return 3.0 / 4.0
        case .oneOne: return 1.0
        case .sixteenNine: return 9.0 / 16.0
        case .anamorphic: return 1.0 / 2.0
        }
    }
}

enum FrameStyleOption: String, CaseIterable {
    case none = "Sin Marco"
    case polaroidWhite = "Polaroid"
    case filmBlack = "Cine Negro"
    case filmPerforated = "35mm"
}

enum ShutterSpeedOption: String, CaseIterable {
    case auto = "AUTO"
    case s1_1000 = "1/1000"
    case s1_250 = "1/250"
    case s1_60 = "1/60"
    case s1_15 = "1/15"
    case s1_4 = "1/4"
}

struct DevelopedPhotoResult {
    let jpegData: Data?
    let previewImage: UIImage?
    let status: String
    let exifSummary: String
}

// MARK: - 2. Motor Cinematográfico oCam (Curva S con Pivote + Grano Real Escalar + Inyección EXIF)
class CinematicPipeline {
    static let shared = CinematicPipeline()
    
    let ciContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        .workingFormat: CIFormat.RGBA8,
        .cacheIntermediates: false,
        .priorityRequestLow: false
    ])
    
    func applyCinematicLook(
        to input: CIImage,
        profile: FilmProfile,
        contrastSCurve: Float,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float,
        exposureAdjust: Float = 0.0,
        portraitDepthBlur: Float = 0.0,
        nightModeBoost: Bool = false,
        lightLeakEnabled: Bool = false,
        anamorphicMode: Bool = false,
        isRAW: Bool,
        is48MP: Bool
    ) -> CIImage {
        var current = input
        let extent = current.extent
        guard extent.width > 0, extent.height > 0 else { return input }
        let scaleMultiplier = max(1.0, min(extent.width, extent.height) / 1080.0)
        
        if abs(exposureAdjust) > 0.02 {
            let exp = CIFilter.exposureAdjust()
            exp.inputImage = current
            exp.ev = exposureAdjust
            if let out = exp.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 1. Balance de Blancos Cinematográfico (Elimina el tono azulado frío)
        let wbFix = CIFilter.temperatureAndTint()
        wbFix.inputImage = current
        wbFix.neutral = CIVector(x: 6500, y: 0)
        let baseWarmth: CGFloat = isRAW ? 5400 : 5850
        let userShift = CGFloat(-warmthAdjust * 1350)
        let tintShift: CGFloat = isRAW ? 18 : 6
        wbFix.targetNeutral = CIVector(x: baseWarmth + userShift, y: tintShift)
        if let out = wbFix.outputImage?.cropped(to: extent) { current = out }
        
        // 2. Recuperación de Altas Luces (Evita fotos quemadas) y Sombras ricas
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        hs.highlightAmount = nightModeBoost ? 0.15 : 0.22
        hs.shadowAmount = nightModeBoost ? 0.45 : (isRAW ? 0.35 : 0.18)
        hs.radius = Float(30.0 * scaleMultiplier)
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 3. Matrices Químicas por Cámara
        let matrix = CIFilter.colorMatrix()
        matrix.inputImage = current
        
        switch profile {
        case .ocamMaster:
            matrix.rVector = CIVector(x: 1.12, y: 0.03, z: -0.03, w: 0)
            matrix.gVector = CIVector(x: 0.01, y: 1.01, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: 0.02, z: 0.88, w: 0)
            matrix.biasVector = CIVector(x: 0.008, y: 0.002, z: -0.012, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .nocturnaClub:
            matrix.rVector = CIVector(x: 1.16, y: 0.04, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.98, z: 0.02, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.05, z: 1.06, w: 0)
            matrix.biasVector = CIVector(x: 0.005, y: -0.010, z: 0.012, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .portra400:
            matrix.rVector = CIVector(x: 1.11, y: 0.02, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.01, y: 1.01, z: -0.01, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: -0.01, z: 0.90, w: 0)
            matrix.biasVector = CIVector(x: 0.008, y: 0.00, z: -0.008, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .cinestill800T:
            matrix.rVector = CIVector(x: 0.98, y: 0.02, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 1.01, z: 0.03, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: 0.04, z: 1.08, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .dispo98:
            matrix.rVector = CIVector(x: 1.09, y: 0.04, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.05, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.02, z: 0.87, w: 0)
            matrix.biasVector = CIVector(x: 0.00, y: 0.012, z: -0.01, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .ccd2004:
            let controls = CIFilter.colorControls()
            controls.inputImage = current
            controls.saturation = 1.18
            if let out = controls.outputImage?.cropped(to: extent) { current = out }
            
        case .polaroid600:
            matrix.rVector = CIVector(x: 1.12, y: 0.04, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.02, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.01, z: 0.85, w: 0)
            matrix.biasVector = CIVector(x: 0.015, y: 0.005, z: -0.015, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .superia400:
            matrix.rVector = CIVector(x: 1.05, y: -0.01, z: 0.02, w: 0)
            matrix.gVector = CIVector(x: -0.01, y: 1.06, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: 0.00, y: 0.01, z: 0.93, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .velvia50:
            let controls = CIFilter.colorControls()
            controls.inputImage = current
            controls.saturation = 1.25
            if let out = controls.outputImage?.cropped(to: extent) { current = out }
            
        case .gold200:
            matrix.rVector = CIVector(x: 1.15, y: 0.03, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.04, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.06, y: -0.02, z: 0.83, w: 0)
            matrix.biasVector = CIVector(x: 0.012, y: 0.004, z: -0.018, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .bleachBypass:
            let controls = CIFilter.colorControls()
            controls.inputImage = current
            controls.saturation = 0.48
            if let out = controls.outputImage?.cropped(to: extent) { current = out }
            
        case .triX400:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = current
            if let out = noir.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 4. S-Curve Contrast con Pivote 0.64
        let sAmount = Double(contrastSCurve)
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        curve.point0 = CGPoint(x: 0.00, y: 0.01)
        curve.point1 = CGPoint(x: 0.25, y: max(0.11, 0.22 - (sAmount * 0.09)))
        curve.point2 = CGPoint(x: 0.52, y: 0.50)
        curve.point3 = CGPoint(x: 0.76, y: min(0.86, 0.77 + (sAmount * 0.07)))
        curve.point4 = CGPoint(x: 1.00, y: 0.94)
        if let out = curve.outputImage?.cropped(to: extent) { current = out }
        
        // 5. Modo Retrato Óptico (Bokeh circular suave)
        if !is48MP && portraitDepthBlur > 0.05 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = current.clampedToExtent()
            blur.radius = Float(18.0 * Double(portraitDepthBlur) * scaleMultiplier)
            if let blurred = blur.outputImage?.cropped(to: extent) {
                let mask = CIFilter.radialGradient()
                mask.center = CGPoint(x: extent.midX, y: extent.midY)
                mask.radius0 = Float(min(extent.width, extent.height) * 0.26)
                mask.radius1 = Float(max(extent.width, extent.height) * 0.62)
                mask.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
                mask.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
                if let maskImg = mask.outputImage?.cropped(to: extent) {
                    let blend = CIFilter.blendWithMask()
                    blend.inputImage = blurred
                    blend.backgroundImage = current
                    blend.maskImage = maskImg
                    if let out = blend.outputImage?.cropped(to: extent) { current = out }
                }
            }
        }
        
        // 6. Halation / Bloom Cálido
        if !is48MP && bloomAmount > 0.04 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = Float(16.0 * scaleMultiplier)
            bloom.intensity = bloomAmount * (profile == .nocturnaClub ? 0.85 : 0.62)
            if let out = bloom.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 7. Viñeteado Óptico
        if vignetteAmount > 0.02 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = current
            vignette.intensity = vignetteAmount * 1.55
            vignette.radius = 1.65
            if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 8. Fuga de Luz Analógica
        if lightLeakEnabled {
            let grad = CIFilter.linearGradient()
            grad.point0 = CGPoint(x: 0, y: extent.height * 0.85)
            grad.point1 = CGPoint(x: extent.width * 0.42, y: extent.height * 0.35)
            grad.color0 = CIColor(red: 1.0, green: 0.32, blue: 0.05, alpha: 0.52)
            grad.color1 = CIColor(red: 1.0, green: 0.65, blue: 0.10, alpha: 0.0)
            if let leakImg = grad.outputImage?.cropped(to: extent) {
                let screen = CIFilter.screenBlendMode()
                screen.inputImage = leakImg
                screen.backgroundImage = current
                if let out = screen.outputImage?.cropped(to: extent) { current = out }
            }
        }
        
        // 9. Lente Anamórfico
        if anamorphicMode {
            let flare = CIFilter.linearGradient()
            flare.point0 = CGPoint(x: extent.width * 0.1, y: extent.height * 0.5)
            flare.point1 = CGPoint(x: extent.width * 0.9, y: extent.height * 0.5)
            flare.color0 = CIColor(red: 0.1, green: 0.5, blue: 1.0, alpha: 0.0)
            flare.color1 = CIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.25)
            if let flareImg = flare.outputImage?.cropped(to: extent) {
                let add = CIFilter.additionCompositing()
                add.inputImage = flareImg
                add.backgroundImage = current
                if let out = add.outputImage?.cropped(to: extent) { current = out }
            }
        }
        
        // 10. Grano 35mm Real Escalado a los Megapíxeles
        if grainAmount > 0.02, let rawNoise = CIFilter.randomGenerator().outputImage {
            let grainScale = max(1.8, min(extent.width, extent.height) / 950.0)
            let scaledNoise = rawNoise.transformed(by: CGAffineTransform(scaleX: grainScale, y: grainScale))
            let grainStrength = CGFloat(grainAmount * 0.22)
            
            let centeredGrain = scaledNoise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: grainStrength, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: grainStrength, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: grainStrength, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0.5 - (grainStrength * 0.5), y: 0.5 - (grainStrength * 0.5), z: 0.5 - (grainStrength * 0.5), w: 0)
            ]).cropped(to: extent)
            
            let softLight = CIFilter.softLightBlendMode()
            softLight.inputImage = centeredGrain
            softLight.backgroundImage = current
            if let grained = softLight.outputImage?.cropped(to: extent) {
                current = grained
            }
        }
        
        return current
    }
    
    func applyFinalTouches(
        to image: UIImage,
        aspectRatio: AspectRatioOption,
        frameStyle: FrameStyleOption,
        dateStampEnabled: Bool
    ) -> UIImage {
        let origW = image.size.width
        let origH = image.size.height
        let isLandscape = origW > origH
        
        var targetRatio: CGFloat = 3.0 / 4.0
        switch aspectRatio {
        case .fourThree: targetRatio = isLandscape ? (4.0 / 3.0) : (3.0 / 4.0)
        case .oneOne: targetRatio = 1.0
        case .sixteenNine: targetRatio = isLandscape ? (16.0 / 9.0) : (9.0 / 16.0)
        case .anamorphic: targetRatio = isLandscape ? (2.39 / 1.0) : (1.0 / 2.0)
        }
        
        var cropW = origW
        var cropH = origH
        if (origW / origH) > targetRatio {
            cropW = origH * targetRatio
        } else {
            cropH = origW / targetRatio
        }
        let cropX = (origW - cropW) / 2.0
        let cropY = (origH - cropH) / 2.0
        
        let borderSide: CGFloat = (frameStyle == .none) ? 0 : (min(cropW, cropH) * (frameStyle == .filmPerforated ? 0.08 : 0.048))
        let borderBottom: CGFloat = (frameStyle == .polaroidWhite) ? (min(cropW, cropH) * 0.14) : borderSide
        let canvasW = cropW + (borderSide * 2)
        let canvasH = cropH + borderSide + borderBottom
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: canvasW, height: canvasH), format: format)
        
        return renderer.image { ctx in
            if frameStyle == .polaroidWhite {
                UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
            } else if frameStyle == .filmBlack || frameStyle == .filmPerforated {
                UIColor(white: 0.04, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
                
                if frameStyle == .filmPerforated {
                    UIColor(white: 0.18, alpha: 1.0).setFill()
                    let perfW = borderSide * 0.5
                    let perfH = borderSide * 0.75
                    let perfX = (borderSide - perfW) / 2.0
                    var currentY: CGFloat = borderSide
                    while currentY + perfH < canvasH - borderSide {
                        ctx.fill(CGRect(x: perfX, y: currentY, width: perfW, height: perfH))
                        ctx.fill(CGRect(x: canvasW - borderSide + perfX, y: currentY, width: perfW, height: perfH))
                        currentY += perfH * 1.8
                    }
                }
            }
            
            let photoRect = CGRect(x: borderSide, y: borderSide, width: cropW, height: cropH)
            ctx.cgContext.saveGState()
            ctx.cgContext.clip(to: photoRect)
            image.draw(in: CGRect(x: borderSide - cropX, y: borderSide - cropY, width: origW, height: origH))
            ctx.cgContext.restoreGState()
            
            if dateStampEnabled {
                let df = DateFormatter()
                df.dateFormat = "''yy MM dd"
                let dateStr = df.string(from: Date())
                
                let fontSize = max(18.0, min(cropW, cropH) * 0.036)
                let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
                
                let shadow = NSShadow()
                shadow.shadowColor = UIColor(red: 1.0, green: 0.18, blue: 0.0, alpha: 0.85)
                shadow.shadowBlurRadius = fontSize * 0.35
                shadow.shadowOffset = .zero
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.12, alpha: 0.92),
                    .shadow: shadow
                ]
                
                let strSize = (dateStr as NSString).size(withAttributes: attrs)
                let posX = borderSide + cropW - strSize.width - (cropW * 0.045)
                let posY = borderSide + cropH - strSize.height - (cropH * 0.035)
                (dateStr as NSString).draw(at: CGPoint(x: posX, y: posY), withAttributes: attrs)
            }
        }
    }
    
    private func encodeJPEGWithMetadata(cgImage: CGImage, originalMetadata: [String: Any]?, profile: FilmProfile) -> (data: Data?, summary: String) {
        var meta = originalMetadata ?? [:]
        meta[kCGImagePropertyOrientation as String] = 1
        
        var tiffDict = (meta[kCGImagePropertyTIFFDictionary as String] as? [String: Any]) ?? [:]
        if tiffDict[kCGImagePropertyTIFFMake as String] == nil {
            tiffDict[kCGImagePropertyTIFFMake as String] = "Apple"
        }
        if tiffDict[kCGImagePropertyTIFFModel as String] == nil {
            tiffDict[kCGImagePropertyTIFFModel as String] = UIDevice.current.model
        }
        tiffDict[kCGImagePropertyTIFFSoftware as String] = "oCam Engine - \(profile.rawValue)"
        meta[kCGImagePropertyTIFFDictionary as String] = tiffDict
        
        var exifDict = (meta[kCGImagePropertyExifDictionary as String] as? [String: Any]) ?? [:]
        exifDict[kCGImagePropertyExifPixelXDimension as String] = cgImage.width
        exifDict[kCGImagePropertyExifPixelYDimension as String] = cgImage.height
        if exifDict[kCGImagePropertyExifLensModel as String] == nil {
            exifDict[kCGImagePropertyExifLensModel as String] = "oCam 24mm f/1.6"
        }
        meta[kCGImagePropertyExifDictionary as String] = exifDict
        
        let isoVal = (exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first ?? 64
        let fNumber = (exifDict[kCGImagePropertyExifFNumber as String] as? Double) ?? 1.6
        let expTime = (exifDict[kCGImagePropertyExifExposureTime as String] as? Double) ?? 0.008
        let shutterInv = max(1, Int(round(1.0 / max(0.0001, expTime))))
        let summary = "1/\(shutterInv)s | f/\(String(format: "%.1f", fNumber)) | ISO \(isoVal)"
        
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return (nil, summary)
        }
        meta[kCGImageDestinationLossyCompressionQuality as String] = 0.96
        CGImageDestinationAddImage(dest, cgImage, meta as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            return (nil, summary)
        }
        return (mutableData as Data, summary)
    }
    
    func renderPreviewUIImage(
        from ciInput: CIImage,
        profile: FilmProfile,
        contrastSCurve: Float,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float,
        exposureAdjust: Float,
        portraitDepthBlur: Float,
        lightLeakEnabled: Bool,
        anamorphicMode: Bool
    ) -> UIImage? {
        let filtered = applyCinematicLook(
            to: ciInput,
            profile: profile,
            contrastSCurve: contrastSCurve,
            bloomAmount: bloomAmount,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            warmthAdjust: warmthAdjust,
            exposureAdjust: exposureAdjust,
            portraitDepthBlur: portraitDepthBlur,
            nightModeBoost: profile == .nocturnaClub,
            lightLeakEnabled: lightLeakEnabled,
            anamorphicMode: anamorphicMode,
            isRAW: false,
            is48MP: false
        )
        guard let cg = ciContext.createCGImage(filtered, from: filtered.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
    
    func developFinalPhoto(
        data: Data,
        rawMetadata: [String: Any]?,
        wasCapturedAsRAW: Bool,
        profile: FilmProfile,
        contrastSCurve: Float,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float,
        exposureAdjust: Float = 0.0,
        portraitDepthBlur: Float = 0.0,
        nightModeBoost: Bool = false,
        lightLeakEnabled: Bool = false,
        anamorphicMode: Bool = false,
        dateStampEnabled: Bool = false,
        aspectRatio: AspectRatioOption = .fourThree,
        frameStyle: FrameStyleOption = .none,
        deviceOrientation: UIDeviceOrientation,
        isFromGallery: Bool = false
    ) -> DevelopedPhotoResult {
        var baseImage: CIImage?
        var usedCIRAW = false
        
        var extractedMeta = rawMetadata
        if extractedMeta == nil, let src = CGImageSourceCreateWithData(data as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any] {
            extractedMeta = props
        }
        
        let targetExifOrientation: CGImagePropertyOrientation
        switch deviceOrientation {
        case .landscapeLeft: targetExifOrientation = .up
        case .landscapeRight: targetExifOrientation = .down
        case .portraitUpsideDown: targetExifOrientation = .left
        default: targetExifOrientation = .right
        }
        
        if wasCapturedAsRAW, let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
            rawFilter.luminanceNoiseReductionAmount = nightModeBoost ? 0.88 : 0.78
            rawFilter.colorNoiseReductionAmount = 0.94
            rawFilter.sharpnessAmount = 0.22
            rawFilter.localToneMapAmount = 0.20
            rawFilter.boostAmount = 0.48
            rawFilter.baselineExposure = -0.40
            rawFilter.scaleFactor = 1.0
            
            if var rawOut = rawFilter.outputImage {
                if !isFromGallery {
                    if rawOut.extent.width > rawOut.extent.height {
                        rawOut = rawOut.oriented(targetExifOrientation)
                    } else if deviceOrientation == .landscapeLeft {
                        rawOut = rawOut.oriented(.left)
                    } else if deviceOrientation == .landscapeRight {
                        rawOut = rawOut.oriented(.right)
                    }
                }
                baseImage = rawOut
                usedCIRAW = true
            }
        }
        
        if baseImage == nil, var std = CIImage(data: data, options: [.applyOrientationProperty: true]) {
            if !isFromGallery && std.extent.width > std.extent.height && !deviceOrientation.isLandscape {
                std = std.oriented(.right)
            }
            baseImage = std
        }
        
        guard let input = baseImage else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: nil, status: "ERROR DATOS", exifSummary: "")
        }
        
        let normalizedInput = input.transformed(by: CGAffineTransform(translationX: -input.extent.origin.x, y: -input.extent.origin.y))
        let maxSide = max(normalizedInput.extent.width, normalizedInput.extent.height)
        let is48MP = maxSide > 5000
        
        let processed = applyCinematicLook(
            to: normalizedInput,
            profile: profile,
            contrastSCurve: contrastSCurve,
            bloomAmount: bloomAmount,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            warmthAdjust: warmthAdjust,
            exposureAdjust: exposureAdjust,
            portraitDepthBlur: portraitDepthBlur,
            nightModeBoost: nightModeBoost,
            lightLeakEnabled: lightLeakEnabled,
            anamorphicMode: anamorphicMode,
            isRAW: usedCIRAW,
            is48MP: is48MP
        )
        
        guard let cgImage = ciContext.createCGImage(processed, from: processed.extent) else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: nil, status: "ERROR GPU", exifSummary: "")
        }
        
        var uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        if aspectRatio != .fourThree || frameStyle != .none || dateStampEnabled {
            uiImage = applyFinalTouches(
                to: uiImage,
                aspectRatio: aspectRatio,
                frameStyle: frameStyle,
                dateStampEnabled: dateStampEnabled
            )
        }
        
        let finalCG = uiImage.cgImage ?? cgImage
        let encoded = encodeJPEGWithMetadata(cgImage: finalCG, originalMetadata: extractedMeta, profile: profile)
        let finalData = encoded.data ?? uiImage.jpegData(compressionQuality: 0.96)
        
        let w = finalCG.width
        let h = finalCG.height
        let mp = max(1, Int(round((Double(w) * Double(h)) / 1_000_000.0)))
        let statusText = usedCIRAW ? "RAW \(mp)MP" : "\(mp)MP"
        return DevelopedPhotoResult(jpegData: finalData, previewImage: uiImage, status: statusText, exifSummary: encoded.summary)
    }
}

// MARK: - 3. Controlador de Hardware oCam
@Observable
class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.ocam.sessionQueue")
    private let motionManager = CMMotionManager()
    
    private var currentDevice: AVCaptureDevice?
    private var lastExposureUpdate: Date = .distantPast
    private var max12MPDimension = CMVideoDimensions(width: 4032, height: 3024)
    private var max48MPDimension: CMVideoDimensions?
    
    var capturedImage: UIImage?
    var isProcessing = false
    var isRAWActive = false
    var is48MPSupported = false
    var use48MPMode = false
    var useRAWCapture = true
    var statusMessage = "oCam READY"
    var lastExifSummary = "1/125s | f/1.6 | ISO 64"
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .ocamMaster
    
    var exposureEV: Float = -0.45
    var contrastSCurve: Float = 0.72
    var warmth: Float = 0.28
    var bloomIntensity: Float = 0.42
    var grainIntensity: Float = 0.28
    var vignetteIntensity: Float = 0.28
    var portraitDepthBlur: Float = 0.0
    var nightModeEnabled = false
    var shutterSpeed: ShutterSpeedOption = .auto
    var anamorphicMode = false
    var dateStampEnabled = false
    var lightLeakEnabled = false
    var aspectRatio: AspectRatioOption = .fourThree
    var frameStyle: FrameStyleOption = .none
    var flashEnabled = false
    var showGrid = true
    var timerSeconds: Int = 0
    var countdownRemaining: Int = 0
    var focusPoint: CGPoint?
    var physicalOrientation: UIDeviceOrientation = .portrait
    
    override init() {
        super.init()
        startMotionTracking()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    func selectProfile(_ profile: FilmProfile) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedProfile = profile
        applyRecommendedForCurrentProfile()
    }
    
    func applyRecommendedForCurrentProfile() {
        let rec = selectedProfile.recommended
        exposureEV = rec.ev
        contrastSCurve = rec.contrastSCurve
        warmth = rec.warmth
        bloomIntensity = rec.bloom
        grainIntensity = rec.grain
        vignetteIntensity = rec.vignette
        nightModeEnabled = rec.nightMode
        setExposure(rec.ev)
        updateNightModeHardware()
    }
    
    func resetToNeutral() {
        exposureEV = 0.0
        contrastSCurve = 0.35
        warmth = 0.0
        bloomIntensity = 0.0
        grainIntensity = 0.0
        vignetteIntensity = 0.0
        portraitDepthBlur = 0.0
        nightModeEnabled = false
        setExposure(0.0)
        updateNightModeHardware()
    }
    
    private func startMotionTracking() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.25
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let acc = data?.acceleration else { return }
            if abs(acc.y) > abs(acc.x) {
                self.physicalOrientation = acc.y < 0 ? .portrait : .portraitUpsideDown
            } else {
                self.physicalOrientation = acc.x < 0 ? .landscapeLeft : .landscapeRight
            }
        }
    }
    
    private func configureSensorFormat(for device: AVCaptureDevice, prefer48MP: Bool) {
        var bestFormat48MP: AVCaptureDevice.Format?
        var found48MPDim: CMVideoDimensions?
        var best12MPDim = CMVideoDimensions(width: 4032, height: 3024)
        
        for format in device.formats {
            let dims = format.supportedMaxPhotoDimensions
            if let d12 = dims.first(where: { $0.width >= 4000 && $0.width <= 4200 }) {
                best12MPDim = d12
            }
            if let d48 = dims.first(where: { $0.width >= 8000 }) {
                let mediaSubType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                if bestFormat48MP == nil || mediaSubType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
                    bestFormat48MP = format
                    found48MPDim = d48
                }
            }
        }
        
        self.max12MPDimension = best12MPDim
        self.max48MPDimension = found48MPDim
        let supports48 = (found48MPDim != nil)
        
        if prefer48MP, let format48 = bestFormat48MP, let d48 = found48MPDim {
            do {
                if self.session.canSetSessionPreset(.inputPriority) {
                    self.session.sessionPreset = .inputPriority
                }
                try device.lockForConfiguration()
                device.activeFormat = format48
                device.automaticallyAdjustsVideoHDREnabled = false
                if device.isGlobalToneMappingSupported {
                    device.isGlobalToneMappingEnabled = true
                }
                device.unlockForConfiguration()
                self.photoOutput.maxPhotoDimensions = d48
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            } catch {}
        } else {
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }
            do {
                try device.lockForConfiguration()
                if device.isLowLightBoostSupported {
                    device.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                device.unlockForConfiguration()
            } catch {}
            self.photoOutput.maxPhotoDimensions = best12MPDim
            self.photoOutput.maxPhotoQualityPrioritization = .quality
        }
        
        DispatchQueue.main.async {
            self.is48MPSupported = supports48
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        currentDevice = device
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
            if photoOutput.isAppleProRAWSupported {
                photoOutput.isAppleProRAWEnabled = true
            }
        }
        
        configureSensorFormat(for: device, prefer48MP: use48MPMode)
        
        session.commitConfiguration()
        session.startRunning()
        
        applyExposureInternal(exposureEV)
        updateStatusBadge()
    }
    
    func updateNightModeHardware() {
        let isNight = nightModeEnabled
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isLowLightBoostSupported {
                    device.automaticallyEnablesLowLightBoostWhenAvailable = isNight
                }
                if isNight {
                    let duration = CMTimeMake(value: 1, timescale: 12)
                    let targetISO = min(device.activeFormat.maxISO, max(400, device.iso))
                    device.setExposureModeCustom(duration: duration, iso: targetISO, completionHandler: nil)
                } else if self.shutterSpeed == .auto {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {}
            self.updateStatusBadge()
        }
    }
    
    func focusAt(normalizedPoint: CGPoint, viewPoint: CGPoint) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        focusPoint = viewPoint
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.focusPoint == viewPoint {
                self.focusPoint = nil
            }
        }
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = normalizedPoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = normalizedPoint
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }
    
    func toggleSensorMode() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if useRAWCapture {
            if is48MPSupported && currentZoom == 1.0 {
                useRAWCapture = false
                use48MPMode = true
            } else {
                useRAWCapture = false
                use48MPMode = false
            }
        } else if use48MPMode {
            use48MPMode = false
            useRAWCapture = false
        } else {
            useRAWCapture = true
            use48MPMode = false
        }
        
        let want48 = use48MPMode && is48MPSupported && (currentZoom == 1.0)
        let targetEV = exposureEV
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            self.session.beginConfiguration()
            self.configureSensorFormat(for: device, prefer48MP: want48)
            self.session.commitConfiguration()
            self.applyExposureInternal(targetEV)
            self.updateStatusBadge()
        }
    }
    
    private func updateStatusBadge() {
        let hasRAW = !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
        DispatchQueue.main.async {
            self.isRAWActive = hasRAW
            if self.nightModeEnabled {
                self.statusMessage = "MODO NOCHE ACTIVO"
            } else if self.currentZoom != 1.0 {
                self.statusMessage = "LENTE \(self.currentZoom == 0.5 ? "0.5x" : "2x") 12MP"
            } else if self.use48MPMode && self.is48MPSupported {
                self.statusMessage = "48MP PRO"
            } else if self.useRAWCapture && hasRAW {
                self.statusMessage = "RAW 12MP"
            } else {
                self.statusMessage = "12MP CINE"
            }
        }
    }
    
    func setExposure(_ ev: Float) {
        exposureEV = ev
        let now = Date()
        guard now.timeIntervalSince(lastExposureUpdate) > 0.06 else { return }
        lastExposureUpdate = now
        
        sessionQueue.async {
            self.applyExposureInternal(ev)
        }
    }
    
    private func applyExposureInternal(_ ev: Float) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            let clampedEV = max(device.minExposureTargetBias, min(ev, device.maxExposureTargetBias))
            device.setExposureTargetBias(clampedEV, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {}
    }
    
    func applyShutterSpeed(_ speed: ShutterSpeedOption) {
        shutterSpeed = speed
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if speed == .auto {
                    device.exposureMode = .continuousAutoExposure
                } else {
                    var duration = CMTime.invalid
                    var iso: Float = device.iso
                    switch speed {
                    case .s1_1000: duration = CMTimeMake(value: 1, timescale: 1000); iso = 320
                    case .s1_250: duration = CMTimeMake(value: 1, timescale: 250); iso = 160
                    case .s1_60: duration = CMTimeMake(value: 1, timescale: 60); iso = 100
                    case .s1_15: duration = CMTimeMake(value: 1, timescale: 15); iso = 80
                    case .s1_4: duration = CMTimeMake(value: 1, timescale: 4); iso = 64
                    case .auto: break
                    }
                    if duration.isValid {
                        device.setExposureModeCustom(duration: duration, iso: iso, completionHandler: nil)
                    }
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }
    
    func switchCameraLens(factor: CGFloat) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentZoom = factor
        let targetEV = exposureEV
        let want48 = use48MPMode && (factor == 1.0)
        
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            
            let targetType: AVCaptureDevice.DeviceType = (factor == 0.5) ? .builtInUltraWideCamera : .builtInWideAngleCamera
            if let newDevice = AVCaptureDevice.default(targetType, for: .video, position: .back),
               let newInput = try? AVCaptureDeviceInput(device: newDevice) {
                self.currentDevice = newDevice
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                }
                if factor == 1.0 {
                    self.configureSensorFormat(for: newDevice, prefer48MP: want48)
                } else {
                    self.session.sessionPreset = .photo
                    if let maxDim = newDevice.activeFormat.supportedMaxPhotoDimensions.last {
                        self.photoOutput.maxPhotoDimensions = maxDim
                    }
                }
            }
            
            self.session.commitConfiguration()
            
            if let device = self.currentDevice {
                do {
                    try device.lockForConfiguration()
                    let zoom = (factor > 1.0) ? factor : 1.0
                    device.videoZoomFactor = min(zoom, device.maxAvailableVideoZoomFactor)
                    let clampedEV = max(device.minExposureTargetBias, min(targetEV, device.maxExposureTargetBias))
                    device.setExposureTargetBias(clampedEV, completionHandler: nil)
                    device.unlockForConfiguration()
                } catch {}
            }
            
            self.updateStatusBadge()
        }
    }
    
    func triggerShutter() {
        guard !isProcessing && countdownRemaining == 0 else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        
        if timerSeconds > 0 {
            countdownRemaining = timerSeconds
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if self.countdownRemaining > 1 {
                    self.countdownRemaining -= 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else {
                    timer.invalidate()
                    self.countdownRemaining = 0
                    self.capturePhoto()
                }
            }
        } else {
            capturePhoto()
        }
    }
    
    func capturePhoto() {
        guard !isProcessing else { return }
        isProcessing = true
        
        let want48MP = self.use48MPMode && self.is48MPSupported && (self.currentZoom == 1.0)
        let wantRAW = self.useRAWCapture && !want48MP && (self.currentZoom == 1.0)
        let useFlash = self.flashEnabled
        let isNight = self.nightModeEnabled
        statusMessage = want48MP ? "48MP..." : (wantRAW ? "RAW..." : "REVELANDO...")
        
        sessionQueue.async {
            guard let connection = self.photoOutput.connection(with: .video), connection.isEnabled, connection.isActive else {
                DispatchQueue.main.async {
                    self.statusMessage = "LISTO"
                    self.isProcessing = false
                }
                return
            }
            
            let settings: AVCapturePhotoSettings
            let bayerFormats = self.photoOutput.availableRawPhotoPixelFormatTypes.filter {
                AVCapturePhotoOutput.isBayerRAWPixelFormat($0)
            }
            
            if wantRAW, let rawFormat = bayerFormats.first ?? self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                let processedCodec = self.photoOutput.availablePhotoCodecTypes.contains(.hevc) ? AVVideoCodecType.hevc : AVVideoCodecType.jpeg
                settings = AVCapturePhotoSettings(
                    rawPixelFormatType: rawFormat,
                    processedFormat: [AVVideoCodecKey: processedCodec]
                )
                settings.photoQualityPrioritization = .speed
                self.photoOutput.maxPhotoDimensions = self.max12MPDimension
                settings.maxPhotoDimensions = self.max12MPDimension
            } else {
                if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    settings = AVCapturePhotoSettings()
                }
                
                if want48MP, let d48 = self.max48MPDimension {
                    self.photoOutput.maxPhotoDimensions = d48
                    settings.maxPhotoDimensions = d48
                    settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
                } else {
                    self.photoOutput.maxPhotoDimensions = self.max12MPDimension
                    settings.maxPhotoDimensions = self.max12MPDimension
                    settings.photoQualityPrioritization = isNight ? self.photoOutput.maxPhotoQualityPrioritization : .balanced
                }
            }
            
            if self.photoOutput.supportedFlashModes.contains(.on) {
                settings.flashMode = useFlash ? .on : .off
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.use48MPMode = false
                self.useRAWCapture = false
                self.statusMessage = "12MP (\(error.localizedDescription.prefix(10)))"
                self.isProcessing = false
            }
            return
        }
        
        if self.useRAWCapture && !self.use48MPMode && self.currentZoom == 1.0 && !photo.isRawPhoto && !self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR"
                self.isProcessing = false
            }
            return
        }
        
        let wasRAW = photo.isRawPhoto
        let photoMeta = photo.metadata
        let profile = self.selectedProfile
        let sCurve = self.contrastSCurve
        let bloom = self.bloomIntensity
        let grain = self.grainIntensity
        let vignette = self.vignetteIntensity
        let warmth = self.warmth
        let portrait = self.portraitDepthBlur
        let night = self.nightModeEnabled
        let leak = self.lightLeakEnabled
        let anamorphic = self.anamorphicMode
        let stamp = self.dateStampEnabled
        let ratio = self.aspectRatio
        let frame = self.frameStyle
        let angle = self.physicalOrientation
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                rawMetadata: photoMeta,
                wasCapturedAsRAW: wasRAW,
                profile: profile,
                contrastSCurve: sCurve,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vignette,
                warmthAdjust: warmth,
                exposureAdjust: 0.0,
                portraitDepthBlur: portrait,
                nightModeBoost: night,
                lightLeakEnabled: leak,
                anamorphicMode: anamorphic,
                dateStampEnabled: stamp,
                aspectRatio: ratio,
                frameStyle: frame,
                deviceOrientation: angle
            )
            
            if let jpegData = result.jpegData {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                }, completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        if success {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            self.statusMessage = result.status
                            self.lastExifSummary = result.exifSummary
                        } else if let preview = result.previewImage {
                            UIImageWriteToSavedPhotosAlbum(preview, nil, nil, nil)
                            self.statusMessage = "GUARDADA"
                        }
                    }
                })
            }
            
            await MainActor.run {
                self.capturedImage = result.previewImage
                self.isProcessing = false
            }
        }
    }
}

// MARK: - 4. Visor Óptico + Botón Físico Camera Control (AVCaptureEventInteraction)
struct NativeCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var onTapFocus: (CGPoint, CGPoint) -> Void
    var onHardwareShutter: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        
        if #available(iOS 17.2, *) {
            let eventInteraction = AVCaptureEventInteraction { event in
                if event.phase == .ended {
                    DispatchQueue.main.async {
                        onHardwareShutter()
                    }
                }
            }
            view.addInteraction(eventInteraction)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onTapFocus: onTapFocus) }
    
    class Coordinator: NSObject {
        var onTapFocus: (CGPoint, CGPoint) -> Void
        init(onTapFocus: @escaping (CGPoint, CGPoint) -> Void) { self.onTapFocus = onTapFocus }
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let view = sender.view as? PreviewView else { return }
            let pt = sender.location(in: view)
            let devicePt = view.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: pt)
            onTapFocus(devicePt, pt)
        }
    }
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - 5. Capa de Previsualización Fiel en Vivo
struct LiveOpticalEffectsView: View {
    let profile: FilmProfile
    let contrastSCurve: Float
    let vignetteIntensity: Float
    let grainIntensity: Float
    let bloomIntensity: Float
    let warmth: Float
    let portraitDepthBlur: Float
    let lightLeakEnabled: Bool
    let anamorphicMode: Bool
    let dateStampEnabled: Bool
    let frameStyle: FrameStyleOption
    
    private var currentDateStamp: String {
        let df = DateFormatter()
        df.dateFormat = "''yy MM dd"
        return df.string(from: Date())
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                filmLiveOverlay(for: profile)
                
                if abs(warmth) > 0.02 {
                    (warmth > 0
                        ? Color(red: 1.0, green: 0.72, blue: 0.28)
                        : Color(red: 0.25, green: 0.70, blue: 1.0))
                        .opacity(Double(abs(warmth)) * 0.20)
                        .blendMode(.softLight)
                }
                
                if portraitDepthBlur > 0.05 {
                    RadialGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(Double(portraitDepthBlur) * 0.15),
                            Color(white: 0.12).opacity(Double(portraitDepthBlur) * 0.45)
                        ],
                        center: .center,
                        startRadius: min(geo.size.width, geo.size.height) * 0.26,
                        endRadius: max(geo.size.width, geo.size.height) * 0.60
                    )
                    .blendMode(.softLight)
                }
                
                if bloomIntensity > 0.04 {
                    RadialGradient(
                        colors: [
                            profile.badgeColor.opacity(Double(bloomIntensity) * 0.22),
                            Color(red: 1.0, green: 0.42, blue: 0.12).opacity(Double(bloomIntensity) * 0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: geo.size.width * 0.78
                    )
                    .blendMode(.screen)
                }
                
                if lightLeakEnabled {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.28, blue: 0.02).opacity(0.55),
                            Color(red: 1.0, green: 0.65, blue: 0.10).opacity(0.22),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                    .blendMode(.screen)
                }
                
                if anamorphicMode {
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.55, blue: 1.0).opacity(0.35),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.screen)
                    .frame(height: 14)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                }
                
                RadialGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(Double(vignetteIntensity) * 0.42 + Double(contrastSCurve) * 0.08),
                        Color.black.opacity(min(0.92, Double(vignetteIntensity) * 0.92 + Double(contrastSCurve) * 0.15))
                    ],
                    center: .center,
                    startRadius: min(geo.size.width, geo.size.height) * CGFloat(0.46 - Double(vignetteIntensity) * 0.16),
                    endRadius: max(geo.size.width, geo.size.height) * 0.72
                )
                
                if grainIntensity > 0.02 {
                    TimelineView(.periodic(from: .now, by: 0.09)) { timeline in
                        Canvas { context, size in
                            let seed = Int(timeline.date.timeIntervalSinceReferenceDate * 14)
                            let count = Int(420 * grainIntensity)
                            var rng = SeededRandomGenerator(seed: UInt64(abs(seed) + 1))
                            for _ in 0..<count {
                                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                                let isBright = Bool.random(using: &rng)
                                let rect = CGRect(x: x, y: y, width: 1.8, height: 1.8)
                                context.fill(
                                    Path(ellipseIn: rect),
                                    with: .color((isBright ? Color.white : Color.black).opacity(Double(grainIntensity) * 0.30))
                                )
                            }
                        }
                    }
                    .blendMode(.overlay)
                }
                
                if frameStyle != .none {
                    Rectangle()
                        .stroke(
                            frameStyle == .polaroidWhite ? Color(red: 0.97, green: 0.96, blue: 0.93) : Color(white: 0.08),
                            lineWidth: 14
                        )
                }
                
                if dateStampEnabled {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(currentDateStamp)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.14))
                                .shadow(color: Color(red: 1.0, green: 0.15, blue: 0.0).opacity(0.9), radius: 5)
                                .padding(.trailing, 18)
                                .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func filmLiveOverlay(for profile: FilmProfile) -> some View {
        switch profile {
        case .ocamMaster:
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.78, blue: 0.38).opacity(0.18),
                    Color(red: 0.85, green: 0.55, blue: 0.25).opacity(0.10),
                    Color(red: 0.05, green: 0.18, blue: 0.14).opacity(0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .nocturnaClub:
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.45, blue: 0.18).opacity(0.20),
                    Color(red: 0.08, green: 0.22, blue: 0.45).opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)
        case .portra400:
            Color(red: 1.0, green: 0.68, blue: 0.35).opacity(0.15).blendMode(.softLight)
        case .cinestill800T:
            Color(red: 0.15, green: 0.65, blue: 0.95).opacity(0.14).blendMode(.colorBurn)
        case .dispo98:
            Color(red: 0.25, green: 0.95, blue: 0.55).opacity(0.12).blendMode(.softLight)
        case .ccd2004:
            Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.10).blendMode(.overlay)
        case .polaroid600:
            Color(red: 1.0, green: 0.76, blue: 0.52).opacity(0.18).blendMode(.softLight)
        case .superia400:
            Color(red: 0.15, green: 0.85, blue: 0.45).opacity(0.11).blendMode(.softLight)
        case .velvia50:
            Color(red: 0.95, green: 0.35, blue: 0.25).opacity(0.10).blendMode(.softLight)
        case .gold200:
            Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.18).blendMode(.softLight)
        case .bleachBypass, .triX400:
            Color.clear
        }
    }
}

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - 6. Laboratorio oCam Studio
struct GalleryDarkroomView: View {
    let originalData: Data
    var onSaveSuccess: (UIImage, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfile: FilmProfile = .ocamMaster
    @State private var activeTab: Int = 0
    @State private var exposureAdjust: Float = -0.15
    @State private var contrastSCurve: Float = 0.72
    @State private var warmthAdjust: Float = 0.28
    @State private var bloomAmount: Float = 0.42
    @State private var grainAmount: Float = 0.28
    @State private var vignetteAmount: Float = 0.28
    @State private var portraitDepthBlur: Float = 0.0
    @State private var lightLeakEnabled = false
    @State private var dateStampEnabled = false
    @State private var aspectRatio: AspectRatioOption = .fourThree
    @State private var frameStyle: FrameStyleOption = .none
    @State private var previewImage: UIImage?
    @State private var scaledCIImage: CIImage?
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedProfile.badgeColor, in: Capsule())
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Recomendado (\(selectedProfile.rawValue))", systemImage: "sparkles") {
                            let rec = selectedProfile.recommended
                            exposureAdjust = 0.0
                            contrastSCurve = rec.contrastSCurve
                            warmthAdjust = rec.warmth
                            bloomAmount = rec.bloom
                            grainAmount = rec.grain
                            vignetteAmount = rec.vignette
                            updatePreview()
                        }
                        Button("Restablecer a Cero", systemImage: "arrow.counterclockwise") {
                            exposureAdjust = 0.0
                            contrastSCurve = 0.35
                            warmthAdjust = 0.0
                            bloomAmount = 0.0
                            grainAmount = 0.0
                            vignetteAmount = 0.0
                            portraitDepthBlur = 0.0
                            updatePreview()
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        saveDevelopedGalleryPhoto()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13, weight: .bold))
                            Text(isSaving ? "..." : "Guardar")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(white: 0.05))
                    
                    if let preview = previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(8)
                    } else {
                        ProgressView().tint(.white)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("oCam Studio • \(selectedProfile.rawValue)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("S-Curve \(String(format: "%.2f", contrastSCurve * 4.0)) | f/1.6 | P3 DNG")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 12)
                
                VStack(spacing: 12) {
                    if activeTab == 0 {
                        darkroomSlider(title: "S-Curve Contrast", value: $contrastSCurve, range: 0.0...1.0, format: "%.2f", multiplier: 4.0)
                        darkroomSlider(title: "Exposure (EV)", value: $exposureAdjust, range: -1.5...1.5, format: "%+.2f")
                        darkroomSlider(title: "Portrait Bokeh", value: $portraitDepthBlur, range: 0.0...1.0, format: "f/%.1f", multiplier: 1.4)
                    } else if activeTab == 1 {
                        darkroomSlider(title: "Warmth (Golden)", value: $warmthAdjust, range: -1.0...1.0, format: "%+.2f")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FilmProfile.allCases) { profile in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedProfile = profile
                                        let rec = profile.recommended
                                        contrastSCurve = rec.contrastSCurve
                                        warmthAdjust = rec.warmth
                                        bloomAmount = rec.bloom
                                        grainAmount = rec.grain
                                        vignetteAmount = rec.vignette
                                        updatePreview()
                                    } label: {
                                        Text(profile.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(selectedProfile == profile ? .black : .white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedProfile == profile ? profile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                                    }
                                }
                            }
                        }
                    } else if activeTab == 2 {
                        darkroomSlider(title: "35mm Film Grain", value: $grainAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Halation Glow", value: $bloomAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Optical Vignette", value: $vignetteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                    } else {
                        HStack(spacing: 8) {
                            ForEach(AspectRatioOption.allCases, id: \.self) { ratio in
                                Button {
                                    aspectRatio = ratio
                                    updatePreview()
                                } label: {
                                    Text(ratio.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(aspectRatio == ratio ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(aspectRatio == ratio ? selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                                }
                            }
                        }
                        HStack(spacing: 8) {
                            Button {
                                dateStampEnabled.toggle()
                                updatePreview()
                            } label: {
                                Label("Fecha '98", systemImage: "calendar")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(dateStampEnabled ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(dateStampEnabled ? selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                            }
                            Button {
                                lightLeakEnabled.toggle()
                                updatePreview()
                            } label: {
                                Label("Light Leak", systemImage: "sun.max.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(lightLeakEnabled ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(lightLeakEnabled ? selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                            }
                            Button {
                                let all = FrameStyleOption.allCases
                                if let idx = all.firstIndex(of: frameStyle) {
                                    frameStyle = all[(idx + 1) % all.count]
                                    updatePreview()
                                }
                            } label: {
                                Text(frameStyle.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(frameStyle != .none ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(frameStyle != .none ? selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 0.7))
                .padding(.horizontal, 14)
                
                HStack(spacing: 16) {
                    studioTabButton(index: 0, icon: "chart.xyaxis.line", title: "Tone")
                    studioTabButton(index: 1, icon: "paintpalette", title: "Color")
                    studioTabButton(index: 2, icon: "sparkles", title: "Texture")
                    studioTabButton(index: 3, icon: "crop", title: "Crop")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            prepareScaledPreviewInput()
        }
    }
    
    @ViewBuilder
    private func studioTabButton(index: Int, icon: String, title: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                activeTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(activeTab == index ? selectedProfile.badgeColor : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(activeTab == index ? Color.white.opacity(0.12) : Color.clear, in: Capsule())
        }
    }
    
    @ViewBuilder
    private func darkroomSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String, multiplier: Float = 1.0) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(String(format: format, value.wrappedValue * multiplier))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(selectedProfile.badgeColor)
            }
            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { newVal in
                    value.wrappedValue = newVal
                    updatePreview()
                }
            ), in: range)
            .tint(selectedProfile.badgeColor)
        }
    }
    
    private func prepareScaledPreviewInput() {
        Task.detached(priority: .userInitiated) {
            guard var ci = CIImage(data: originalData, options: [.applyOrientationProperty: true]) else { return }
            ci = ci.transformed(by: CGAffineTransform(translationX: -ci.extent.origin.x, y: -ci.extent.origin.y))
            let maxDim = max(ci.extent.width, ci.extent.height)
            if maxDim > 1200 {
                let scale = 1200.0 / maxDim
                ci = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }
            let finalCI = ci
            await MainActor.run {
                self.scaledCIImage = finalCI
                self.updatePreview()
            }
        }
    }
    
    private func updatePreview() {
        guard let baseCI = scaledCIImage else { return }
        let prof = selectedProfile
        let sCurve = contrastSCurve
        let bloom = bloomAmount
        let grain = grainAmount
        let vig = vignetteAmount
        let warm = warmthAdjust
        let exp = exposureAdjust
        let port = portraitDepthBlur
        let leak = lightLeakEnabled
        let stamp = dateStampEnabled
        let ratio = aspectRatio
        let frame = frameStyle
        
        Task.detached(priority: .userInteractive) {
            guard var img = CinematicPipeline.shared.renderPreviewUIImage(
                from: baseCI,
                profile: prof,
                contrastSCurve: sCurve,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                warmthAdjust: warm,
                exposureAdjust: exp,
                portraitDepthBlur: port,
                lightLeakEnabled: leak,
                anamorphicMode: false
            ) else { return }
            
            if ratio != .fourThree || stamp || frame != .none {
                img = CinematicPipeline.shared.applyFinalTouches(
                    to: img,
                    aspectRatio: ratio,
                    frameStyle: frame,
                    dateStampEnabled: stamp
                )
            }
            let finalPreview = img
            await MainActor.run {
                self.previewImage = finalPreview
            }
        }
    }
    
    private func saveDevelopedGalleryPhoto() {
        isSaving = true
        let prof = selectedProfile
        let sCurve = contrastSCurve
        let bloom = bloomAmount
        let grain = grainAmount
        let vig = vignetteAmount
        let warm = warmthAdjust
        let exp = exposureAdjust
        let port = portraitDepthBlur
        let leak = lightLeakEnabled
        let stamp = dateStampEnabled
        let ratio = aspectRatio
        let frame = frameStyle
        let rawData = originalData
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: rawData,
                rawMetadata: nil,
                wasCapturedAsRAW: true,
                profile: prof,
                contrastSCurve: sCurve,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                warmthAdjust: warm,
                exposureAdjust: exp,
                portraitDepthBlur: port,
                nightModeBoost: prof == .nocturnaClub,
                lightLeakEnabled: leak,
                anamorphicMode: false,
                dateStampEnabled: stamp,
                aspectRatio: ratio,
                frameStyle: frame,
                deviceOrientation: .portrait,
                isFromGallery: true
            )
            
            if let jpegData = result.jpegData {
                PHPhotoLibrary.shared().performChanges({
                    let req = PHAssetCreationRequest.forAsset()
                    req.addResource(with: .photo, data: jpegData, options: nil)
                }, completionHandler: { _, _ in })
            }
            
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.isSaving = false
                if let img = result.previewImage {
                    onSaveSuccess(img, "oCam \(result.status)")
                }
                dismiss()
            }
        }
    }
}

// MARK: - 7. Interfaz Principal oCam con Liquid Glass de Apple
struct GridOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: (w / 3) * 2, y: 0))
                path.addLine(to: CGPoint(x: (w / 3) * 2, y: h))
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: (h / 3) * 2))
                path.addLine(to: CGPoint(x: w, y: (h / 3) * 2))
            }
            .stroke(Color.white.opacity(0.20), lineWidth: 0.6)
        }
        .allowsHitTesting(false)
    }
}

struct ContentView: View {
    @State private var camera = CameraManager()
    @State private var showTray = false
    @State private var showExposureBar = false
    @State private var activeDrawerTab: Int = 0
    @State private var showFullPreview = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedPhotoData: Data?
    @State private var showDarkroom = false
    
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0]
    
    private var modeButtonTitle: String {
        if camera.currentZoom != 1.0 { return "12MP" }
        if camera.use48MPMode && camera.is48MPSupported { return "48MP" }
        if camera.useRAWCapture { return "RAW" }
        return "12MP"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 10) {
                // 1. Barra Superior Minimalista Liquid Glass
                HStack(spacing: 10) {
                    Button {
                        camera.toggleSensorMode()
                    } label: {
                        Text(modeButtonTitle)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(camera.useRAWCapture || camera.use48MPMode ? camera.selectedProfile.badgeColor : Color.white.opacity(0.15), in: Capsule())
                            .foregroundStyle(camera.useRAWCapture || camera.use48MPMode ? .black : .white)
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.nightModeEnabled.toggle()
                        camera.updateNightModeHardware()
                    } label: {
                        Image(systemName: camera.nightModeEnabled ? "moon.stars.fill" : "moon")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(camera.nightModeEnabled ? .black : .white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(camera.nightModeEnabled ? Color.yellow : Color.white.opacity(0.12), in: Circle())
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            camera.portraitDepthBlur = (camera.portraitDepthBlur > 0.05) ? 0.0 : 0.65
                        }
                    } label: {
                        Text("f")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .italic()
                            .foregroundStyle(camera.portraitDepthBlur > 0.05 ? .black : .white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(camera.portraitDepthBlur > 0.05 ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Circle())
                    }
                    
                    Spacer()
                    
                    Text("oCam")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showExposureBar.toggle()
                            if showExposureBar { showTray = false }
                        }
                    } label: {
                        Image(systemName: "plusminus.circle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(showExposureBar || abs(camera.exposureEV + 0.45) > 0.05 ? camera.selectedProfile.badgeColor : .white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.flashEnabled.toggle()
                    } label: {
                        Image(systemName: camera.flashEnabled ? "bolt.fill" : "bolt.slash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(camera.flashEnabled ? .yellow : .white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showTray.toggle()
                            if showTray { showExposureBar = false }
                        }
                    } label: {
                        Image(systemName: showTray ? "chevron.down" : "chevron.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(showTray ? .black : .white)
                            .frame(width: 32, height: 32)
                            .background(showTray ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.6))
                .padding(.horizontal, 14)
                
                // 2. Visor Principal con Previsualización Real de Relación de Aspecto
                GeometryReader { outerGeo in
                    let availW = outerGeo.size.width
                    let availH = outerGeo.size.height
                    let targetRatio = camera.aspectRatio.portraitRatio
                    let frameW = min(availW, availH * targetRatio)
                    let frameH = min(availH, frameW / targetRatio)
                    
                    ZStack {
                        ZStack {
                            NativeCameraPreview(
                                session: camera.session,
                                onTapFocus: { devicePt, viewPt in
                                    camera.focusAt(normalizedPoint: devicePt, viewPoint: viewPt)
                                },
                                onHardwareShutter: {
                                    camera.triggerShutter()
                                }
                            )
                            .contrast(liveContrast(for: camera.selectedProfile) + Double(camera.contrastSCurve) * 0.14)
                            .saturation(liveSaturation(for: camera.selectedProfile))
                            
                            LiveOpticalEffectsView(
                                profile: camera.selectedProfile,
                                contrastSCurve: camera.contrastSCurve,
                                vignetteIntensity: camera.vignetteIntensity,
                                grainIntensity: camera.grainIntensity,
                                bloomIntensity: camera.bloomIntensity,
                                warmth: camera.warmth,
                                portraitDepthBlur: camera.portraitDepthBlur,
                                lightLeakEnabled: camera.lightLeakEnabled,
                                anamorphicMode: camera.anamorphicMode,
                                dateStampEnabled: camera.dateStampEnabled,
                                frameStyle: camera.frameStyle
                            )
                            
                            if camera.showGrid {
                                GridOverlayView()
                            }
                            
                            if let pt = camera.focusPoint {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(camera.selectedProfile.badgeColor, lineWidth: 1.5)
                                    .frame(width: 60, height: 60)
                                    .position(pt)
                            }
                            
                            if camera.countdownRemaining > 0 {
                                Text("\(camera.countdownRemaining)")
                                    .font(.system(size: 72, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 10)
                            }
                        }
                        .frame(width: frameW, height: frameH)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: camera.aspectRatio)
                        
                        VStack {
                            HStack {
                                Text("\(camera.selectedProfile.rawValue) • \(camera.statusMessage)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                            
                            if showExposureBar {
                                HStack(spacing: 12) {
                                    Image(systemName: "sun.min.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.7))
                                    Slider(value: Binding(
                                        get: { camera.exposureEV },
                                        set: { camera.setExposure($0) }
                                    ), in: -2.0...1.5)
                                    .tint(camera.selectedProfile.badgeColor)
                                    Text(String(format: "%+.1f EV", camera.exposureEV))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(camera.selectedProfile.badgeColor)
                                        .frame(width: 54)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.6))
                                .padding(.horizontal, 24)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            if showTray {
                                VStack(spacing: 10) {
                                    HStack(spacing: 8) {
                                        trayTabPill(index: 0, title: "Tone & EV")
                                        trayTabPill(index: 1, title: "Film & Grain")
                                        trayTabPill(index: 2, title: "Ratio & Retro")
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Button("Recomendado para \(camera.selectedProfile.rawValue)", systemImage: "sparkles") {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                camera.applyRecommendedForCurrentProfile()
                                            }
                                            Button("Por defecto (Neutro)", systemImage: "arrow.counterclockwise") {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                camera.resetToNeutral()
                                            }
                                        } label: {
                                            HStack(spacing: 3) {
                                                Image(systemName: "arrow.uturn.backward")
                                                Text("Reset")
                                            }
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 5)
                                            .background(camera.selectedProfile.badgeColor, in: Capsule())
                                        }
                                    }
                                    
                                    if activeDrawerTab == 0 {
                                        glassSliderRow(title: "EXPOSICIÓN", value: Binding(
                                            get: { camera.exposureEV },
                                            set: { camera.setExposure($0) }
                                        ), range: -2.0...1.5, text: String(format: "%+.1f EV", camera.exposureEV))
                                        
                                        glassSliderRow(title: "S-CURVE", value: $camera.contrastSCurve, range: 0.0...1.0, text: String(format: "%.2f", camera.contrastSCurve * 4.0))
                                        
                                        glassSliderRow(title: "CALIDEZ", value: $camera.warmth, range: -1.0...1.0, text: String(format: "%+.1f", camera.warmth))
                                    } else if activeDrawerTab == 1 {
                                        glassSliderRow(title: "GRANO 35MM", value: $camera.grainIntensity, range: 0.0...1.0, text: "\(Int(camera.grainIntensity * 100))%")
                                        
                                        glassSliderRow(title: "HALATION", value: $camera.bloomIntensity, range: 0.0...1.0, text: "\(Int(camera.bloomIntensity * 100))%")
                                        
                                        glassSliderRow(title: "VIÑETEADO", value: $camera.vignetteIntensity, range: 0.0...1.0, text: "\(Int(camera.vignetteIntensity * 100))%")
                                    } else {
                                        HStack(spacing: 6) {
                                            ForEach(AspectRatioOption.allCases, id: \.self) { ratio in
                                                Button {
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    camera.aspectRatio = ratio
                                                } label: {
                                                    Text(ratio.rawValue)
                                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                                        .foregroundStyle(camera.aspectRatio == ratio ? .black : .white)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 6)
                                                        .background(camera.aspectRatio == ratio ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                                                }
                                            }
                                        }
                                        
                                        HStack(spacing: 6) {
                                            Button {
                                                camera.dateStampEnabled.toggle()
                                            } label: {
                                                Text(camera.dateStampEnabled ? "FECHA '98: ON" : "FECHA '98")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(camera.dateStampEnabled ? .black : .white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(camera.dateStampEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                                            }
                                            
                                            Button {
                                                camera.lightLeakEnabled.toggle()
                                            } label: {
                                                Text(camera.lightLeakEnabled ? "LEAK: ON" : "LIGHT LEAK")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(camera.lightLeakEnabled ? .black : .white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(camera.lightLeakEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                                            }
                                            
                                            Button {
                                                let all = FrameStyleOption.allCases
                                                if let idx = all.firstIndex(of: camera.frameStyle) {
                                                    camera.frameStyle = all[(idx + 1) % all.count]
                                                }
                                            } label: {
                                                Text(camera.frameStyle.rawValue)
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(camera.frameStyle != .none ? .black : .white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(camera.frameStyle != .none ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Capsule())
                                            }
                                            
                                            Button {
                                                camera.showGrid.toggle()
                                            } label: {
                                                Image(systemName: "squareshape.split.3x3")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(camera.showGrid ? .black : .white)
                                                    .padding(6)
                                                    .background(camera.showGrid ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12), in: Circle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.18), lineWidth: 0.7))
                                .padding(.horizontal, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            HStack(spacing: 6) {
                                ForEach(zoomLevels, id: \.self) { level in
                                    Button {
                                        camera.switchCameraLens(factor: level)
                                    } label: {
                                        Text(level == 0.5 ? ".5" : "\(Int(level))×")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(camera.currentZoom == level ? camera.selectedProfile.badgeColor : .white)
                                            .frame(width: 34, height: 34)
                                            .background(camera.currentZoom == level ? Color.black.opacity(0.65) : Color.clear, in: Circle())
                                    }
                                }
                            }
                            .padding(4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.5))
                            .padding(.bottom, 8)
                        }
                    }
                    .frame(width: availW, height: availH)
                }
                
                // 3. Selector de Cámaras en Cápsulas Liquid Glass
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilmProfile.allCases) { profile in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    camera.selectProfile(profile)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(camera.selectedProfile == profile ? .black : profile.badgeColor)
                                        .frame(width: 7, height: 7)
                                    Text(profile.rawValue)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(camera.selectedProfile == profile ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    camera.selectedProfile == profile
                                        ? profile.badgeColor
                                        : Color.white.opacity(0.12),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(camera.selectedProfile == profile ? 0.0 : 0.14), lineWidth: 0.6)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // 4. Barra de Obturador Liquid Glass
                HStack {
                    Button {
                        if camera.capturedImage != nil {
                            showFullPreview = true
                        }
                    } label: {
                        if let lastPhoto = camera.capturedImage {
                            Image(uiImage: lastPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.35), lineWidth: 1))
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white.opacity(0.6))
                                )
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.14), lineWidth: 0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        camera.triggerShutter()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(camera.selectedProfile.badgeColor, lineWidth: 3.5)
                                .frame(width: 76, height: 76)
                            Circle()
                                .fill(camera.isProcessing ? camera.selectedProfile.badgeColor : Color.white)
                                .frame(width: 64, height: 64)
                                .scaleEffect(camera.isProcessing ? 0.88 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: camera.isProcessing)
                        }
                    }
                    .disabled(camera.isProcessing)
                    
                    Spacer()
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 2) {
                            Image(systemName: "slider.horizontal.below.rectangle")
                                .font(.system(size: 17, weight: .semibold))
                            Text("STUDIO")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(camera.selectedProfile.badgeColor.opacity(0.55), lineWidth: 0.9)
                        )
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 12)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        self.importedPhotoData = data
                        self.selectedPhotoItem = nil
                        self.showDarkroom = true
                    }
                }
            }
        }
        .sheet(isPresented: $showDarkroom) {
            if let data = importedPhotoData {
                GalleryDarkroomView(originalData: data) { savedImg, msg in
                    camera.capturedImage = savedImg
                    camera.statusMessage = msg
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showFullPreview) {
            if let img = camera.capturedImage {
                ZStack(alignment: .top) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("oCam • \(camera.selectedProfile.rawValue)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text(camera.lastExifSummary)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        
                        Spacer()
                        
                        Button("Done") {
                            showFullPreview = false
                        }
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(camera.selectedProfile.badgeColor, in: Capsule())
                        .foregroundStyle(.black)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func trayTabPill(index: Int, title: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                activeDrawerTab = index
            }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(activeDrawerTab == index ? .black : .white.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(activeDrawerTab == index ? Color.white : Color.white.opacity(0.12), in: Capsule())
        }
    }
    
    @ViewBuilder
    private func glassSliderRow(title: String, value: Binding<Float>, range: ClosedRange<Float>, text: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 72, alignment: .leading)
            Slider(value: value, in: range)
                .tint(camera.selectedProfile.badgeColor)
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(camera.selectedProfile.badgeColor)
                .frame(width: 48, alignment: .trailing)
        }
    }
    
    private func liveContrast(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400, .bleachBypass: return 1.24
        case .ocamMaster, .nocturnaClub: return 1.15
        case .polaroid600: return 0.96
        default: return 1.12
        }
    }
    
    private func liveSaturation(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400: return 0.0
        case .bleachBypass: return 0.48
        case .velvia50, .ccd2004: return 1.24
        case .ocamMaster, .portra400, .gold200, .nocturnaClub: return 1.10
        default: return 0.98
        }
    }
}
// FIN DEL ARCHIVO
