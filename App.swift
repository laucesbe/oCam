import SwiftUI
import AVFoundation
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

// MARK: - 1. Catálogo de 16 Cámaras Cinematográficas y Retro de oCam
enum FilmProfile: String, CaseIterable, Identifiable {
    case ocamMaster = "oCam"
    case cineChrome = "Palms 70s"
    case kodak2383 = "Kodak 2383"
    case nocturnaClub = "Nocturna"
    case portra400 = "Portra 400"
    case cinestill800T = "800T"
    case dispo98 = "Dispo 98"
    case ccd2004 = "CCD 2004"
    case polaroid600 = "Polaroid"
    case superia400 = "Superia"
    case velvia50 = "Velvia 50"
    case gold200 = "Gold 200"
    case aerochrome = "Aero IR"
    case bleachBypass = "Bleach"
    case ilfordHP5 = "Ilford HP5"
    case triX400 = "Tri-X B&W"
    
    var id: String { self.rawValue }
    
    var subtitle: String {
        switch self {
        case .ocamMaster: return "TRUE COLOR FILM ROLL-OFF"
        case .cineChrome: return "WARM PALMS & DEEP GREENS"
        case .kodak2383: return "HOLLYWOOD PRINT LUT"
        case .nocturnaClub: return "CLUB & NEON LOW LIGHT"
        case .portra400: return "NATURAL SKIN & SOFT LIGHT"
        case .cinestill800T: return "TUNGSTEN HALATION"
        case .dispo98: return "90s POCKET FLASH"
        case .ccd2004: return "EARLY 2000s DIGICAM"
        case .polaroid600: return "CREAMY INSTANT FRAME"
        case .superia400: return "EMERALD SHADOWS"
        case .velvia50: return "RICH SLIDE CHROME"
        case .gold200: return "GOLDEN HOUR VINTAGE"
        case .aerochrome: return "INFRARED CRIMSON FOLIAGE"
        case .bleachBypass: return "METALLIC CINEMA GRIT"
        case .ilfordHP5: return "SOFT DOCUMENTARY B&W"
        case .triX400: return "HIGH CONTRAST MONO"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .ocamMaster: return Color(red: 0.92, green: 0.84, blue: 0.70)
        case .cineChrome: return Color(red: 0.94, green: 0.76, blue: 0.48)
        case .kodak2383: return Color(red: 0.48, green: 0.82, blue: 0.86)
        case .nocturnaClub: return Color(red: 0.96, green: 0.52, blue: 0.40)
        case .portra400: return Color(red: 0.94, green: 0.70, blue: 0.52)
        case .cinestill800T: return Color(red: 0.42, green: 0.78, blue: 0.96)
        case .dispo98: return Color(red: 0.52, green: 0.90, blue: 0.66)
        case .ccd2004: return Color(red: 0.78, green: 0.68, blue: 0.96)
        case .polaroid600: return Color(red: 0.95, green: 0.80, blue: 0.72)
        case .superia400: return Color(red: 0.42, green: 0.86, blue: 0.60)
        case .velvia50: return Color(red: 0.94, green: 0.50, blue: 0.50)
        case .gold200: return Color(red: 0.96, green: 0.84, blue: 0.44)
        case .aerochrome: return Color(red: 0.98, green: 0.36, blue: 0.52)
        case .bleachBypass: return Color(red: 0.76, green: 0.80, blue: 0.84)
        case .ilfordHP5: return Color(white: 0.82)
        case .triX400: return Color(white: 0.92)
        }
    }
    
    struct RecommendedSettings {
        let ev: Float
        let contrastSCurve: Float
        let warmth: Float
        let bloom: Float
        let grain: Float
        let vignette: Float
        let fadeMatte: Float
        let saturationAdjust: Float
        let nightMode: Bool
    }
    
