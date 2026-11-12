import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMotion
import Photos
import PhotosUI
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

// MARK: - 1. Catálogo de 12 Cámaras Cinematográficas y Retro
enum FilmProfile: String, CaseIterable, Identifiable {
    case chromagraph = "Chroma"
    case portra400 = "Portra 400"
    case cinestill800T = "800T"
    case dispo98 = "Dispo 98"
    case ccd2004 = "CCD 2004"
    case polaroid600 = "Polaroid"
    case superia400 = "Superia"
    case velvia50 = "Velvia 50"
    case gold200 = "Gold 200"
    case ektachrome = "E100"
    case bleachBypass = "Bleach"
    case triX400 = "Tri-X B&W"
    
    var id: String { self.rawValue }
    
    var subtitle: String {
        switch self {
        case .chromagraph: return "CINE PIPELINE"
        case .portra400: return "WARM SKIN"
        case .cinestill800T: return "TUNGSTEN NIGHT"
        case .dispo98: return "90s DISPOSABLE"
        case .ccd2004: return "Y2K DIGICAM"
        case .polaroid600: return "INSTANT FILM"
        case .superia400: return "FUJI EMERALD"
        case .velvia50: return "VIVID SLIDE"
        case .gold200: return "VINTAGE GOLD"
        case .ektachrome: return "CLEAN CHROME"
        case .bleachBypass: return "SILVER GRIT"
        case .triX400: return "MONO 400"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .chromagraph: return Color(red: 0.90, green: 0.74, blue: 0.45)
        case .portra400: return Color(red: 0.95, green: 0.58, blue: 0.35)
        case .cinestill800T: return Color(red: 0.32, green: 0.78, blue: 0.94)
        case .dispo98: return Color(red: 0.45, green: 0.92, blue: 0.62)
        case .ccd2004: return Color(red: 0.78, green: 0.62, blue: 0.98)
        case .polaroid600: return Color(red: 0.96, green: 0.76, blue: 0.64)
        case .superia400: return Color(red: 0.30, green: 0.85, blue: 0.55)
        case .velvia50: return Color(red: 0.96, green: 0.42, blue: 0.42)
        case .gold200: return Color(red: 0.98, green: 0.82, blue: 0.28)
        case .ektachrome: return Color(red: 0.55, green: 0.72, blue: 0.98)
        case .bleachBypass: return Color(red: 0.72, green: 0.78, blue: 0.80)
        case .triX400: return Color(white: 0.88)
        }
    }
}

enum AspectRatioOption: String, CaseIterable {
    case fourThree = "4:3"
    case oneOne = "1:1"
    case sixteenNine = "16:9"
}

enum FrameStyleOption: String, CaseIterable {
    case none = "Sin Marco"
    case polaroidWhite = "Blanco"
    case filmBlack = "Cine Negro"
}

struct DevelopedPhotoResult {
    let jpegData: Data?
    let previewImage: UIImage?
    let status: String
}

// MARK: - 2. Motor de Revelado Cinematográfico + Efectos Ópticos Retro
class CinematicPipeline {
    static let shared = CinematicPipeline()
    
    private let ciContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        .workingFormat: CIFormat.RGBA8,
        .cacheIntermediates: false,
        .priorityRequestLow: false
    ])
    
    func applyCinematicLook(
        to input: CIImage,
        profile: FilmProfile,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float = 0.0,
        exposureAdjust: Float = 0.0,
        lightLeakEnabled: Bool = false,
        isRAW: Bool,
        is48MP: Bool
    ) -> CIImage {
        var current = input
        let extent = current.extent
        guard extent.width > 0, extent.height > 0 else { return input }
        
        // 0. Ajuste de Exposición
        if abs(exposureAdjust) > 0.02 {
            let exp = CIFilter.exposureAdjust()
            exp.inputImage = current
            exp.ev = exposureAdjust
            if let out = exp.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 1. Neutralizar dominante verde RGGB en RAW + Ajuste manual de Calidez (WB)
        if isRAW || abs(warmthAdjust) > 0.02 {
            let wbFix = CIFilter.temperatureAndTint()
            wbFix.inputImage = current
            wbFix.neutral = CIVector(x: 6200, y: 0)
            let baseTemp: CGFloat = isRAW ? 5750 : 6200
            let tempShift = CGFloat(-warmthAdjust * 1400) // Más cálido reduce targetNeutral
            let tintShift: CGFloat = isRAW ? 20 : 0
            wbFix.targetNeutral = CIVector(x: baseTemp + tempShift, y: tintShift)
            if let out = wbFix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 2. Compresión suave de Altas Luces (Highlight Roll-off)
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        hs.highlightAmount = isRAW ? 0.25 : 0.36
        hs.shadowAmount = isRAW ? 0.42 : 0.25
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 3. Curvas de Cine y Matrices de las 12 Cámaras
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        switch profile {
        case .chromagraph:
            curve.point0 = CGPoint(x: 0.00, y: 0.03)
            curve.point1 = CGPoint(x: 0.24, y: 0.19)
            curve.point2 = CGPoint(x: 0.50, y: 0.51)
            curve.point3 = CGPoint(x: 0.76, y: 0.79)
            curve.point4 = CGPoint(x: 1.00, y: 0.92)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.06, y: 0.01, z: -0.01, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.99, z: 0.00, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: 0.01, z: 0.95, w: 0)
            matrix.biasVector = CIVector(x: 0.005, y: -0.005, z: 0.00, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .portra400:
            curve.point0 = CGPoint(x: 0.00, y: 0.05)
            curve.point1 = CGPoint(x: 0.25, y: 0.22)
            curve.point2 = CGPoint(x: 0.50, y: 0.54)
            curve.point3 = CGPoint(x: 0.75, y: 0.81)
            curve.point4 = CGPoint(x: 1.00, y: 0.94)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.12, y: 0.02, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.01, y: 1.00, z: -0.01, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: -0.01, z: 0.90, w: 0)
            matrix.biasVector = CIVector(x: 0.01, y: -0.004, z: -0.008, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .cinestill800T:
            curve.point0 = CGPoint(x: 0.00, y: 0.03)
            curve.point1 = CGPoint(x: 0.25, y: 0.17)
            curve.point2 = CGPoint(x: 0.50, y: 0.49)
            curve.point3 = CGPoint(x: 0.75, y: 0.80)
            curve.point4 = CGPoint(x: 1.00, y: 0.94)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 0.95, y: 0.00, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.99, z: 0.03, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: 0.04, z: 1.12, w: 0)
            matrix.biasVector = CIVector(x: -0.01, y: 0.00, z: 0.02, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .dispo98:
            // Cámara desechable años 90: negros lavados verdosos, altas luces cálidas, contraste punchy
            curve.point0 = CGPoint(x: 0.00, y: 0.08)
            curve.point1 = CGPoint(x: 0.25, y: 0.20)
            curve.point2 = CGPoint(x: 0.50, y: 0.53)
            curve.point3 = CGPoint(x: 0.75, y: 0.82)
            curve.point4 = CGPoint(x: 1.00, y: 0.93)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.08, y: 0.04, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.06, z: 0.02, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.03, z: 0.88, w: 0)
            matrix.biasVector = CIVector(x: 0.00, y: 0.018, z: -0.01, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .ccd2004:
            // Digicam Y2K: contraste digital marcado y saturación vibrante fría/magenta
            let controls = CIFilter.colorControls()
            controls.inputImage = current
            controls.saturation = 1.22
            controls.contrast = 1.12
            if let out = controls.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.05, y: 0.02, z: 0.02, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.97, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: 0.02, y: 0.01, z: 1.08, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .polaroid600:
            // Película instantánea: negros mate suaves, tonos crema/melocotón
            curve.point0 = CGPoint(x: 0.00, y: 0.09)
            curve.point1 = CGPoint(x: 0.25, y: 0.25)
            curve.point2 = CGPoint(x: 0.50, y: 0.54)
            curve.point3 = CGPoint(x: 0.75, y: 0.78)
            curve.point4 = CGPoint(x: 1.00, y: 0.90)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.10, y: 0.04, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.01, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: 0.02, z: 0.86, w: 0)
            matrix.biasVector = CIVector(x: 0.02, y: 0.008, z: -0.015, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .superia400:
            // Fuji Superia 400: Verdes esmeralda ricos y sombras ligeramente magenta
            curve.point0 = CGPoint(x: 0.00, y: 0.04)
            curve.point1 = CGPoint(x: 0.25, y: 0.20)
            curve.point2 = CGPoint(x: 0.50, y: 0.52)
            curve.point3 = CGPoint(x: 0.75, y: 0.80)
            curve.point4 = CGPoint(x: 1.00, y: 0.94)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.04, y: -0.02, z: 0.03, w: 0)
            matrix.gVector = CIVector(x: -0.01, y: 1.07, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: 0.01, y: 0.02, z: 0.96, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .velvia50:
            curve.point0 = CGPoint(x: 0.00, y: 0.01)
            curve.point1 = CGPoint(x: 0.24, y: 0.17)
            curve.point2 = CGPoint(x: 0.50, y: 0.51)
            curve.point3 = CGPoint(x: 0.76, y: 0.83)
            curve.point4 = CGPoint(x: 1.00, y: 0.96)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = current
            colorControls.saturation = 1.28
            colorControls.contrast = 1.06
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .gold200:
            curve.point0 = CGPoint(x: 0.00, y: 0.06)
            curve.point1 = CGPoint(x: 0.25, y: 0.21)
            curve.point2 = CGPoint(x: 0.50, y: 0.53)
            curve.point3 = CGPoint(x: 0.75, y: 0.80)
            curve.point4 = CGPoint(x: 1.00, y: 0.92)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.15, y: 0.03, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.04, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.06, y: -0.02, z: 0.84, w: 0)
            matrix.biasVector = CIVector(x: 0.015, y: 0.005, z: -0.02, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .ektachrome:
            curve.point0 = CGPoint(x: 0.00, y: 0.02)
            curve.point1 = CGPoint(x: 0.25, y: 0.19)
            curve.point2 = CGPoint(x: 0.50, y: 0.51)
            curve.point3 = CGPoint(x: 0.75, y: 0.81)
            curve.point4 = CGPoint(x: 1.00, y: 0.95)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 0.98, y: 0.01, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 1.02, z: 0.02, w: 0)
            matrix.bVector = CIVector(x: -0.01, y: 0.02, z: 1.08, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .bleachBypass:
            let controls = CIFilter.colorControls()
            controls.inputImage = current
            controls.saturation = 0.42
            controls.contrast = 1.18
            if let out = controls.outputImage?.cropped(to: extent) { current = out }
            
            curve.inputImage = current
            curve.point0 = CGPoint(x: 0.00, y: 0.02)
            curve.point1 = CGPoint(x: 0.25, y: 0.16)
            curve.point2 = CGPoint(x: 0.50, y: 0.49)
            curve.point3 = CGPoint(x: 0.75, y: 0.82)
            curve.point4 = CGPoint(x: 1.00, y: 0.91)
            if let out = curve.outputImage?.cropped(to: extent) { current = out }
            
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
        
        // 4. Halation / Bloom
        if !is48MP && bloomAmount > 0.05 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = 12.0
            bloom.intensity = bloomAmount * 0.55
            if let out = bloom.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 5. Viñeteado óptico regulable (Más potente para que se note claramente)
        if vignetteAmount > 0.02 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = current
            vignette.intensity = vignetteAmount * 1.65
            vignette.radius = 1.55
            if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 6. Fuga de Luz Analógica (Light Leak en el borde izquierdo/superior)
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
        
        // 7. Grano orgánico de 35mm regulable
        if grainAmount > 0.02, let noise = CIFilter.randomGenerator().outputImage {
            let grainAlpha = CGFloat(grainAmount * 0.075)
            let monoNoise = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: grainAlpha)
            ]).cropped(to: extent)
            current = monoNoise.composited(over: current).cropped(to: extent)
        }
        
        return current
    }
    
    /// Aplica recorte de formato (4:3, 1:1, 16:9), marco analógico y fechador retro de cuarzo ('26 11 12)
    func applyFinalTouches(
        to image: UIImage,
        aspectRatio: AspectRatioOption,
        frameStyle: FrameStyleOption,
        dateStampEnabled: Bool
    ) -> UIImage {
        let origW = image.size.width
        let origH = image.size.height
        let isLandscape = origW > origH
        
        // 1. Calcular recorte según formato elegido
        var targetRatio: CGFloat = 3.0 / 4.0
        switch aspectRatio {
        case .fourThree: targetRatio = isLandscape ? (4.0 / 3.0) : (3.0 / 4.0)
        case .oneOne: targetRatio = 1.0
        case .sixteenNine: targetRatio = isLandscape ? (16.0 / 9.0) : (9.0 / 16.0)
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
        
        let borderSide: CGFloat = (frameStyle == .none) ? 0 : (min(cropW, cropH) * 0.048)
        let borderBottom: CGFloat = (frameStyle == .polaroidWhite) ? (min(cropW, cropH) * 0.14) : borderSide
        let canvasW = cropW + (borderSide * 2)
        let canvasH = cropH + borderSide + borderBottom
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: canvasW, height: canvasH), format: format)
        
        return renderer.image { ctx in
            // Fondo de marco
            if frameStyle == .polaroidWhite {
                UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
            } else if frameStyle == .filmBlack {
                UIColor(white: 0.05, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
            }
            
            // Dibujar foto recortada dentro del marco
            let photoRect = CGRect(x: borderSide, y: borderSide, width: cropW, height: cropH)
            ctx.cgContext.saveGState()
            ctx.cgContext.clip(to: photoRect)
            image.draw(in: CGRect(x: borderSide - cropX, y: borderSide - cropY, width: origW, height: origH))
            ctx.cgContext.restoreGState()
            
            // Dibujar Fechador Retro de Cuarzo ('26 11 12)
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
    
    func renderPreviewUIImage(
        from ciInput: CIImage,
        profile: FilmProfile,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float,
        exposureAdjust: Float,
        lightLeakEnabled: Bool
    ) -> UIImage? {
        let filtered = applyCinematicLook(
            to: ciInput,
            profile: profile,
            bloomAmount: bloomAmount,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            warmthAdjust: warmthAdjust,
            exposureAdjust: exposureAdjust,
            lightLeakEnabled: lightLeakEnabled,
            isRAW: false,
            is48MP: false
        )
        guard let cg = ciContext.createCGImage(filtered, from: filtered.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
    
    func developFinalPhoto(
        data: Data,
        wasCapturedAsRAW: Bool,
        profile: FilmProfile,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float = 0.0,
        exposureAdjust: Float = 0.0,
        lightLeakEnabled: Bool = false,
        dateStampEnabled: Bool = false,
        aspectRatio: AspectRatioOption = .fourThree,
        frameStyle: FrameStyleOption = .none,
        deviceOrientation: UIDeviceOrientation,
        isFromGallery: Bool = false
    ) -> DevelopedPhotoResult {
        var baseImage: CIImage?
        var usedCIRAW = false
        
        let targetExifOrientation: CGImagePropertyOrientation
        switch deviceOrientation {
        case .landscapeLeft: targetExifOrientation = .up
        case .landscapeRight: targetExifOrientation = .down
        case .portraitUpsideDown: targetExifOrientation = .left
        default: targetExifOrientation = .right
        }
        
        if wasCapturedAsRAW, let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
            rawFilter.luminanceNoiseReductionAmount = 0.78
            rawFilter.colorNoiseReductionAmount = 0.92
            rawFilter.sharpnessAmount = 0.18
            rawFilter.localToneMapAmount = 0.15
            rawFilter.boostAmount = 0.45
            rawFilter.baselineExposure = -0.35
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
            return DevelopedPhotoResult(jpegData: nil, previewImage: nil, status: "ERROR AL LEER DATOS")
        }
        
        let normalizedInput = input.transformed(by: CGAffineTransform(translationX: -input.extent.origin.x, y: -input.extent.origin.y))
        let maxSide = max(normalizedInput.extent.width, normalizedInput.extent.height)
        let is48MP = maxSide > 5000
        
        let processed = applyCinematicLook(
            to: normalizedInput,
            profile: profile,
            bloomAmount: bloomAmount,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            warmthAdjust: warmthAdjust,
            exposureAdjust: exposureAdjust,
            lightLeakEnabled: lightLeakEnabled,
            isRAW: usedCIRAW,
            is48MP: is48MP
        )
        
        guard let cgImage = ciContext.createCGImage(processed, from: processed.extent) else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: nil, status: "ERROR RENDER GPU")
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
        
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.96) else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: uiImage, status: "ERROR JPEG")
        }
        
        let w = Int(uiImage.size.width)
        let h = Int(uiImage.size.height)
        let mp = max(1, Int(round((Double(w) * Double(h)) / 1_000_000.0)))
        let statusText = usedCIRAW ? "RAW \(mp)MP (\(w)x\(h))" : "CINE \(mp)MP (\(w)x\(h))"
        return DevelopedPhotoResult(jpegData: jpegData, previewImage: uiImage, status: statusText)
    }
}