    var recommended: RecommendedSettings {
        switch self {
        case .ocamMaster:
            // Mantiene la limpieza de tus fotos 4 y 5 de 48MP con sutil estética de cine analógico
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.65, warmth: 0.0, bloom: 0.30, grain: 0.24, vignette: 0.24, fadeMatte: 0.14, saturationAdjust: -0.10, nightMode: false)
        case .cineChrome:
            // Calibrada exactamente como la 2da foto de las palmeras: desaturación orgánica, cielo cremoso y sombras profundas
            return RecommendedSettings(ev: -0.40, contrastSCurve: 0.74, warmth: 0.06, bloom: 0.36, grain: 0.30, vignette: 0.30, fadeMatte: 0.22, saturationAdjust: -0.16, nightMode: false)
        case .kodak2383:
            // Película de impresión de cine: contraste rico y separación cromática limpia
            return RecommendedSettings(ev: -0.40, contrastSCurve: 0.78, warmth: 0.0, bloom: 0.34, grain: 0.26, vignette: 0.32, fadeMatte: 0.18, saturationAdjust: -0.08, nightMode: false)
        case .nocturnaClub:
            return RecommendedSettings(ev: -0.55, contrastSCurve: 0.72, warmth: -0.04, bloom: 0.58, grain: 0.32, vignette: 0.36, fadeMatte: 0.12, saturationAdjust: -0.05, nightMode: true)
        case .portra400:
            return RecommendedSettings(ev: -0.25, contrastSCurve: 0.54, warmth: 0.03, bloom: 0.26, grain: 0.22, vignette: 0.20, fadeMatte: 0.16, saturationAdjust: -0.06, nightMode: false)
        case .cinestill800T:
            return RecommendedSettings(ev: -0.45, contrastSCurve: 0.68, warmth: -0.14, bloom: 0.62, grain: 0.34, vignette: 0.32, fadeMatte: 0.12, saturationAdjust: -0.06, nightMode: true)
        case .dispo98:
            return RecommendedSettings(ev: -0.20, contrastSCurve: 0.70, warmth: 0.0, bloom: 0.35, grain: 0.50, vignette: 0.42, fadeMatte: 0.28, saturationAdjust: -0.08, nightMode: false)
        case .ccd2004:
            return RecommendedSettings(ev: -0.30, contrastSCurve: 0.62, warmth: 0.0, bloom: 0.16, grain: 0.18, vignette: 0.22, fadeMatte: 0.05, saturationAdjust: 0.06, nightMode: false)
        case .polaroid600:
            return RecommendedSettings(ev: -0.15, contrastSCurve: 0.48, warmth: 0.04, bloom: 0.42, grain: 0.28, vignette: 0.38, fadeMatte: 0.34, saturationAdjust: -0.14, nightMode: false)
        case .superia400:
            return RecommendedSettings(ev: -0.30, contrastSCurve: 0.64, warmth: 0.0, bloom: 0.24, grain: 0.28, vignette: 0.24, fadeMatte: 0.14, saturationAdjust: -0.05, nightMode: false)
        case .velvia50:
            return RecommendedSettings(ev: -0.40, contrastSCurve: 0.76, warmth: 0.0, bloom: 0.20, grain: 0.16, vignette: 0.28, fadeMatte: 0.06, saturationAdjust: 0.12, nightMode: false)
        case .gold200:
            return RecommendedSettings(ev: -0.30, contrastSCurve: 0.62, warmth: 0.06, bloom: 0.32, grain: 0.26, vignette: 0.26, fadeMatte: 0.20, saturationAdjust: -0.04, nightMode: false)
        case .aerochrome:
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.70, warmth: 0.0, bloom: 0.30, grain: 0.26, vignette: 0.28, fadeMatte: 0.10, saturationAdjust: 0.05, nightMode: false)
        case .bleachBypass:
            return RecommendedSettings(ev: -0.45, contrastSCurve: 0.82, warmth: -0.05, bloom: 0.14, grain: 0.44, vignette: 0.44, fadeMatte: 0.15, saturationAdjust: -0.48, nightMode: false)
        case .ilfordHP5:
            return RecommendedSettings(ev: -0.30, contrastSCurve: 0.56, warmth: 0.0, bloom: 0.22, grain: 0.46, vignette: 0.32, fadeMatte: 0.22, saturationAdjust: -1.0, nightMode: false)
        case .triX400:
            return RecommendedSettings(ev: -0.35, contrastSCurve: 0.80, warmth: 0.0, bloom: 0.20, grain: 0.58, vignette: 0.40, fadeMatte: 0.10, saturationAdjust: -1.0, nightMode: false)
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

// MARK: - 2. Motor Cinematográfico oCam (RAW Sin Verde + 48MP Con Look Completo + Lab Preciso)
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
        shadowsAdjust: Float = 0.0,
        highlightsAdjust: Float = 0.0,
        fadeMatteAmount: Float = 0.14,
        saturationAdjust: Float = 0.0,
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
        