// MARK: - 3. Controlador de Cámara Definitivo
@Observable
class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.chromacam.sessionQueue")
    private let motionManager = CMMotionManager()
    
    private var currentDevice: AVCaptureDevice?
    private var lastExposureUpdate: Date = .distantPast
    private var max12MPDimension = CMVideoDimensions(width: 4032, height: 3024)
    private var max48MPDimension: CMVideoDimensions?
    
    var capturedImage: UIImage?
    var isProcessing = false
    var isRAWActive = false
    var is48MPSupported = false
    var use48MPMode = true
    var useRAWCapture = false
    var statusMessage = "INICIANDO..."
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .chromagraph
    
    // Controles Ópticos y Retro (Se previsualizan en VIVO y se graban en la foto)
    var exposureEV: Float = -0.35
    var warmth: Float = 0.0
    var bloomIntensity: Float = 0.35
    var grainIntensity: Float = 0.35
    var vignetteIntensity: Float = 0.35
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
    
    private func unlockBestSensorFormat(for device: AVCaptureDevice) {
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
        
        if let format48 = bestFormat48MP, let d48 = found48MPDim {
            do {
                if self.session.canSetSessionPreset(.inputPriority) {
                    self.session.sessionPreset = .inputPriority
                }
                try device.lockForConfiguration()
                device.activeFormat = format48
                device.unlockForConfiguration()
                
                self.photoOutput.maxPhotoDimensions = d48
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            } catch {}
        } else {
            self.session.sessionPreset = .photo
            if let fallbackDim = device.activeFormat.supportedMaxPhotoDimensions.last {
                self.photoOutput.maxPhotoDimensions = fallbackDim
            }
        }
        
        let supports48 = (found48MPDim != nil)
        DispatchQueue.main.async {
            self.is48MPSupported = supports48
            if !supports48 {
                self.use48MPMode = false
                self.useRAWCapture = true
            }
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
        }
        
        unlockBestSensorFormat(for: device)
        
        session.commitConfiguration()
        session.startRunning()
        
        applyExposureInternal(exposureEV)
        updateStatusBadge()
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
        if use48MPMode {
            use48MPMode = false
            useRAWCapture = true
        } else if useRAWCapture {
            useRAWCapture = false
        } else {
            if is48MPSupported && currentZoom == 1.0 {
                use48MPMode = true
                useRAWCapture = false
            } else {
                useRAWCapture = true
            }
        }
        
        let target48 = use48MPMode && is48MPSupported && (currentZoom == 1.0)
        sessionQueue.async {
            if target48, let d48 = self.max48MPDimension {
                self.photoOutput.maxPhotoDimensions = d48
            } else {
                self.photoOutput.maxPhotoDimensions = self.max12MPDimension
            }
            self.updateStatusBadge()
        }
    }
    
    private func updateStatusBadge() {
        let hasRAW = !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
        DispatchQueue.main.async {
            self.isRAWActive = hasRAW
            if self.currentZoom != 1.0 {
                self.statusMessage = "LENTE \(self.currentZoom == 0.5 ? "0.5x" : "2x") (12MP)"
            } else if self.use48MPMode && self.is48MPSupported {
                self.statusMessage = "48MP (8064x6048) ACTIVO"
            } else if self.useRAWCapture && hasRAW {
                self.statusMessage = "BAYER RAW 12MP ACTIVO"
            } else {
                self.statusMessage = "CINE 12MP ACTIVO"
            }
        }
    }
    
    func setExposure(_ ev: Float) {
        exposureEV = ev
        let now = Date()
        guard now.timeIntervalSince(lastExposureUpdate) > 0.08 else { return }
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
    
    func switchCameraLens(factor: CGFloat) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentZoom = factor
        let targetEV = exposureEV
        
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
                    self.unlockBestSensorFormat(for: newDevice)
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
        statusMessage = want48MP ? "CAPTURANDO 48MP..." : "REVELANDO 12MP..."
        
        sessionQueue.async {
            guard let connection = self.photoOutput.connection(with: .video), connection.isEnabled, connection.isActive else {
                DispatchQueue.main.async {
                    self.statusMessage = "CÁMARA NO LISTA"
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
                    settings.photoQualityPrioritization = .balanced
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
                self.statusMessage = "MODO 12MP (\(error.localizedDescription.prefix(12)))"
                self.isProcessing = false
            }
            return
        }
        
        if self.useRAWCapture && !self.use48MPMode && self.currentZoom == 1.0 && !photo.isRawPhoto && !self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR DE DATOS"
                self.isProcessing = false
            }
            return
        }
        
        let wasRAW = photo.isRawPhoto
        let profile = self.selectedProfile
        let bloom = self.bloomIntensity
        let grain = self.grainIntensity
        let vignette = self.vignetteIntensity
        let warmth = self.warmth
        let leak = self.lightLeakEnabled
        let stamp = self.dateStampEnabled
        let ratio = self.aspectRatio
        let frame = self.frameStyle
        let angle = self.physicalOrientation
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                wasCapturedAsRAW: wasRAW,
                profile: profile,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vignette,
                warmthAdjust: warmth,
                lightLeakEnabled: leak,
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
                        } else if let preview = result.previewImage {
                            UIImageWriteToSavedPhotosAlbum(preview, nil, nil, nil)
                            self.statusMessage = "GUARDADA EN CARRETE"
                        } else {
                            self.statusMessage = "PERMISO FOTOS DENEGADO"
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

// MARK: - 4. Capa de Previsualización Óptica en Vivo (Grano 35mm, Viñeta, Halation, Light Leak y Fecha)
struct LiveOpticalEffectsView: View {
    let profile: FilmProfile
    let vignetteIntensity: Float
    let grainIntensity: Float
    let bloomIntensity: Float
    let warmth: Float
    let lightLeakEnabled: Bool
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
                // 1. Tinte de Película + Calidez (WB) en vivo
                filmLiveOverlay(for: profile)
                
                if abs(warmth) > 0.02 {
                    (warmth > 0 ? Color.orange : Color.cyan)
                        .opacity(Double(abs(warmth)) * 0.16)
                        .blendMode(.softLight)
                }
                
                // 2. Halation / Difusión de luces en vivo
                if bloomIntensity > 0.05 {
                    RadialGradient(
                        colors: [
                            profile.badgeColor.opacity(Double(bloomIntensity) * 0.16),
                            Color(red: 1.0, green: 0.35, blue: 0.15).opacity(Double(bloomIntensity) * 0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: geo.size.width * 0.75
                    )
                    .blendMode(.screen)
                }
                
                // 3. Fuga de Luz Analógica (Light Leak) en vivo
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
                
                // 4. Viñeteado Óptico Real en vivo (Responde directamente al Slider de Viñeteado)
                if vignetteIntensity > 0.02 {
                    RadialGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(Double(vignetteIntensity) * 0.45),
                            Color.black.opacity(min(0.92, Double(vignetteIntensity) * 0.95))
                        ],
                        center: .center,
                        startRadius: min(geo.size.width, geo.size.height) * CGFloat(0.48 - Double(vignetteIntensity) * 0.18),
                        endRadius: max(geo.size.width, geo.size.height) * 0.72
                    )
                }
                
                // 5. Textura de Grano 35mm Animada en vivo (Responde al Slider de Grano)
                if grainIntensity > 0.02 {
                    TimelineView(.periodic(from: .now, by: 0.09)) { timeline in
                        Canvas { context, size in
                            let seed = Int(timeline.date.timeIntervalSinceReferenceDate * 14)
                            let count = Int(380 * grainIntensity)
                            var rng = SeededRandomGenerator(seed: UInt64(abs(seed) + 1))
                            for _ in 0..<count {
                                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                                let isBright = Bool.random(using: &rng)
                                let rect = CGRect(x: x, y: y, width: 1.6, height: 1.6)
                                context.fill(
                                    Path(ellipseIn: rect),
                                    with: .color((isBright ? Color.white : Color.black).opacity(Double(grainIntensity) * 0.28))
                                )
                            }
                        }
                    }
                    .blendMode(.overlay)
                }
                
                // 6. Marco Polaroid / Cine Negro en vivo
                if frameStyle != .none {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            frameStyle == .polaroidWhite ? Color(red: 0.97, green: 0.96, blue: 0.93) : Color(white: 0.08),
                            lineWidth: 16
                        )
                }
                
                // 7. Fechador Retro de Cuarzo ('26 11 12) en vivo
                if dateStampEnabled {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(currentDateStamp)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.14))
                                .shadow(color: Color(red: 1.0, green: 0.15, blue: 0.0).opacity(0.9), radius: 5)
                                .padding(.trailing, 22)
                                .padding(.bottom, 155)
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
        case .chromagraph:
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.55).opacity(0.08), Color(red: 0.1, green: 0.35, blue: 0.45).opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .portra400:
            Color(red: 1.0, green: 0.68, blue: 0.35).opacity(0.12).blendMode(.overlay)
        case .cinestill800T:
            Color(red: 0.15, green: 0.65, blue: 0.95).opacity(0.14).blendMode(.colorBurn)
        case .dispo98:
            Color(red: 0.25, green: 0.95, blue: 0.55).opacity(0.10).blendMode(.softLight)
        case .ccd2004:
            Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.09).blendMode(.overlay)
        case .polaroid600:
            Color(red: 1.0, green: 0.78, blue: 0.58).opacity(0.16).blendMode(.softLight)
        case .superia400:
            Color(red: 0.15, green: 0.85, blue: 0.45).opacity(0.10).blendMode(.softLight)
        case .velvia50:
            Color(red: 0.95, green: 0.25, blue: 0.45).opacity(0.08).blendMode(.overlay)
        case .gold200:
            Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.15).blendMode(.softLight)
        case .ektachrome:
            Color(red: 0.35, green: 0.65, blue: 1.0).opacity(0.10).blendMode(.softLight)
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