        // 0. Ajuste de Exposición
        if abs(exposureAdjust) > 0.02 {
            let exp = CIFilter.exposureAdjust()
            exp.inputImage = current
            exp.ev = exposureAdjust
            if let out = exp.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 1. Corrección de Exceso de Verde exclusiva para Bayer RAW (Los 2 fotodiodos G1/G2 del sensor RGGB bajo luz cálida)
        // Sin usar CITemperatureAndTint forzado a 6500K, que era lo que teñía tus fotos RAW de verde lima
        if isRAW {
            let rawGreenFix = CIFilter.colorMatrix()
            rawGreenFix.inputImage = current
            rawGreenFix.rVector = CIVector(x: 1.03, y: 0.00, z: 0.00, w: 0)
            rawGreenFix.gVector = CIVector(x: 0.00, y: 0.94, z: 0.00, w: 0) // Atenúa el exceso de canal verde del Bayer RAW
            rawGreenFix.bVector = CIVector(x: 0.00, y: 0.00, z: 1.04, w: 0)
            if let out = rawGreenFix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // Ajuste manual de temperatura (solo cuando el usuario mueve el slider de WB)
        if abs(warmthAdjust) > 0.02 {
            let wbFix = CIFilter.temperatureAndTint()
            wbFix.inputImage = current
            wbFix.neutral = CIVector(x: 6500, y: 0)
            let userShift = CGFloat(-warmthAdjust * 850)
            wbFix.targetNeutral = CIVector(x: 6500 + userShift, y: 0)
            if let out = wbFix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 2. Recuperación de Altas Luces y Sombras (Con soporte para los nuevos sliders de Highlights y Shadows del Studio)
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        let baseHighlight: Float = nightModeBoost ? 0.22 : 0.32
        let baseShadow: Float = nightModeBoost ? 0.30 : (isRAW ? 0.18 : 0.08)
        hs.highlightAmount = max(0.05, min(1.0, baseHighlight - (highlightsAdjust * 0.35)))
        hs.shadowAmount = max(-0.5, min(1.0, baseShadow + (shadowsAdjust * 0.50)))
        hs.radius = Float(26.0 * scaleMultiplier)
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 3. Emulación de Color y Desaturación Orgánica (Conservando neutros blancos como en tus fotos 4 y 5 + estética Palmeras)
        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = current
        let colorControls = CIFilter.colorControls()
        let matrix = CIFilter.colorMatrix()
        
        switch profile {
        case .ocamMaster:
            // Limpieza de las fotos 4 y 5 + roll-off cinematográfico y verdes profundos tipo palmeras
            vibrance.amount = -0.14
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.88 + saturationAdjust * 0.35)
            colorControls.contrast = 1.04
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
            // Split-toning analógico preservador de blancos (suma de cada fila = 1.00)
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.02, y: 0.01, z: -0.03, w: 0)
            matrix.gVector = CIVector(x: -0.01, y: 0.98, z: 0.03, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: -0.01, z: 1.03, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .cineChrome:
            // Estética exacta de la 2da foto de las palmeras: verdes pino apagados, cielo crema sedoso y sombras densas
            vibrance.amount = -0.20
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.83 + saturationAdjust * 0.35)
            colorControls.contrast = 1.06
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.03, y: 0.02, z: -0.05, w: 0)
            matrix.gVector = CIVector(x: -0.02, y: 0.97, z: 0.05, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: 0.01, z: 1.02, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .kodak2383:
            // Película de impresión de cine: sombras densas con cian muy sutil y luces piel naturales
            vibrance.amount = -0.10
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.90 + saturationAdjust * 0.35)
            colorControls.contrast = 1.07
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.03, y: 0.01, z: -0.04, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.99, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: 0.02, z: 1.01, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .nocturnaClub:
            vibrance.amount = -0.10
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.92 + saturationAdjust * 0.35)
            colorControls.contrast = 1.08
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .portra400:
            vibrance.amount = -0.08
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.92 + saturationAdjust * 0.35)
            colorControls.contrast = 1.02
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .cinestill800T:
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 0.95, y: 0.03, z: 0.02, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.99, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: 0.03, z: 1.00, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .dispo98:
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.88 + saturationAdjust * 0.35)
            colorControls.contrast = 1.08
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .ccd2004:
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 1.05 + saturationAdjust * 0.35)
            colorControls.contrast = 1.08
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .polaroid600:
            vibrance.amount = -0.16
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.85 + saturationAdjust * 0.35)
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .superia400:
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.03, y: -0.02, z: -0.01, w: 0)
            matrix.gVector = CIVector(x: -0.02, y: 1.04, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: 0.00, y: 0.01, z: 0.99, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .velvia50:
            vibrance.amount = 0.12
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 1.08 + saturationAdjust * 0.35)
            colorControls.contrast = 1.08
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .gold200:
            vibrance.amount = -0.06
            if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.93 + saturationAdjust * 0.35)
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .aerochrome:
            // Kodak Aerochrome IR: Intercambia el canal verde de las plantas hacia rojo rubí manteniendo blancos
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 0.45, y: 0.65, z: -0.10, w: 0)
            matrix.gVector = CIVector(x: 0.25, y: 0.55, z: 0.20, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: 0.10, z: 0.95, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .bleachBypass:
            colorControls.inputImage = current
            colorControls.saturation = max(0.0, 0.45 + saturationAdjust * 0.35)
            colorControls.contrast = 1.15
            if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
            
        case .ilfordHP5:
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = current
            if let out = mono.outputImage?.cropped(to: extent) { current = out }
            
        case .triX400:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = current
            if let out = noir.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 4. Curva Tonal S-Curve + Matte Fade Analógico + Highlight Roll-off (Funciona igual en 12MP, RAW y 48MP)
        let sAmount = Double(contrastSCurve)
        let matteLift = Double(fadeMatteAmount) * 0.085
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        let blackPoint = min(0.12, 0.015 + matteLift)
        let shadowDip = max(blackPoint + 0.06, 0.22 - (sAmount * 0.085) + (matteLift * 0.35))
        let midTone = 0.49
        let highShoulder = min(0.85, 0.75 + (sAmount * 0.06))
        let whiteRollOff = 0.915 // Comprime los blancos altos a crema suave como en las palmeras #2
        
        curve.point0 = CGPoint(x: 0.00, y: blackPoint)
        curve.point1 = CGPoint(x: 0.25, y: shadowDip)
        curve.point2 = CGPoint(x: 0.50, y: midTone)
        curve.point3 = CGPoint(x: 0.75, y: highShoulder)
        curve.point4 = CGPoint(x: 1.00, y: whiteRollOff)
        if let out = curve.outputImage?.cropped(to: extent) { current = out }
        
        // 5. Micro-contraste Óptico (Ahora ACTIVO también en 48MP para darle carácter de lente analógico)
        let clarity = CIFilter.unsharpMask()
        clarity.inputImage = current
        clarity.radius = Float(min(18.0, 10.0 * scaleMultiplier))
        clarity.intensity = 0.22
        if let out = clarity.outputImage?.cropped(to: extent) { current = out }
        
        // 6. Modo Retrato Óptico (Bokeh circular suave)
        if portraitDepthBlur > 0.05 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = current.clampedToExtent()
            blur.radius = Float(min(26.0, 14.0 * Double(portraitDepthBlur) * scaleMultiplier))
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
        
        // 7. Halation / Difusión en luces (Ahora ACTIVO también en 48MP con radio acotado seguro en GPU)
        if bloomAmount > 0.04 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = Float(min(18.0, 11.0 * scaleMultiplier))
            bloom.intensity = bloomAmount * (profile == .nocturnaClub ? 0.60 : 0.38)
            if let out = bloom.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 8. Viñeteado Óptico Natural
        if vignetteAmount > 0.02 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = current
            vignette.intensity = vignetteAmount * 1.40
            vignette.radius = 1.72
            if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 9. Fuga de Luz Analógica Opcional
        if lightLeakEnabled {
            let grad = CIFilter.linearGradient()
            grad.point0 = CGPoint(x: 0, y: extent.height * 0.85)
            grad.point1 = CGPoint(x: extent.width * 0.42, y: extent.height * 0.35)
            grad.color0 = CIColor(red: 1.0, green: 0.32, blue: 0.05, alpha: 0.48)
            grad.color1 = CIColor(red: 1.0, green: 0.65, blue: 0.10, alpha: 0.0)
            if let leakImg = grad.outputImage?.cropped(to: extent) {
                let screen = CIFilter.screenBlendMode()
                screen.inputImage = leakImg
                screen.backgroundImage = current
                if let out = screen.outputImage?.cropped(to: extent) { current = out }
            }
        }
        
        // 10. Lente Anamórfico Opcional
        if anamorphicMode {
            let flare = CIFilter.linearGradient()
            flare.point0 = CGPoint(x: extent.width * 0.1, y: extent.height * 0.5)
            flare.point1 = CGPoint(x: extent.width * 0.9, y: extent.height * 0.5)
            flare.color0 = CIColor(red: 0.1, green: 0.5, blue: 1.0, alpha: 0.0)
            flare.color1 = CIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.22)
            if let flareImg = flare.outputImage?.cropped(to: extent) {
                let add = CIFilter.additionCompositing()
                add.inputImage = flareImg
                add.backgroundImage = current
                if let out = add.outputImage?.cropped(to: extent) { current = out }
            }
        }
        
        // 11. Grano 35mm Real Escalado a los Megapíxeles (Se ve idéntico en 12MP, 48MP y Studio)
        if grainAmount > 0.02, let rawNoise = CIFilter.randomGenerator().outputImage {
            let grainScale = max(1.8, min(extent.width, extent.height) / 920.0)
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
    
    /// Funde dos fotos químicamente cuando está activo el modo Doble Exposición Analógica
    func blendDoubleExposure(base: UIImage, overlay: UIImage) -> UIImage {
        let size = base.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            overlay.draw(in: CGRect(origin: .zero, size: size), blendMode: .screen, alpha: 0.65)
        }
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
        shadowsAdjust: Float,
        highlightsAdjust: Float,
        fadeMatteAmount: Float,
        saturationAdjust: Float,
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
            shadowsAdjust: shadowsAdjust,
            highlightsAdjust: highlightsAdjust,
            fadeMatteAmount: fadeMatteAmount,
            saturationAdjust: saturationAdjust,
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
        cameraWhiteBalanceTempAndTint: (temp: Float, tint: Float)? = nil,
        profile: FilmProfile,
        contrastSCurve: Float,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        warmthAdjust: Float,
        exposureAdjust: Float = 0.0,
        shadowsAdjust: Float = 0.0,
        highlightsAdjust: Float = 0.0,
        fadeMatteAmount: Float = 0.14,
        saturationAdjust: Float = 0.0,
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
        
        // Solo usar CIRAWFilter si realmente es un DNG/RAW de cámara (NO en fotos JPEG de la galería para que el Lab sea 100% preciso)
        if wasCapturedAsRAW && !isFromGallery, let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
            rawFilter.luminanceNoiseReductionAmount = nightModeBoost ? 0.88 : 0.80
            rawFilter.colorNoiseReductionAmount = 0.96
            rawFilter.sharpnessAmount = 0.24
            // CRÍTICO: localToneMapAmount = 0.0 evita el halo oscuro/verdoso raro que salió alrededor de tu lámpara en la foto RAW #2 y #3
            rawFilter.localToneMapAmount = 0.0
            rawFilter.boostAmount = 0.50
            rawFilter.baselineExposure = -0.20
            rawFilter.scaleFactor = 1.0
            
            // Inyectar la temperatura y tinte reales medidos por el sensor al disparar para que el blanco sea idéntico al de 48MP
            if let wb = cameraWhiteBalanceTempAndTint, wb.temp > 2000 && wb.temp < 10000 {
                rawFilter.neutralTemperature = wb.temp
                rawFilter.neutralTint = wb.tint
            }
            
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
            shadowsAdjust: shadowsAdjust,
            highlightsAdjust: highlightsAdjust,
            fadeMatteAmount: fadeMatteAmount,
            saturationAdjust: saturationAdjust,
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

// MARK: - 3. Controlador de Hardware oCam (48MP por defecto + Doble Exposición + Horizonte)
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
    var doubleExposureFirstShot: UIImage? // Almacena la primera toma en modo Doble Exposición
    var isProcessing = false
    var isRAWActive = false
    var is48MPSupported = false
    var use48MPMode = true     // Arranca en 48MP PRO por defecto porque dio los mejores colores en tus pruebas
    var useRAWCapture = false
    var doubleExposureEnabled = false
    var showHorizonAndHistogram = false
    var horizonAngleDegrees: Double = 0.0
    var statusMessage = "48MP PRO"
    var lastExifSummary = "1/125s | f/1.6 | ISO 64"
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .ocamMaster
    
    var exposureEV: Float = -0.35
    var contrastSCurve: Float = 0.65
    var warmth: Float = 0.0
    var bloomIntensity: Float = 0.30
    var grainIntensity: Float = 0.24
    var vignetteIntensity: Float = 0.24
    var fadeMatteAmount: Float = 0.14
    var saturationAdjust: Float = -0.10
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
        fadeMatteAmount = rec.fadeMatte
        saturationAdjust = rec.saturationAdjust
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
        fadeMatteAmount = 0.0
        saturationAdjust = 0.0
        portraitDepthBlur = 0.0
        nightModeEnabled = false
        setExposure(0.0)
        updateNightModeHardware()
    }
    
    private func startMotionTracking() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.12
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let acc = data?.acceleration else { return }
            let angle = atan2(acc.x, -acc.y) * 180.0 / .pi
            self.horizonAngleDegrees = angle
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
            if !supports48 && self.use48MPMode {
                self.use48MPMode = false
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
        if use48MPMode {
            use48MPMode = false
            useRAWCapture = true
        } else if useRAWCapture {
            useRAWCapture = false
            use48MPMode = false
        } else {
            if is48MPSupported && currentZoom == 1.0 {
                use48MPMode = true
                useRAWCapture = false
            } else {
                useRAWCapture = true
                use48MPMode = false
            }
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
            if self.doubleExposureEnabled {
                self.statusMessage = self.doubleExposureFirstShot == nil ? "2X EXP: TOMA 1/2" : "2X EXP: TOMA 2/2"
            } else if self.nightModeEnabled {
                self.statusMessage = "MODO NOCHE"
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
        
        // Leer temperatura y tinte reales del sensor en el instante del disparo para calibrar el Bayer RAW sin verde
        var measuredWB: (temp: Float, tint: Float)? = nil
        if let dev = self.currentDevice {
            let tt = dev.temperatureAndTintValues(for: dev.deviceWhiteBalanceGains)
            measuredWB = (tt.temperature, tt.tint)
        }
        
        let wasRAW = photo.isRawPhoto
        let photoMeta = photo.metadata
        let profile = self.selectedProfile
        let sCurve = self.contrastSCurve
        let bloom = self.bloomIntensity
        let grain = self.grainIntensity
        let vignette = self.vignetteIntensity
        let warmth = self.warmth
        let fade = self.fadeMatteAmount
        let sat = self.saturationAdjust
        let portrait = self.portraitDepthBlur
        let night = self.nightModeEnabled
        let leak = self.lightLeakEnabled
        let anamorphic = self.anamorphicMode
        let stamp = self.dateStampEnabled
        let ratio = self.aspectRatio
        let frame = self.frameStyle
        let angle = self.physicalOrientation
        let isDoubleExp = self.doubleExposureEnabled
        let firstShot = self.doubleExposureFirstShot
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                rawMetadata: photoMeta,
                wasCapturedAsRAW: wasRAW,
                cameraWhiteBalanceTempAndTint: measuredWB,
                profile: profile,
                contrastSCurve: sCurve,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vignette,
                warmthAdjust: warmth,
                exposureAdjust: 0.0,
                shadowsAdjust: 0.0,
                highlightsAdjust: 0.0,
                fadeMatteAmount: fade,
                saturationAdjust: sat,
                portraitDepthBlur: portrait,
                nightModeBoost: night,
                lightLeakEnabled: leak,
                anamorphicMode: anamorphic,
                dateStampEnabled: stamp,
                aspectRatio: ratio,
                frameStyle: frame,
                deviceOrientation: angle
            )
            
            guard var finalUIImage = result.previewImage else {
                await MainActor.run { self.isProcessing = false }
                return
            }
            
            // Si está activo Doble Exposición y es la toma 1/2, guardarla como fantasma en el visor y esperar la 2da foto
            if isDoubleExp && firstShot == nil {
                await MainActor.run {
                    self.doubleExposureFirstShot = finalUIImage
                    self.statusMessage = "2X EXP: TOMA 2/2"
                    self.isProcessing = false
                }
                return
            }
            
            var finalDataToSave = result.jpegData
            if isDoubleExp, let baseShot = firstShot {
                finalUIImage = CinematicPipeline.shared.blendDoubleExposure(base: baseShot, overlay: finalUIImage)
                finalDataToSave = finalUIImage.jpegData(compressionQuality: 0.96)
            }
            
            if let jpegData = finalDataToSave {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                }, completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        if success {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            self.statusMessage = isDoubleExp ? "2X EXP GUARDADA" : result.status
                            self.lastExifSummary = result.exifSummary
                        } else {
                            UIImageWriteToSavedPhotosAlbum(finalUIImage, nil, nil, nil)
                            self.statusMessage = "GUARDADA"
                        }
                    }
                })
            }
            
            await MainActor.run {
                self.doubleExposureFirstShot = nil
                self.capturedImage = finalUIImage
                self.isProcessing = false
            }
        }
    }
}