// MARK: - 5. Laboratorio Darkroom para Fotos de la Galería (Con Safe Area Corregida)
struct GalleryDarkroomView: View {
    let originalData: Data
    var onSaveSuccess: (UIImage, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfile: FilmProfile = .chromagraph
    @State private var exposureAdjust: Float = 0.0
    @State private var warmthAdjust: Float = 0.0
    @State private var bloomAmount: Float = 0.35
    @State private var grainAmount: Float = 0.35
    @State private var vignetteAmount: Float = 0.35
    @State private var lightLeakEnabled = false
    @State private var dateStampEnabled = false
    @State private var frameStyle: FrameStyleOption = .none
    @State private var previewImage: UIImage?
    @State private var scaledCIImage: CIImage?
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Barra Superior con Safe Area protegida (Nunca choca con la hora ni la batería)
            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Cerrar")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.18))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("DARKROOM LAB")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(selectedProfile.subtitle)
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(selectedProfile.badgeColor)
                }
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    saveDevelopedGalleryPhoto()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 12, weight: .bold))
                        Text(isSaving ? "..." : "Guardar")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedProfile.badgeColor)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
                .disabled(isSaving)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // Visor de foto importada
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(white: 0.06))
                
                if let preview = previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(8)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 14)
            
            // Botones Rápidos Retro en el Lab (Light Leak, Fecha '98 y Marco)
            HStack(spacing: 8) {
                Button {
                    lightLeakEnabled.toggle()
                    updatePreview()
                } label: {
                    Label("Light Leak", systemImage: "sun.max.fill")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(lightLeakEnabled ? selectedProfile.badgeColor : Color(white: 0.15))
                        .foregroundStyle(lightLeakEnabled ? .black : .white)
                        .clipShape(Capsule())
                }
                
                Button {
                    dateStampEnabled.toggle()
                    updatePreview()
                } label: {
                    Label("Fecha '98", systemImage: "calendar")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(dateStampEnabled ? selectedProfile.badgeColor : Color(white: 0.15))
                        .foregroundStyle(dateStampEnabled ? .black : .white)
                        .clipShape(Capsule())
                }
                
                Button {
                    let all = FrameStyleOption.allCases
                    if let idx = all.firstIndex(of: frameStyle) {
                        frameStyle = all[(idx + 1) % all.count]
                        updatePreview()
                    }
                } label: {
                    Label(frameStyle.rawValue, systemImage: "photo.artframe")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(frameStyle != .none ? selectedProfile.badgeColor : Color(white: 0.15))
                        .foregroundStyle(frameStyle != .none ? .black : .white)
                        .clipShape(Capsule())
                }
            }
            
            // Deslizadores Químicos
            VStack(spacing: 8) {
                darkroomSlider(title: "EXPOSICIÓN", value: $exposureAdjust, range: -1.5...1.5, format: "%+.1f EV")
                darkroomSlider(title: "CALIDEZ WB", value: $warmthAdjust, range: -1.0...1.0, format: "%+.1f")
                darkroomSlider(title: "HALATION", value: $bloomAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                darkroomSlider(title: "GRANO 35MM", value: $grainAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                darkroomSlider(title: "VIÑETEADO", value: $vignetteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 14)
            
            // Carrusel de las 12 Cámaras
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilmProfile.allCases) { profile in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedProfile = profile
                            updatePreview()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(selectedProfile == profile ? .black : profile.badgeColor)
                                        .frame(width: 8, height: 8)
                                    Text(profile.rawValue)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                }
                                Text(profile.subtitle)
                                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                                    .opacity(0.75)
                            }
                            .foregroundStyle(selectedProfile == profile ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedProfile == profile ? profile.badgeColor : Color(white: 0.14))
                            )
                        }
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 10)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            prepareScaledPreviewInput()
        }
    }
    
    @ViewBuilder
    private func darkroomSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String, multiplier: Float = 1.0) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 78, alignment: .leading)
            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { newVal in
                    value.wrappedValue = newVal
                    updatePreview()
                }
            ), in: range)
            .tint(selectedProfile.badgeColor)
            Text(String(format: format, value.wrappedValue * multiplier))
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 46, alignment: .trailing)
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
        let bloom = bloomAmount
        let grain = grainAmount
        let vig = vignetteAmount
        let warm = warmthAdjust
        let exp = exposureAdjust
        let leak = lightLeakEnabled
        let stamp = dateStampEnabled
        let frame = frameStyle
        
        Task.detached(priority: .userInteractive) {
            guard var img = CinematicPipeline.shared.renderPreviewUIImage(
                from: baseCI,
                profile: prof,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                warmthAdjust: warm,
                exposureAdjust: exp,
                lightLeakEnabled: leak
            ) else { return }
            
            if stamp || frame != .none {
                img = CinematicPipeline.shared.applyFinalTouches(
                    to: img,
                    aspectRatio: .fourThree,
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
        let bloom = bloomAmount
        let grain = grainAmount
        let vig = vignetteAmount
        let warm = warmthAdjust
        let exp = exposureAdjust
        let leak = lightLeakEnabled
        let stamp = dateStampEnabled
        let frame = frameStyle
        let rawData = originalData
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: rawData,
                wasCapturedAsRAW: true,
                profile: prof,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                warmthAdjust: warm,
                exposureAdjust: exp,
                lightLeakEnabled: leak,
                dateStampEnabled: stamp,
                aspectRatio: .fourThree,
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
                    onSaveSuccess(img, "LAB: \(result.status)")
                }
                dismiss()
            }
        }
    }
}

// MARK: - 6. Interfaz Principal Chromagraph Studio
struct NativeCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var onTapFocus: (CGPoint, CGPoint) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTapFocus: onTapFocus)
    }
    
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
            .stroke(Color.white.opacity(0.22), lineWidth: 0.7)
        }
        .allowsHitTesting(false)
    }
}

struct ContentView: View {
    @State private var camera = CameraManager()
    @State private var showControls = false
    @State private var showFullPreview = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedPhotoData: Data?
    @State private var showDarkroom = false
    
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0]
    
    private var modeButtonTitle: String {
        if camera.currentZoom != 1.0 { return "12MP" }
        if camera.use48MPMode && camera.is48MPSupported { return "48MP PRO" }
        if camera.useRAWCapture { return "12MP RAW" }
        return "12MP CINE"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Barra Superior de Telemetría y Herramientas Rápidas
                HStack(spacing: 6) {
                    Button {
                        camera.toggleSensorMode()
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.black)
                                .frame(width: 6, height: 6)
                            Text(modeButtonTitle)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(camera.selectedProfile.badgeColor)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                    }
                    
                    Text(camera.statusMessage)
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.11))
                        .foregroundStyle(.white.opacity(0.9))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Botón Flash
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.flashEnabled.toggle()
                    } label: {
                        Image(systemName: camera.flashEnabled ? "bolt.fill" : "bolt.slash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(camera.flashEnabled ? camera.selectedProfile.badgeColor : .white.opacity(0.75))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Botón Fechador '98
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.dateStampEnabled.toggle()
                    } label: {
                        Text("'98")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(camera.dateStampEnabled ? .black : .white.opacity(0.8))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 7)
                            .background(camera.dateStampEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Botón Cuadrícula
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.showGrid.toggle()
                    } label: {
                        Image(systemName: "squareshape.split.3x3")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(camera.showGrid ? camera.selectedProfile.badgeColor : .white.opacity(0.75))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Botón Ajustes Químicos
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring) { showControls.toggle() }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(showControls ? .black : .white)
                            .padding(8)
                            .background(showControls ? camera.selectedProfile.badgeColor : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                
                // Visor Principal con Grano, Viñeta, Halation y Light Leak EN VIVO
                ZStack(alignment: .bottom) {
                    ZStack {
                        NativeCameraPreview(session: camera.session) { devicePt, viewPt in
                            camera.focusAt(normalizedPoint: devicePt, viewPoint: viewPt)
                        }
                        .contrast(liveContrast(for: camera.selectedProfile))
                        .saturation(liveSaturation(for: camera.selectedProfile))
                        
                        // Capa Óptica en Tiempo Real (Muestra Grano, Viñeta, Halation, Fecha y Marcos)
                        LiveOpticalEffectsView(
                            profile: camera.selectedProfile,
                            vignetteIntensity: camera.vignetteIntensity,
                            grainIntensity: camera.grainIntensity,
                            bloomIntensity: camera.bloomIntensity,
                            warmth: camera.warmth,
                            lightLeakEnabled: camera.lightLeakEnabled,
                            dateStampEnabled: camera.dateStampEnabled,
                            frameStyle: camera.frameStyle
                        )
                        
                        if camera.showGrid {
                            GridOverlayView()
                        }
                        
                        // Indicador de enfoque al tocar la pantalla
                        if let pt = camera.focusPoint {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(camera.selectedProfile.badgeColor, lineWidth: 1.5)
                                .frame(width: 64, height: 64)
                                .position(pt)
                        }
                        
                        if camera.countdownRemaining > 0 {
                            Text("\(camera.countdownRemaining)")
                                .font(.system(size: 76, weight: .black, design: .monospaced))
                                .foregroundStyle(camera.selectedProfile.badgeColor)
                                .shadow(color: .black.opacity(0.8), radius: 12)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    
                    // Controles Inferiores Superpuestos
                    VStack(spacing: 10) {
                        if showControls {
                            VStack(spacing: 8) {
                                // Botones de Efectos Creativos (Light Leak, Formato, Marco, Timer)
                                HStack(spacing: 6) {
                                    Button {
                                        camera.lightLeakEnabled.toggle()
                                    } label: {
                                        Text(camera.lightLeakEnabled ? "LEAK: ON" : "LEAK: OFF")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(camera.lightLeakEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.14))
                                            .foregroundStyle(camera.lightLeakEnabled ? .black : .white)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        let all = AspectRatioOption.allCases
                                        if let idx = all.firstIndex(of: camera.aspectRatio) {
                                            camera.aspectRatio = all[(idx + 1) % all.count]
                                        }
                                    } label: {
                                        Text(camera.aspectRatio.rawValue)
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(camera.aspectRatio != .fourThree ? camera.selectedProfile.badgeColor : Color.white.opacity(0.14))
                                            .foregroundStyle(camera.aspectRatio != .fourThree ? .black : .white)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        let all = FrameStyleOption.allCases
                                        if let idx = all.firstIndex(of: camera.frameStyle) {
                                            camera.frameStyle = all[(idx + 1) % all.count]
                                        }
                                    } label: {
                                        Text(camera.frameStyle.rawValue.uppercased())
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(camera.frameStyle != .none ? camera.selectedProfile.badgeColor : Color.white.opacity(0.14))
                                            .foregroundStyle(camera.frameStyle != .none ? .black : .white)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        camera.timerSeconds = (camera.timerSeconds == 0) ? 3 : 0
                                    } label: {
                                        Text(camera.timerSeconds > 0 ? "TIMER 3S" : "TIMER OFF")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(camera.timerSeconds > 0 ? camera.selectedProfile.badgeColor : Color.white.opacity(0.14))
                                            .foregroundStyle(camera.timerSeconds > 0 ? .black : .white)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.bottom, 2)
                                
                                HStack {
                                    Text("LUCES (EV)")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .frame(width: 76, alignment: .leading)
                                    Slider(value: Binding(
                                        get: { camera.exposureEV },
                                        set: { camera.setExposure($0) }
                                    ), in: -2.0...1.0)
                                    .tint(camera.selectedProfile.badgeColor)
                                    Text(String(format: "%+.1f", camera.exposureEV))
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("CALIDEZ WB")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .frame(width: 76, alignment: .leading)
                                    Slider(value: $camera.warmth, in: -1.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text(String(format: "%+.1f", camera.warmth))
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("HALATION")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .frame(width: 76, alignment: .leading)
                                    Slider(value: $camera.bloomIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.bloomIntensity * 100))%")
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("GRANO 35MM")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .frame(width: 76, alignment: .leading)
                                    Slider(value: $camera.grainIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.grainIntensity * 100))%")
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("VIÑETEADO")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .frame(width: 76, alignment: .leading)
                                    Slider(value: $camera.vignetteIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.vignetteIntensity * 100))%")
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .frame(width: 36)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.84))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 14)
                        }
                        
                        // Selector de 12 Cámaras Cinematográficas y Retro
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FilmProfile.allCases) { profile in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        camera.selectedProfile = profile
                                    } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 5) {
                                                Circle()
                                                    .fill(selectedDotColor(for: profile))
                                                    .frame(width: 8, height: 8)
                                                Text(profile.rawValue)
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            }
                                            Text(profile.subtitle)
                                                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                                                .opacity(0.75)
                                        }
                                        .foregroundStyle(camera.selectedProfile == profile ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 11)
                                                .fill(camera.selectedProfile == profile ? profile.badgeColor : Color.black.opacity(0.72))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Selector de Lentes (0.5x | 1x | 2x)
                        HStack(spacing: 10) {
                            ForEach(zoomLevels, id: \.self) { level in
                                Button {
                                    camera.switchCameraLens(factor: level)
                                } label: {
                                    Text(level == 0.5 ? "0.5x" : "\(Int(level))x")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(camera.currentZoom == level ? .black : .white)
                                        .frame(width: 42, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(camera.currentZoom == level ? camera.selectedProfile.badgeColor : Color.black.opacity(0.65))
                                        )
                                }
                            }
                        }
                        
                        // Barra Inferior: Última Foto | Obturador | Importar a Darkroom Lab
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
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.4), lineWidth: 1))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.14))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.white.opacity(0.4))
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                camera.triggerShutter()
                            } label: {
                                ZStack {
                                    Circle()
                                        .stroke(camera.selectedProfile.badgeColor, lineWidth: 3)
                                        .frame(width: 74, height: 74)
                                    Circle()
                                        .fill(camera.isProcessing ? camera.selectedProfile.badgeColor : Color.white)
                                        .frame(width: 62, height: 62)
                                }
                            }
                            .disabled(camera.isProcessing)
                            
                            Spacer()
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                VStack(spacing: 3) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 17, weight: .semibold))
                                    Text("LAB")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.65))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(camera.selectedProfile.badgeColor.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)
                    }
                }
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
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Button("Cerrar") {
                        showFullPreview = false
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(20)
                }
            }
        }
    }
    
    private func selectedDotColor(for profile: FilmProfile) -> Color {
        camera.selectedProfile == profile ? .black : profile.badgeColor
    }
    
    private func liveContrast(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400: return 1.28
        case .bleachBypass, .ccd2004: return 1.20
        case .polaroid600: return 0.94
        default: return 1.10
        }
    }
    
    private func liveSaturation(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400: return 0.0
        case .bleachBypass: return 0.45
        case .velvia50, .ccd2004: return 1.28
        case .portra400, .gold200, .superia400: return 1.12
        default: return 0.95
        }
    }
}
// FIN DEL ARCHIVO