// MARK: - 4. Visor Óptico de Alta Precisión
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

// MARK: - 5. Capa de Previsualización Fiel en Vivo + Fantasma de Doble Exposición + Horizonte
struct LiveOpticalEffectsView: View {
    let profile: FilmProfile
    let contrastSCurve: Float
    let fadeMatteAmount: Float
    let vignetteIntensity: Float
    let grainIntensity: Float
    let bloomIntensity: Float
    let warmth: Float
    let portraitDepthBlur: Float
    let lightLeakEnabled: Bool
    let anamorphicMode: Bool
    let dateStampEnabled: Bool
    let frameStyle: FrameStyleOption
    let doubleExposureGhost: UIImage?
    
    private var currentDateStamp: String {
        let df = DateFormatter()
        df.dateFormat = "''yy MM dd"
        return df.string(from: Date())
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                filmLiveOverlay(for: profile)
                
                // Matte Fade Analógico en vivo
                if fadeMatteAmount > 0.02 {
                    Color(white: 0.14)
                        .opacity(Double(fadeMatteAmount) * 0.22)
                        .blendMode(.screen)
                }
                
                // Fantasma de la primera foto cuando está activa la Doble Exposición
                if let ghost = doubleExposureGhost {
                    Image(uiImage: ghost)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .opacity(0.42)
                        .blendMode(.screen)
                        .clipped()
                }
                
                if abs(warmth) > 0.02 {
                    (warmth > 0
                        ? Color(red: 1.0, green: 0.76, blue: 0.40)
                        : Color(red: 0.35, green: 0.75, blue: 1.0))
                        .opacity(Double(abs(warmth)) * 0.14)
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
                            Color.white.opacity(Double(bloomIntensity) * 0.15),
                            profile.badgeColor.opacity(Double(bloomIntensity) * 0.08),
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
                            Color(red: 1.0, green: 0.28, blue: 0.02).opacity(0.50),
                            Color(red: 1.0, green: 0.65, blue: 0.10).opacity(0.20),
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
                            Color(red: 0.15, green: 0.55, blue: 1.0).opacity(0.32),
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
                        Color.black.opacity(Double(vignetteIntensity) * 0.38 + Double(contrastSCurve) * 0.06),
                        Color.black.opacity(min(0.88, Double(vignetteIntensity) * 0.85 + Double(contrastSCurve) * 0.12))
                    ],
                    center: .center,
                    startRadius: min(geo.size.width, geo.size.height) * CGFloat(0.48 - Double(vignetteIntensity) * 0.15),
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
                                    with: .color((isBright ? Color.white : Color.black).opacity(Double(grainIntensity) * 0.28))
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
        case .ocamMaster, .cineChrome, .kodak2383:
            LinearGradient(
                colors: [
                    Color(white: 0.95).opacity(0.06),
                    Color.clear,
                    Color.black.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .aerochrome:
            Color(red: 0.95, green: 0.20, blue: 0.45).opacity(0.14).blendMode(.softLight)
        case .cinestill800T:
            Color(red: 0.20, green: 0.65, blue: 0.95).opacity(0.08).blendMode(.softLight)
        default:
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

// MARK: - 6. Laboratorio oCam Studio de Alta Precisión (2400px + Antes/Después + Sombras/Luces/Fade)
struct GalleryDarkroomView: View {
    let originalData: Data
    var onSaveSuccess: (UIImage, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfile: FilmProfile = .cineChrome
    @State private var activeTab: Int = 0
    @State private var exposureAdjust: Float = 0.0
    @State private var contrastSCurve: Float = 0.74
    @State private var shadowsAdjust: Float = 0.0
    @State private var highlightsAdjust: Float = 0.25
    @State private var fadeMatteAmount: Float = 0.22
    @State private var saturationAdjust: Float = -0.16
    @State private var warmthAdjust: Float = 0.06
    @State private var bloomAmount: Float = 0.36
    @State private var grainAmount: Float = 0.30
    @State private var vignetteAmount: Float = 0.30
    @State private var portraitDepthBlur: Float = 0.0
    @State private var lightLeakEnabled = false
    @State private var dateStampEnabled = false
    @State private var aspectRatio: AspectRatioOption = .fourThree
    @State private var frameStyle: FrameStyleOption = .none
    @State private var previewImage: UIImage?
    @State private var originalPreviewImage: UIImage?
    @State private var isShowingOriginal = false
    @State private var scaledCIImage: CIImage?
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Barra Superior
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
                            .background(selectedProfile.badgeColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Botón para ver el Antes / Después al tocar
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isShowingOriginal.toggle()
                    } label: {
                        Text(isShowingOriginal ? "ORIGINAL" : "COMPARAR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(isShowingOriginal ? .black : .white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(isShowingOriginal ? Color.white : Color.white.opacity(0.14))
                            .clipShape(Capsule())
                    }
                    
                    Menu {
                        Button("Recomendado (\(selectedProfile.rawValue))", systemImage: "sparkles") {
                            let rec = selectedProfile.recommended
                            exposureAdjust = 0.0
                            contrastSCurve = rec.contrastSCurve
                            shadowsAdjust = 0.0
                            highlightsAdjust = 0.20
                            fadeMatteAmount = rec.fadeMatte
                            saturationAdjust = rec.saturationAdjust
                            warmthAdjust = rec.warmth
                            bloomAmount = rec.bloom
                            grainAmount = rec.grain
                            vignetteAmount = rec.vignette
                            updatePreview()
                        }
                        Button("Restablecer a Cero", systemImage: "arrow.counterclockwise") {
                            exposureAdjust = 0.0
                            contrastSCurve = 0.35
                            shadowsAdjust = 0.0
                            highlightsAdjust = 0.0
                            fadeMatteAmount = 0.0
                            saturationAdjust = 0.0
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
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
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
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                
                // Visor de Alta Precisión (2200px)
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(white: 0.05))
                    
                    if let preview = (isShowingOriginal ? originalPreviewImage : previewImage) {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(6)
                    } else {
                        ProgressView().tint(.white)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(isShowingOriginal ? "ORIGINAL SIN FILTRO" : "oCam Studio • \(selectedProfile.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text("S-Curve \(String(format: "%.2f", contrastSCurve * 4.0)) | Fade \(Int(fadeMatteAmount * 100))%")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 12)
                
                // Panel de Controles de Precisión por Pestañas
                VStack(spacing: 10) {
                    if activeTab == 0 {
                        darkroomSlider(title: "S-Curve Contrast", value: $contrastSCurve, range: 0.0...1.0, format: "%.2f", multiplier: 4.0)
                        darkroomSlider(title: "Matte Fade (Roll-Off)", value: $fadeMatteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Highlights Protect", value: $highlightsAdjust, range: -0.5...1.0, format: "%+.2f")
                        darkroomSlider(title: "Shadows Lift / Deep", value: $shadowsAdjust, range: -0.6...0.8, format: "%+.2f")
                    } else if activeTab == 1 {
                        darkroomSlider(title: "Exposure (EV)", value: $exposureAdjust, range: -1.5...1.5, format: "%+.2f")
                        darkroomSlider(title: "Saturation (Organic)", value: $saturationAdjust, range: -0.6...0.5, format: "%+.2f")
                        darkroomSlider(title: "White Balance (WB)", value: $warmthAdjust, range: -1.0...1.0, format: "%+.2f")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FilmProfile.allCases) { profile in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedProfile = profile
                                        let rec = profile.recommended
                                        contrastSCurve = rec.contrastSCurve
                                        fadeMatteAmount = rec.fadeMatte
                                        saturationAdjust = rec.saturationAdjust
                                        warmthAdjust = rec.warmth
                                        bloomAmount = rec.bloom
                                        grainAmount = rec.grain
                                        vignetteAmount = rec.vignette
                                        updatePreview()
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(profile.rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                            Text(profile.subtitle.prefix(14))
                                                .font(.system(size: 8, design: .monospaced))
                                                .opacity(0.75)
                                        }
                                        .foregroundStyle(selectedProfile == profile ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(selectedProfile == profile ? profile.badgeColor : Color.white.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    } else if activeTab == 2 {
                        darkroomSlider(title: "35mm Film Grain", value: $grainAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Halation Glow", value: $bloomAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Optical Vignette", value: $vignetteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Portrait Bokeh", value: $portraitDepthBlur, range: 0.0...1.0, format: "f/%.1f", multiplier: 1.4)
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
                                        .background(aspectRatio == ratio ? selectedProfile.badgeColor : Color.white.opacity(0.12))
                                        .clipShape(Capsule())
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
                                    .background(dateStampEnabled ? selectedProfile.badgeColor : Color.white.opacity(0.12))
                                    .clipShape(Capsule())
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
                                    .background(lightLeakEnabled ? selectedProfile.badgeColor : Color.white.opacity(0.12))
                                    .clipShape(Capsule())
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
                                    .background(frameStyle != .none ? selectedProfile.badgeColor : Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            .background(activeTab == index ? Color.white.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func darkroomSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String, multiplier: Float = 1.0) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(String(format: format, value.wrappedValue * multiplier))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
            // Previsualización de alta resolución (2000px) para que el grano, halation y curvas se vean 1:1 con la foto final
            if maxDim > 2000 {
                let scale = 2000.0 / maxDim
                ci = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }
            let finalCI = ci
            let origUI: UIImage?
            if let cg = CinematicPipeline.shared.ciContext.createCGImage(finalCI, from: finalCI.extent) {
                origUI = UIImage(cgImage: cg)
            } else {
                origUI = nil
            }
            await MainActor.run {
                self.scaledCIImage = finalCI
                self.originalPreviewImage = origUI
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
        let shd = shadowsAdjust
        let hlt = highlightsAdjust
        let fade = fadeMatteAmount
        let sat = saturationAdjust
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
                shadowsAdjust: shd,
                highlightsAdjust: hlt,
                fadeMatteAmount: fade,
                saturationAdjust: sat,
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
        let shd = shadowsAdjust
        let hlt = highlightsAdjust
        let fade = fadeMatteAmount
        let sat = saturationAdjust
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
                wasCapturedAsRAW: false,
                profile: prof,
                contrastSCurve: sCurve,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                warmthAdjust: warm,
                exposureAdjust: exp,
                shadowsAdjust: shd,
                highlightsAdjust: hlt,
                fadeMatteAmount: fade,
                saturationAdjust: sat,
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

// MARK: - 7. Interfaz Principal oCam con Liquid Glass, Nivel Horizonte y Doble Exposición
struct GridOverlayView: View {
    let showHorizon: Bool
    let horizonDegrees: Double
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let isLevel = abs(horizonDegrees) < 1.2
            
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: w / 3, y: 0))
                    path.addLine(to: CGPoint(x: w / 3, y: h))
                    path.move(to: CGPoint(x: (w / 3) * 2, y: 0))
                    path.addLine(to: CGPoint(x: (w / 3) * 2, y: h))
                    path.move(to: CGPoint(x: 0, y: h / 3))
                    path.addLine(to: CGPoint(x: w, y: h / 3))
                    path.move(to: CGPoint(x: 0, y: (h / 3) * 2))
                    path.addLine(to: CGPoint(x: w, y: (h / 3) * 2))
                }
                .stroke(Color.white.opacity(0.18), lineWidth: 0.6)
                
                if showHorizon {
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 110, height: 1)
                        Rectangle()
                            .fill(isLevel ? Color.yellow : Color.white.opacity(0.85))
                            .frame(width: 64, height: isLevel ? 2.0 : 1.2)
                            .rotationEffect(.degrees(horizonDegrees))
                    }
                    .position(x: w / 2, y: h / 2)
                }
            }
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
                HStack(spacing: 8) {
                    Button {
                        camera.toggleSensorMode()
                    } label: {
                        Text(modeButtonTitle)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(camera.useRAWCapture || camera.use48MPMode ? camera.selectedProfile.badgeColor : Color.white.opacity(0.15))
                            .foregroundStyle(camera.useRAWCapture || camera.use48MPMode ? .black : .white)
                            .clipShape(Capsule())
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
                            .background(camera.nightModeEnabled ? Color.yellow : Color.white.opacity(0.12))
                            .clipShape(Circle())
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
                            .background(camera.portraitDepthBlur > 0.05 ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    // Botón de Doble Exposición Analógica (2X EXP)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.doubleExposureEnabled.toggle()
                        if !camera.doubleExposureEnabled {
                            camera.doubleExposureFirstShot = nil
                        }
                    } label: {
                        Image(systemName: "square.on.square.dashed")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(camera.doubleExposureEnabled ? .black : .white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(camera.doubleExposureEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                            .clipShape(Circle())
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
                            .foregroundStyle(showExposureBar || abs(camera.exposureEV + 0.35) > 0.05 ? camera.selectedProfile.badgeColor : .white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.flashEnabled.toggle()
                    } label: {
                        Image(systemName: camera.flashEnabled ? "bolt.fill" : "bolt.slash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(camera.flashEnabled ? .yellow : .white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
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
                            .background(showTray ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.6))
                .padding(.horizontal, 14)
                
                // 2. Visor Principal con Previsualización Fiel
                GeometryReader { outerGeo in
                    let availW = outerGeo.size.width
                    let availH = outerGeo.size.height
                    let targetRatio = camera.aspectRatio.portraitRatio
                    let frameW = min(availW, availH * targetRatio)
                    let frameH = min(availH, frameW / targetRatio)
                    
                    ZStack {
                        ZStack {
                            NativeCameraPreview(session: camera.session) { devicePt, viewPt in
                                camera.focusAt(normalizedPoint: devicePt, viewPoint: viewPt)
                            }
                            .contrast(liveContrast(for: camera.selectedProfile) + Double(camera.contrastSCurve) * 0.12)
                            .saturation(max(0.0, liveSaturation(for: camera.selectedProfile) + Double(camera.saturationAdjust) * 0.35))
                            
                            LiveOpticalEffectsView(
                                profile: camera.selectedProfile,
                                contrastSCurve: camera.contrastSCurve,
                                fadeMatteAmount: camera.fadeMatteAmount,
                                vignetteIntensity: camera.vignetteIntensity,
                                grainIntensity: camera.grainIntensity,
                                bloomIntensity: camera.bloomIntensity,
                                warmth: camera.warmth,
                                portraitDepthBlur: camera.portraitDepthBlur,
                                lightLeakEnabled: camera.lightLeakEnabled,
                                anamorphicMode: camera.anamorphicMode,
                                dateStampEnabled: camera.dateStampEnabled,
                                frameStyle: camera.frameStyle,
                                doubleExposureGhost: camera.doubleExposureFirstShot
                            )
                            
                            if camera.showGrid {
                                GridOverlayView(
                                    showHorizon: camera.showHorizonAndHistogram,
                                    horizonDegrees: camera.horizonAngleDegrees
                                )
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
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
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
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.6))
                                .padding(.horizontal, 24)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            if showTray {
                                VStack(spacing: 10) {
                                    HStack(spacing: 8) {
                                        trayTabPill(index: 0, title: "Tone & Fade")
                                        trayTabPill(index: 1, title: "Film & Grain")
                                        trayTabPill(index: 2, title: "Ratio & HUD")
                                        
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
                                            .background(camera.selectedProfile.badgeColor)
                                            .clipShape(Capsule())
                                        }
                                    }
                                    
                                    if activeDrawerTab == 0 {
                                        glassSliderRow(title: "EXPOSICIÓN", value: Binding(
                                            get: { camera.exposureEV },
                                            set: { camera.setExposure($0) }
                                        ), range: -2.0...1.5, text: String(format: "%+.1f EV", camera.exposureEV))
                                        
                                        glassSliderRow(title: "S-CURVE", value: $camera.contrastSCurve, range: 0.0...1.0, text: String(format: "%.2f", camera.contrastSCurve * 4.0))
                                        
                                        glassSliderRow(title: "MATTE FADE", value: $camera.fadeMatteAmount, range: 0.0...1.0, text: "\(Int(camera.fadeMatteAmount * 100))%")
                                        
                                        glassSliderRow(title: "TEMP (WB)", value: $camera.warmth, range: -1.0...1.0, text: String(format: "%+.1f", camera.warmth))
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
                                                        .background(camera.aspectRatio == ratio ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                                        .clipShape(Capsule())
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
                                                    .background(camera.dateStampEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                            
                                            Button {
                                                camera.lightLeakEnabled.toggle()
                                            } label: {
                                                Text(camera.lightLeakEnabled ? "LEAK: ON" : "LIGHT LEAK")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(camera.lightLeakEnabled ? .black : .white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(camera.lightLeakEnabled ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                                    .clipShape(Capsule())
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
                                                    .background(camera.frameStyle != .none ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                            
                                            Button {
                                                camera.showHorizonAndHistogram.toggle()
                                            } label: {
                                                Image(systemName: "level")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(camera.showHorizonAndHistogram ? .black : .white)
                                                    .padding(6)
                                                    .background(camera.showHorizonAndHistogram ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                                            .background(camera.currentZoom == level ? Color.black.opacity(0.65) : Color.clear)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.5))
                            .padding(.bottom, 8)
                        }
                    }
                    .frame(width: availW, height: availH)
                }
                
                // 3. Selector de las 16 Cámaras en Cápsulas Liquid Glass
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
                                .background(camera.selectedProfile == profile ? profile.badgeColor : Color.white.opacity(0.12))
                                .clipShape(Capsule())
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
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Button("Done") {
                            showFullPreview = false
                        }
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(camera.selectedProfile.badgeColor)
                        .clipShape(Capsule())
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
                .background(activeDrawerTab == index ? Color.white : Color.white.opacity(0.12))
                .clipShape(Capsule())
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
        case .triX400, .bleachBypass: return 1.20
        case .ocamMaster, .cineChrome, .kodak2383, .nocturnaClub: return 1.08
        case .polaroid600, .ilfordHP5: return 0.96
        default: return 1.06
        }
    }
    
    private func liveSaturation(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400, .ilfordHP5: return 0.0
        case .bleachBypass: return 0.45
        case .velvia50: return 1.12
        case .cineChrome: return 0.83
        case .ocamMaster, .polaroid600: return 0.88
        default: return 0.94
        }
    }
}
// FIN DEL ARCHIVO
