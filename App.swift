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

// MARK: - 1. Catálogo de 16 Cámaras con Química RGB Independiente
enum FilmProfile: String, CaseIterable, Identifiable {
    case cineChrome = "Palms 70s"
    case ocamMaster = "oCam"
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
        case .cineChrome: return "70s CREAM SKY & DEEP PINE"
        case .ocamMaster: return "NATURAL CINEMA ROLL-OFF"
        case .kodak2383: return "HOLLYWOOD TEAL & GOLD"
        case .nocturnaClub: return "NEON & DARK CLUB"
        case .portra400: return "WARM SKIN & GOLDEN LIGHT"
        case .cinestill800T: return "TUNGSTEN CYAN NIGHT"
        case .dispo98: return "90s GREEN SHADOW FLASH"
        case .ccd2004: return "Y2K CRISP DIGICAM"
        case .polaroid600: return "VINTAGE CREAM INSTANT"
        case .superia400: return "FUJI EMERALD & MAGENTA"
        case .velvia50: return "VIVID CHROME SLIDE"
        case .gold200: return "70s CALIFORNIA SUNSET"
        case .aerochrome: return "INFRARED CRIMSON TREES"
        case .bleachBypass: return "SILVER METALLIC GRIT"
        case .ilfordHP5: return "DOCUMENTARY B&W"
        case .triX400: return "CLASSIC DARKROOM B&W"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .cineChrome: return Color(red: 0.94, green: 0.76, blue: 0.48)
        case .ocamMaster: return Color(red: 0.92, green: 0.84, blue: 0.70)
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
        let shadowCrush: Float
        let creamHighlights: Float
        let redTrim: Float
        let greenTrim: Float
        let blueTrim: Float
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
        case .cineChrome:
            // CLON 1:1 DE LA FOTO DE LAS PALMERAS DE REFERENCIA:
            // Cielo crema cálido (blueTrim negativo + creamHighlights alto), palmeras verde pino oscuro (shadowCrush alto + greenTrim negativo),
            // Viñeta en 0.0 (0%) y Halation al máximo (1.0 / 100%)
            return RecommendedSettings(
                ev: -0.45, contrastSCurve: 0.82, shadowCrush: 0.48, creamHighlights: 0.68,
                redTrim: 0.18, greenTrim: -0.22, blueTrim: -0.42,
                warmth: 0.14, bloom: 1.00, grain: 0.32, vignette: 0.00, fadeMatte: 0.18, saturationAdjust: -0.24, nightMode: false
            )
        case .ocamMaster:
            return RecommendedSettings(
                ev: -0.35, contrastSCurve: 0.68, shadowCrush: 0.25, creamHighlights: 0.32,
                redTrim: 0.06, greenTrim: -0.08, blueTrim: -0.15,
                warmth: 0.04, bloom: 0.35, grain: 0.24, vignette: 0.18, fadeMatte: 0.14, saturationAdjust: -0.12, nightMode: false
            )
        case .kodak2383:
            // Print Film de Hollywood: Sombras densas cian/petróleo y altas luces doradas
            return RecommendedSettings(
                ev: -0.40, contrastSCurve: 0.84, shadowCrush: 0.42, creamHighlights: 0.55,
                redTrim: 0.12, greenTrim: -0.06, blueTrim: -0.25,
                warmth: 0.05, bloom: 0.40, grain: 0.26, vignette: 0.28, fadeMatte: 0.15, saturationAdjust: -0.10, nightMode: false
            )
        case .nocturnaClub:
            // Boliche / Bar oscuro: Negros profundos, neones intensos y halation alta
            return RecommendedSettings(
                ev: -0.60, contrastSCurve: 0.78, shadowCrush: 0.38, creamHighlights: 0.25,
                redTrim: 0.14, greenTrim: -0.12, blueTrim: 0.10,
                warmth: 0.0, bloom: 0.82, grain: 0.34, vignette: 0.32, fadeMatte: 0.10, saturationAdjust: 0.05, nightMode: true
            )
        case .portra400:
            // Kodak Portra 400: Pieles cálidas luminosas, verdes suaves y roll-off pastel
            return RecommendedSettings(
                ev: -0.25, contrastSCurve: 0.58, shadowCrush: 0.18, creamHighlights: 0.48,
                redTrim: 0.16, greenTrim: -0.05, blueTrim: -0.22,
                warmth: 0.12, bloom: 0.30, grain: 0.22, vignette: 0.14, fadeMatte: 0.18, saturationAdjust: -0.06, nightMode: false
            )
        case .cinestill800T:
            // Tungsteno nocturno: Frío azulado/cian en sombras y halos rojizos en luces
            return RecommendedSettings(
                ev: -0.45, contrastSCurve: 0.72, shadowCrush: 0.30, creamHighlights: 0.10,
                redTrim: -0.12, greenTrim: 0.04, blueTrim: 0.32,
                warmth: -0.24, bloom: 0.88, grain: 0.34, vignette: 0.28, fadeMatte: 0.12, saturationAdjust: -0.04, nightMode: true
            )
        case .dispo98:
            // Desechable años 90: Sombras lavadas verdosas y luces cálidas de flash
            return RecommendedSettings(
                ev: -0.20, contrastSCurve: 0.74, shadowCrush: 0.15, creamHighlights: 0.42,
                redTrim: 0.05, greenTrim: 0.22, blueTrim: -0.28,
                warmth: 0.06, bloom: 0.40, grain: 0.52, vignette: 0.42, fadeMatte: 0.32, saturationAdjust: -0.10, nightMode: false
            )
        case .ccd2004:
            // Digicam Y2K: Contraste digital marcado y azules profundos
            return RecommendedSettings(
                ev: -0.30, contrastSCurve: 0.70, shadowCrush: 0.30, creamHighlights: 0.0,
                redTrim: 0.04, greenTrim: -0.04, blueTrim: 0.14,
                warmth: -0.05, bloom: 0.15, grain: 0.18, vignette: 0.20, fadeMatte: 0.04, saturationAdjust: 0.12, nightMode: false
            )
        case .polaroid600:
            // Instantánea vintage: Sombras mate levantadas y marco crema cálido
            return RecommendedSettings(
                ev: -0.15, contrastSCurve: 0.52, shadowCrush: 0.10, creamHighlights: 0.62,
                redTrim: 0.20, greenTrim: 0.02, blueTrim: -0.35,
                warmth: 0.16, bloom: 0.48, grain: 0.30, vignette: 0.36, fadeMatte: 0.38, saturationAdjust: -0.18, nightMode: false
            )
        case .superia400:
            // Fuji Superia: Verdes esmeralda intensos y sombras con tinte magenta sutil
            return RecommendedSettings(
                ev: -0.35, contrastSCurve: 0.68, shadowCrush: 0.28, creamHighlights: 0.25,
                redTrim: 0.08, greenTrim: 0.16, blueTrim: -0.12,
                warmth: 0.0, bloom: 0.28, grain: 0.30, vignette: 0.24, fadeMatte: 0.14, saturationAdjust: -0.04, nightMode: false
            )
        case .velvia50:
            // Diapositiva Fuji: Negros profundos y colores vibrantes de paisaje
            return RecommendedSettings(
                ev: -0.45, contrastSCurve: 0.82, shadowCrush: 0.45, creamHighlights: 0.15,
                redTrim: 0.14, greenTrim: 0.08, blueTrim: 0.12,
                warmth: 0.04, bloom: 0.22, grain: 0.16, vignette: 0.28, fadeMatte: 0.05, saturationAdjust: 0.22, nightMode: false
            )
        case .gold200:
            // Kodak Gold 200: Hora dorada californiana cálida y nostálgica
            return RecommendedSettings(
                ev: -0.30, contrastSCurve: 0.66, shadowCrush: 0.26, creamHighlights: 0.58,
                redTrim: 0.22, greenTrim: 0.04, blueTrim: -0.34,
                warmth: 0.18, bloom: 0.36, grain: 0.28, vignette: 0.24, fadeMatte: 0.20, saturationAdjust: -0.04, nightMode: false
            )
        case .aerochrome:
            // Infrarrojo Kodak: Follaje carmesí y cielos dramáticos
            return RecommendedSettings(
                ev: -0.35, contrastSCurve: 0.74, shadowCrush: 0.35, creamHighlights: 0.20,
                redTrim: 0.45, greenTrim: -0.35, blueTrim: -0.10,
                warmth: 0.0, bloom: 0.38, grain: 0.26, vignette: 0.26, fadeMatte: 0.10, saturationAdjust: 0.08, nightMode: false
            )
        case .bleachBypass:
            // Retención de plata: Contraste metálico implacable y baja saturación
            return RecommendedSettings(
                ev: -0.45, contrastSCurve: 0.88, shadowCrush: 0.52, creamHighlights: 0.30,
                redTrim: -0.05, greenTrim: -0.05, blueTrim: -0.10,
                warmth: -0.06, bloom: 0.18, grain: 0.46, vignette: 0.42, fadeMatte: 0.14, saturationAdjust: -0.55, nightMode: false
            )
        case .ilfordHP5:
            return RecommendedSettings(
                ev: -0.30, contrastSCurve: 0.60, shadowCrush: 0.22, creamHighlights: 0.25,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.0,
                warmth: 0.0, bloom: 0.24, grain: 0.48, vignette: 0.28, fadeMatte: 0.24, saturationAdjust: -1.0, nightMode: false
            )
        case .triX400:
            return RecommendedSettings(
                ev: -0.40, contrastSCurve: 0.84, shadowCrush: 0.48, creamHighlights: 0.15,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.0,
                warmth: 0.0, bloom: 0.22, grain: 0.60, vignette: 0.38, fadeMatte: 0.10, saturationAdjust: -1.0, nightMode: false
            )
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

// MARK: - 2. Motor de Emulsión Química por Canales R-G-B Independientes (Clon Exacto de Referencia)
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
        shadowCrush: Float = 0.35,
        creamHighlights: Float = 0.45,
        redTrim: Float = 0.0,
        greenTrim: Float = 0.0,
        blueTrim: Float = 0.0,
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
        
        // 0. Exposición Base
        if abs(exposureAdjust) > 0.02 {
            let exp = CIFilter.exposureAdjust()
            exp.inputImage = current
            exp.ev = exposureAdjust
            if let out = exp.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 1. Neutralización Bayer RAW + Reducción de Ruido
        if isRAW {
            let rawGreenFix = CIFilter.colorMatrix()
            rawGreenFix.inputImage = current
            rawGreenFix.rVector = CIVector(x: 1.03, y: 0.00, z: 0.00, w: 0)
            rawGreenFix.gVector = CIVector(x: 0.00, y: 0.94, z: 0.00, w: 0)
            rawGreenFix.bVector = CIVector(x: 0.00, y: 0.00, z: 1.04, w: 0)
            if let out = rawGreenFix.outputImage?.cropped(to: extent) { current = out }
            
            let nr = CIFilter.noiseReduction()
            nr.inputImage = current
            nr.noiseLevel = 0.05
            nr.sharpness = 0.35
            if let out = nr.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 2. Temperatura de Color (WB)
        if abs(warmthAdjust) > 0.01 {
            let wbFix = CIFilter.temperatureAndTint()
            wbFix.inputImage = current
            wbFix.neutral = CIVector(x: 6500, y: 0)
            let userShift = CGFloat(-warmthAdjust * 1150)
            wbFix.targetNeutral = CIVector(x: 6500 + userShift, y: 0)
            if let out = wbFix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 3. Compresión de Altas Luces (Highlight Roll-off para apagar el brillo digital del cielo)
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        let baseHighlight: Float = nightModeBoost ? 0.18 : 0.22
        let baseShadow: Float = nightModeBoost ? 0.28 : (isRAW ? 0.12 : 0.04)
        hs.highlightAmount = max(0.02, min(1.0, baseHighlight - (highlightsAdjust * 0.35)))
        hs.shadowAmount = max(-0.5, min(1.0, baseShadow + (shadowsAdjust * 0.50)))
        hs.radius = Float(28.0 * scaleMultiplier)
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 4. QUÍMICA ESPECÍFICA DE CADA PELÍCULA + DENSIDAD DE FOLLAJE (El secreto de las Palmeras de Referencia)
        let matrix = CIFilter.colorMatrix()
        matrix.inputImage = current
        
        switch profile {
        case .cineChrome:
            // PALMS 70s (Clon exacto de image_c6935c.jpg):
            // - Oscurece la luminancia del verde de las hojas (Substractive Foliage) llevándolo a verde pino profundo/oliva
            // - Transforma el azul eléctrico del cielo en azul pizarra/petróleo vintage
            // - Calienta las nubes y las paredes blancas hacia un tono crema analógico de los años 70
            matrix.rVector = CIVector(x: 1.06, y: -0.08, z: -0.03, w: 0) // Restar verde (y: -0.08) oscurece las hojas verdes
            matrix.gVector = CIVector(x: 0.02, y: 0.86, z: 0.03, w: 0)  // Baja el verde chillón del iPhone a verde pino
            matrix.bVector = CIVector(x: -0.04, y: -0.08, z: 0.84, w: 0) // Recorta el azul brillante del cielo a crema/petróleo
            matrix.biasVector = CIVector(x: 0.012, y: 0.002, z: -0.022, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .ocamMaster:
            matrix.rVector = CIVector(x: 1.04, y: -0.04, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.01, y: 0.93, z: 0.02, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: -0.04, z: 0.92, w: 0)
            matrix.biasVector = CIVector(x: 0.006, y: 0.001, z: -0.010, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .kodak2383:
            // Print Film de Cine: Separación Teal & Gold de laboratorio cinematográfico
            matrix.rVector = CIVector(x: 1.08, y: -0.06, z: -0.04, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.94, z: 0.04, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: 0.04, z: 0.90, w: 0)
            matrix.biasVector = CIVector(x: 0.008, y: 0.00, z: -0.012, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .nocturnaClub:
            matrix.rVector = CIVector(x: 1.12, y: -0.03, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: -0.02, y: 0.95, z: 0.03, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.04, z: 1.04, w: 0)
            matrix.biasVector = CIVector(x: 0.004, y: -0.008, z: 0.010, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .portra400:
            matrix.rVector = CIVector(x: 1.07, y: -0.03, z: -0.03, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 0.94, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: -0.04, z: 0.89, w: 0)
            matrix.biasVector = CIVector(x: 0.010, y: 0.002, z: -0.014, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .cinestill800T:
            matrix.rVector = CIVector(x: 0.92, y: 0.02, z: 0.02, w: 0)
            matrix.gVector = CIVector(x: -0.01, y: 0.98, z: 0.04, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: 0.05, z: 1.10, w: 0)
            matrix.biasVector = CIVector(x: -0.010, y: 0.004, z: 0.020, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .dispo98:
            matrix.rVector = CIVector(x: 1.04, y: 0.02, z: -0.04, w: 0)
            matrix.gVector = CIVector(x: 0.01, y: 1.03, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.02, z: 0.86, w: 0)
            matrix.biasVector = CIVector(x: -0.005, y: 0.018, z: -0.012, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .ccd2004:
            matrix.rVector = CIVector(x: 1.03, y: 0.01, z: 0.01, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 0.97, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: 0.01, y: 0.01, z: 1.06, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .polaroid600:
            matrix.rVector = CIVector(x: 1.08, y: -0.02, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.03, y: 0.93, z: 0.00, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: -0.04, z: 0.82, w: 0)
            matrix.biasVector = CIVector(x: 0.022, y: 0.008, z: -0.024, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .superia400:
            matrix.rVector = CIVector(x: 1.04, y: -0.05, z: 0.03, w: 0)
            matrix.gVector = CIVector(x: -0.02, y: 1.02, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: 0.01, y: -0.02, z: 0.94, w: 0)
            matrix.biasVector = CIVector(x: 0.006, y: -0.004, z: 0.004, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .velvia50:
            matrix.rVector = CIVector(x: 1.08, y: -0.04, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: -0.02, y: 1.02, z: -0.01, w: 0)
            matrix.bVector = CIVector(x: -0.03, y: -0.02, z: 1.06, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .gold200:
            matrix.rVector = CIVector(x: 1.10, y: -0.02, z: -0.03, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 0.96, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: -0.04, z: 0.84, w: 0)
            matrix.biasVector = CIVector(x: 0.016, y: 0.006, z: -0.022, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .aerochrome:
            matrix.rVector = CIVector(x: 0.45, y: 0.68, z: -0.10, w: 0)
            matrix.gVector = CIVector(x: 0.22, y: 0.52, z: 0.20, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: 0.08, z: 0.95, w: 0)
            if let out = matrix.outputImage?.cropped(to: extent) { current = out }
            
        case .bleachBypass, .ilfordHP5, .triX400:
            break
        }
        
        // 5. AJUSTE FINO DE CANALES R-G-B Y CREAM HIGHLIGHTS (Personalizable por el usuario y por cada cámara)
        if abs(redTrim) > 0.01 || abs(greenTrim) > 0.01 || abs(blueTrim) > 0.01 || creamHighlights > 0.02 {
            let rgbTuner = CIFilter.colorMatrix()
            rgbTuner.inputImage = current
            let rGain = CGFloat(1.0 + redTrim * 0.28 + creamHighlights * 0.06)
            let gGain = CGFloat(1.0 + greenTrim * 0.28 + creamHighlights * 0.02)
            let bGain = CGFloat(1.0 + blueTrim * 0.32 - creamHighlights * 0.14)
            // Cuando greenTrim es negativo, oscurece selectivamente las hojas verdes restando verde en el canal rojo/azul
            let foliagePull = CGFloat(min(0.0, greenTrim) * 0.18)
            
            rgbTuner.rVector = CIVector(x: rGain, y: foliagePull, z: 0, w: 0)
            rgbTuner.gVector = CIVector(x: 0, y: gGain, z: 0, w: 0)
            rgbTuner.bVector = CIVector(x: 0, y: foliagePull * 0.5, z: bGain, w: 0)
            rgbTuner.biasVector = CIVector(
                x: CGFloat(creamHighlights * 0.012),
                y: CGFloat(creamHighlights * 0.004),
                z: CGFloat(-creamHighlights * 0.018),
                w: 0
            )
            if let out = rgbTuner.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 6. Control de Saturación y Vibrance (Apaga el verde y azul fosforescente digital)
        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = current
        vibrance.amount = (profile == .cineChrome) ? -0.28 : (profile == .velvia50 ? 0.15 : -0.14)
        if let out = vibrance.outputImage?.cropped(to: extent) { current = out }
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = current
        if profile == .ilfordHP5 {
            colorControls.saturation = 0.0
            colorControls.contrast = 0.98
        } else if profile == .triX400 {
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = current
            if let out = noir.outputImage?.cropped(to: extent) { current = out }
            colorControls.inputImage = current
            colorControls.saturation = 0.0
            colorControls.contrast = 1.08
        } else {
            colorControls.saturation = max(0.0, 0.92 + saturationAdjust * 0.45)
            colorControls.contrast = 1.04
        }
        if let out = colorControls.outputImage?.cropped(to: extent) { current = out }
        
        // 7. CURVA S + SHADOW CRUSH + CREAM ROLL-OFF (Iguala la densidad oscura de las palmeras y el cielo sedoso)
        let sAmount = Double(contrastSCurve)
        let crush = Double(shadowCrush)
        let matteLift = Double(fadeMatteAmount) * 0.075
        let creamRoll = Double(creamHighlights) * 0.065
        
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        let blackPoint = min(0.11, 0.012 + matteLift)
        // Shadow Crush hunde el punto 1 (sombras bajas) y baja ligeramente el punto medio (0.45) para dar el peso analógico de la foto de referencia
        let shadowDip = max(0.08, 0.22 - (sAmount * 0.08) - (crush * 0.09) + (matteLift * 0.25))
        let midTone = max(0.41, 0.49 - (crush * 0.09))
        let highShoulder = min(0.84, 0.74 + (sAmount * 0.05) - (creamRoll * 0.30))
        let whiteRollOff = max(0.86, 0.93 - creamRoll) // Comprime los blancos altos a papel crema
        
        curve.point0 = CGPoint(x: 0.00, y: blackPoint)
        curve.point1 = CGPoint(x: 0.25, y: shadowDip)
        curve.point2 = CGPoint(x: 0.50, y: midTone)
        curve.point3 = CGPoint(x: 0.75, y: highShoulder)
        curve.point4 = CGPoint(x: 1.00, y: whiteRollOff)
        if let out = curve.outputImage?.cropped(to: extent) { current = out }
        
        // 8. Micro-contraste Óptico en Hojas y Texturas
        let clarity = CIFilter.unsharpMask()
        clarity.inputImage = current
        clarity.radius = Float(min(18.0, 11.0 * scaleMultiplier))
        clarity.intensity = 0.26
        if let out = clarity.outputImage?.cropped(to: extent) { current = out }
        
        // 9. Modo Retrato Óptico
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
        
        // 10. Halation / Difusión Cálida Analógica (En Palms 70s suaviza el contraluz del cielo alrededor de las hojas)
        if bloomAmount > 0.04 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = Float(min(22.0, 15.0 * scaleMultiplier))
            bloom.intensity = bloomAmount * (profile == .nocturnaClub ? 0.65 : 0.48)
            if let out = bloom.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 11. Viñeteado Óptico (0.0 por defecto en Palms 70s)
        if vignetteAmount > 0.02 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = current
            vignette.intensity = vignetteAmount * 1.40
            vignette.radius = 1.72
            if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 12. Fuga de Luz Analógica Opcional
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
        
        // 13. Lente Anamórfico Opcional
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
        
        // 14. Grano 35mm Real Escalado a los Megapíxeles
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
        shadowCrush: Float,
        creamHighlights: Float,
        redTrim: Float,
        greenTrim: Float,
        blueTrim: Float,
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
            shadowCrush: shadowCrush,
            creamHighlights: creamHighlights,
            redTrim: redTrim,
            greenTrim: greenTrim,
            blueTrim: blueTrim,
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
        wbTemp: Float = 0.0,
        wbTint: Float = 0.0,
        profile: FilmProfile,
        contrastSCurve: Float,
        shadowCrush: Float = 0.35,
        creamHighlights: Float = 0.45,
        redTrim: Float = 0.0,
        greenTrim: Float = 0.0,
        blueTrim: Float = 0.0,
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
        
        if wasCapturedAsRAW && !isFromGallery, let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
            rawFilter.luminanceNoiseReductionAmount = 0.94
            rawFilter.colorNoiseReductionAmount = 1.00
            rawFilter.sharpnessAmount = 0.20
            rawFilter.localToneMapAmount = 0.0
            rawFilter.boostAmount = 0.48
            rawFilter.baselineExposure = -0.15
            rawFilter.scaleFactor = 1.0
            
            if wbTemp > 2000 && wbTemp < 10000 {
                rawFilter.neutralTemperature = wbTemp
                rawFilter.neutralTint = wbTint
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
            if !isFromGallery {
                if std.extent.width > std.extent.height && !deviceOrientation.isLandscape {
                    std = std.oriented(.right)
                } else if std.extent.height > std.extent.width && deviceOrientation == .landscapeLeft {
                    std = std.oriented(.left)
                } else if std.extent.height > std.extent.width && deviceOrientation == .landscapeRight {
                    std = std.oriented(.right)
                }
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
            shadowCrush: shadowCrush,
            creamHighlights: creamHighlights,
            redTrim: redTrim,
            greenTrim: greenTrim,
            blueTrim: blueTrim,
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
    var doubleExposureFirstShot: UIImage?
    var isProcessing = false
    var isRAWActive = false
    var is48MPSupported = false
    var use48MPMode = true
    var useRAWCapture = false
    var doubleExposureEnabled = false
    var showHorizonAndHistogram = false
    var horizonAngleDegrees: Double = 0.0
    var statusMessage = "48MP PRO"
    var lastExifSummary = "1/125s | f/1.6 | ISO 64"
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .cineChrome // Arranca en Palms 70s por defecto
    
    // Parámetros inicializados con la receta exacta de las Palmeras 70s
    var exposureEV: Float = -0.45
    var contrastSCurve: Float = 0.82
    var shadowCrush: Float = 0.48
    var creamHighlights: Float = 0.68
    var redTrim: Float = 0.18
    var greenTrim: Float = -0.22
    var blueTrim: Float = -0.42
    var warmth: Float = 0.14
    var bloomIntensity: Float = 1.00
    var grainIntensity: Float = 0.32
    var vignetteIntensity: Float = 0.00
    var fadeMatteAmount: Float = 0.18
    var saturationAdjust: Float = -0.24
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
    
    var uiRotationDegrees: Double {
        switch physicalOrientation {
        case .landscapeLeft: return 90.0
        case .landscapeRight: return -90.0
        case .portraitUpsideDown: return 180.0
        default: return 0.0
        }
    }
    
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
        shadowCrush = rec.shadowCrush
        creamHighlights = rec.creamHighlights
        redTrim = rec.redTrim
        greenTrim = rec.greenTrim
        blueTrim = rec.blueTrim
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
        shadowCrush = 0.0
        creamHighlights = 0.0
        redTrim = 0.0
        greenTrim = 0.0
        blueTrim = 0.0
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
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
                let zStr = self.currentZoom == 0.5 ? "0.5x" : "\(Int(self.currentZoom))x"
                self.statusMessage = "LENTE \(zStr) 12MP"
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
        
        var measuredTemp: Float = 0.0
        var measuredTint: Float = 0.0
        if let dev = self.currentDevice {
            let tt = dev.temperatureAndTintValues(for: dev.deviceWhiteBalanceGains)
            measuredTemp = tt.temperature
            measuredTint = tt.tint
        }
        
        let wasRAW = photo.isRawPhoto
        let photoMeta = photo.metadata
        let profile = self.selectedProfile
        let sCurve = self.contrastSCurve
        let crush = self.shadowCrush
        let cream = self.creamHighlights
        let rTrim = self.redTrim
        let gTrim = self.greenTrim
        let bTrim = self.blueTrim
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
                wbTemp: measuredTemp,
                wbTint: measuredTint,
                profile: profile,
                contrastSCurve: sCurve,
                shadowCrush: crush,
                creamHighlights: cream,
                redTrim: rTrim,
                greenTrim: gTrim,
                blueTrim: bTrim,
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
            
            guard let initialImage = result.previewImage else {
                await MainActor.run { self.isProcessing = false }
                return
            }
            
            if isDoubleExp && firstShot == nil {
                await MainActor.run {
                    self.doubleExposureFirstShot = initialImage
                    self.statusMessage = "2X EXP: TOMA 2/2"
                    self.isProcessing = false
                }
                return
            }
            
            let outputImage: UIImage
            let finalDataToSave: Data?
            if isDoubleExp, let baseShot = firstShot {
                let blended = CinematicPipeline.shared.blendDoubleExposure(base: baseShot, overlay: initialImage)
                outputImage = blended
                finalDataToSave = blended.jpegData(compressionQuality: 0.96)
            } else {
                outputImage = initialImage
                finalDataToSave = result.jpegData
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
                            UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
                            self.statusMessage = "GUARDADA"
                        }
                    }
                })
            }
            
            await MainActor.run {
                self.doubleExposureFirstShot = nil
                self.capturedImage = outputImage
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

// MARK: - 5. Capa de Previsualización Fiel en Vivo (Con soporte para Canales RGB y Cream Highlights)
struct LiveOpticalEffectsView: View {
    let profile: FilmProfile
    let contrastSCurve: Float
    let shadowCrush: Float
    let creamHighlights: Float
    let redTrim: Float
    let greenTrim: Float
    let blueTrim: Float
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
                
                // Previsualización en vivo de Cream Highlights y balance R-G-B
                if creamHighlights > 0.02 || abs(redTrim) > 0.02 || abs(blueTrim) > 0.02 {
                    Color(
                        red: min(1.0, max(0.0, 0.90 + Double(redTrim) * 0.25 + Double(creamHighlights) * 0.12)),
                        green: min(1.0, max(0.0, 0.84 + Double(greenTrim) * 0.20 + Double(creamHighlights) * 0.06)),
                        blue: min(1.0, max(0.0, 0.72 + Double(blueTrim) * 0.30 - Double(creamHighlights) * 0.22))
                    )
                    .opacity(0.18)
                    .blendMode(.softLight)
                }
                
                if fadeMatteAmount > 0.02 {
                    Color(white: 0.14)
                        .opacity(Double(fadeMatteAmount) * 0.22)
                        .blendMode(.screen)
                }
                
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
                        .opacity(Double(abs(warmth)) * 0.16)
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
                            Color(red: 1.0, green: 0.94, blue: 0.82).opacity(Double(bloomIntensity) * 0.16),
                            profile.badgeColor.opacity(Double(bloomIntensity) * 0.09),
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
                
                if vignetteIntensity > 0.01 {
                    RadialGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(Double(vignetteIntensity) * 0.38),
                            Color.black.opacity(min(0.88, Double(vignetteIntensity) * 0.85))
                        ],
                        center: .center,
                        startRadius: min(geo.size.width, geo.size.height) * CGFloat(0.48 - Double(vignetteIntensity) * 0.15),
                        endRadius: max(geo.size.width, geo.size.height) * 0.72
                    )
                }
                
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
        case .cineChrome:
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.90, blue: 0.72).opacity(0.18),
                    Color(red: 0.12, green: 0.28, blue: 0.22).opacity(0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .ocamMaster, .kodak2383:
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.90, blue: 0.78).opacity(0.10),
                    Color(red: 0.08, green: 0.20, blue: 0.24).opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .portra400, .gold200, .polaroid600:
            Color(red: 1.0, green: 0.82, blue: 0.55).opacity(0.14).blendMode(.softLight)
        case .aerochrome:
            Color(red: 0.95, green: 0.20, blue: 0.45).opacity(0.16).blendMode(.softLight)
        case .cinestill800T:
            Color(red: 0.20, green: 0.65, blue: 0.95).opacity(0.12).blendMode(.softLight)
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

// MARK: - 6. Laboratorio oCam Studio con Mixer R-G-B, Cream Sky y Shadow Crush
struct GalleryDarkroomView: View {
    let originalData: Data
    var onSaveSuccess: (UIImage, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfile: FilmProfile = .cineChrome
    @State private var activeTab: Int = 0
    @State private var exposureAdjust: Float = -0.10
    @State private var contrastSCurve: Float = 0.82
    @State private var shadowCrush: Float = 0.48
    @State private var creamHighlights: Float = 0.68
    @State private var redTrim: Float = 0.18
    @State private var greenTrim: Float = -0.22
    @State private var blueTrim: Float = -0.42
    @State private var shadowsAdjust: Float = 0.0
    @State private var highlightsAdjust: Float = 0.25
    @State private var fadeMatteAmount: Float = 0.18
    @State private var saturationAdjust: Float = -0.24
    @State private var warmthAdjust: Float = 0.14
    @State private var bloomAmount: Float = 1.00
    @State private var grainAmount: Float = 0.32
    @State private var vignetteAmount: Float = 0.00
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
                HStack(spacing: 10) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedProfile.badgeColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isShowingOriginal.toggle()
                    } label: {
                        Text(isShowingOriginal ? "ORIGINAL" : "COMPARAR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(isShowingOriginal ? .black : .white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(isShowingOriginal ? Color.white : Color.white.opacity(0.14))
                            .clipShape(Capsule())
                    }
                    
                    Menu {
                        Button("Recomendado (\(selectedProfile.rawValue))", systemImage: "sparkles") {
                            let rec = selectedProfile.recommended
                            exposureAdjust = -0.10
                            contrastSCurve = rec.contrastSCurve
                            shadowCrush = rec.shadowCrush
                            creamHighlights = rec.creamHighlights
                            redTrim = rec.redTrim
                            greenTrim = rec.greenTrim
                            blueTrim = rec.blueTrim
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
                            shadowCrush = 0.0
                            creamHighlights = 0.0
                            redTrim = 0.0
                            greenTrim = 0.0
                            blueTrim = 0.0
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
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
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
                
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(white: 0.05))
                    
                    if let preview = (isShowingOriginal ? originalPreviewImage : previewImage) {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(8)
                    } else {
                        ProgressView().tint(.white)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(isShowingOriginal ? "ORIGINAL SIN FILTRO" : "oCam Studio • \(selectedProfile.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text("R:\(String(format: "%+.1f", redTrim)) G:\(String(format: "%+.1f", greenTrim)) B:\(String(format: "%+.1f", blueTrim)) | Cream \(Int(creamHighlights * 100))%")
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
                .padding(.horizontal, 14)
                
                VStack(spacing: 8) {
                    if activeTab == 0 {
                        darkroomSlider(title: "S-Curve Contrast", value: $contrastSCurve, range: 0.0...1.0, format: "%.2f", multiplier: 4.0)
                        darkroomSlider(title: "Shadow Crush (Deep)", value: $shadowCrush, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Cream Sky Roll-Off", value: $creamHighlights, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Matte Fade", value: $fadeMatteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Exposure (EV)", value: $exposureAdjust, range: -1.5...1.5, format: "%+.2f")
                    } else if activeTab == 1 {
                        darkroomSlider(title: "Red Channel (Warm)", value: $redTrim, range: -0.6...0.6, format: "%+.2f")
                        darkroomSlider(title: "Green (Pine Foliage)", value: $greenTrim, range: -0.6...0.6, format: "%+.2f")
                        darkroomSlider(title: "Blue (Cream / Teal Sky)", value: $blueTrim, range: -0.6...0.6, format: "%+.2f")
                        darkroomSlider(title: "Saturation (Organic)", value: $saturationAdjust, range: -0.6...0.5, format: "%+.2f")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FilmProfile.allCases) { profile in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedProfile = profile
                                        let rec = profile.recommended
                                        contrastSCurve = rec.contrastSCurve
                                        shadowCrush = rec.shadowCrush
                                        creamHighlights = rec.creamHighlights
                                        redTrim = rec.redTrim
                                        greenTrim = rec.greenTrim
                                        blueTrim = rec.blueTrim
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
                                                .lineLimit(1)
                                            Text(profile.subtitle.prefix(14))
                                                .font(.system(size: 8, design: .monospaced))
                                                .lineLimit(1)
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
                        darkroomSlider(title: "Halation Glow", value: $bloomAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "35mm Film Grain", value: $grainAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Optical Vignette", value: $vignetteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "White Balance (WB)", value: $warmthAdjust, range: -1.0...1.0, format: "%+.2f")
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
                    studioTabButton(index: 1, icon: "slider.horizontal.below.square.and.square.filled", title: "RGB")
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
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
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
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(String(format: format, value.wrappedValue * multiplier))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
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
        let crush = shadowCrush
        let cream = creamHighlights
        let rTrim = redTrim
        let gTrim = greenTrim
        let bTrim = blueTrim
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
        
        Task.detached(priority: .userInitiated) {
            guard var img = CinematicPipeline.shared.renderPreviewUIImage(
                from: baseCI,
                profile: prof,
                contrastSCurve: sCurve,
                shadowCrush: crush,
                creamHighlights: cream,
                redTrim: rTrim,
                greenTrim: gTrim,
                blueTrim: bTrim,
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
        let crush = shadowCrush
        let cream = creamHighlights
        let rTrim = redTrim
        let gTrim = greenTrim
        let bTrim = blueTrim
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
                shadowCrush: crush,
                creamHighlights: cream,
                redTrim: rTrim,
                greenTrim: gTrim,
                blueTrim: bTrim,
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

// MARK: - 7. Interfaz Principal oCam Modular con Pestaña RGB Directa
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
    @State private var activeDrawerTab: Int = 0 // 0: Tone, 1: RGB, 2: Grain, 3: Format
    @State private var showFullPreview = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedPhotoData: Data?
    @State private var showDarkroom = false
    
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0, 3.0]
    
    private var modeButtonTitle: String {
        if camera.currentZoom != 1.0 { return "12MP" }
        if camera.use48MPMode && camera.is48MPSupported { return "48MP" }
        if camera.useRAWCapture { return "RAW" }
        return "12MP"
    }
    
    private var hasExtraFeaturesActive: Bool {
        camera.timerSeconds > 0 || camera.nightModeEnabled || camera.portraitDepthBlur > 0.05 || camera.doubleExposureEnabled || camera.dateStampEnabled || camera.lightLeakEnabled
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                topBarView
                viewfinderSection
                filmCarouselView
                bottomShutterBarView
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
            fullPreviewSheet
        }
    }
    
    private var topBarView: some View {
        HStack(spacing: 10) {
            Button {
                camera.toggleSensorMode()
            } label: {
                Text(modeButtonTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(camera.useRAWCapture || camera.use48MPMode ? camera.selectedProfile.badgeColor : Color.white.opacity(0.15))
                    .foregroundStyle(camera.useRAWCapture || camera.use48MPMode ? .black : .white)
                    .clipShape(Capsule())
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                camera.flashEnabled.toggle()
            } label: {
                Image(systemName: camera.flashEnabled ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(camera.flashEnabled ? .yellow : .white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
                    .rotationEffect(.degrees(camera.uiRotationDegrees))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
            }
            
            Spacer(minLength: 4)
            
            HStack(spacing: 6) {
                Text("oCam")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(.white.opacity(0.95))
                
                if camera.timerSeconds > 0 {
                    Text("\(camera.timerSeconds)s")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
            }
            
            Spacer(minLength: 4)
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showExposureBar.toggle()
                    if showExposureBar { showTray = false }
                }
            } label: {
                Image(systemName: "plusminus.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(showExposureBar ? camera.selectedProfile.badgeColor : .white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
                    .rotationEffect(.degrees(camera.uiRotationDegrees))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
            }
            
            extraFeaturesMenu
            
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
                    .frame(width: 34, height: 34)
                    .background(showTray ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.6))
        .padding(.horizontal, 16)
    }
    
    private var extraFeaturesMenu: some View {
        Menu {
            Button("Temporizador: OFF") { camera.timerSeconds = 0 }
            Button("Temporizador: 3s") { camera.timerSeconds = 3 }
            Button("Temporizador: 10s") { camera.timerSeconds = 10 }
            
            Divider()
            
            Button(camera.nightModeEnabled ? "Modo Noche: ON" : "Activar Modo Noche") {
                camera.nightModeEnabled.toggle()
                camera.updateNightModeHardware()
            }
            Button(camera.portraitDepthBlur > 0.05 ? "Modo Retrato (f/1.4): ON" : "Activar Modo Retrato (f/1.4)") {
                camera.portraitDepthBlur = (camera.portraitDepthBlur > 0.05) ? 0.0 : 0.65
            }
            Button(camera.doubleExposureEnabled ? "Doble Exposición (2X): ON" : "Activar Doble Exposición (2X)") {
                camera.doubleExposureEnabled.toggle()
                if !camera.doubleExposureEnabled { camera.doubleExposureFirstShot = nil }
            }
            Button(camera.anamorphicMode ? "Destello Anamórfico: ON" : "Activar Destello Anamórfico") {
                camera.anamorphicMode.toggle()
            }
            
            Divider()
            
            Button(camera.dateStampEnabled ? "Fechador '98: ON" : "Activar Fechador '98") {
                camera.dateStampEnabled.toggle()
            }
            Button(camera.lightLeakEnabled ? "Light Leak: ON" : "Activar Light Leak") {
                camera.lightLeakEnabled.toggle()
            }
            Button(camera.showGrid ? "Ocultar Cuadrícula" : "Mostrar Cuadrícula") {
                camera.showGrid.toggle()
            }
            Button(camera.showHorizonAndHistogram ? "Ocultar Nivel Horizonte" : "Mostrar Nivel Horizonte") {
                camera.showHorizonAndHistogram.toggle()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(hasExtraFeaturesActive ? .black : .white)
                .frame(width: 34, height: 34)
                .background(hasExtraFeaturesActive ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                .clipShape(Circle())
                .rotationEffect(.degrees(camera.uiRotationDegrees))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
        }
    }
    
    private var viewfinderSection: some View {
        GeometryReader { outerGeo in
            let sideMargin: CGFloat = 36.0
            let availW = max(100, outerGeo.size.width - sideMargin)
            let availH = max(100, outerGeo.size.height - 6)
            let targetRatio = camera.aspectRatio.portraitRatio
            let frameW = min(availW, availH * targetRatio)
            let frameH = min(availH, frameW / targetRatio)
            
            ZStack {
                ZStack {
                    NativeCameraPreview(session: camera.session) { devicePt, viewPt in
                        camera.focusAt(normalizedPoint: devicePt, viewPoint: viewPt)
                    }
                    .contrast(liveContrast(for: camera.selectedProfile) + Double(camera.contrastSCurve) * 0.14)
                    .saturation(max(0.0, liveSaturation(for: camera.selectedProfile) + Double(camera.saturationAdjust) * 0.35))
                    
                    LiveOpticalEffectsView(
                        profile: camera.selectedProfile,
                        contrastSCurve: camera.contrastSCurve,
                        shadowCrush: camera.shadowCrush,
                        creamHighlights: camera.creamHighlights,
                        redTrim: camera.redTrim,
                        greenTrim: camera.greenTrim,
                        blueTrim: camera.blueTrim,
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
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(camera.selectedProfile.badgeColor, lineWidth: 1.5)
                                .frame(width: 62, height: 62)
                            
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(camera.selectedProfile.badgeColor)
                        }
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
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.9)
                )
                .shadow(color: .black.opacity(0.5), radius: 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: camera.aspectRatio)
                
                VStack {
                    HStack(spacing: 6) {
                        Text("\(camera.selectedProfile.rawValue) • \(camera.statusMessage)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 12)
                    
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
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(camera.selectedProfile.badgeColor)
                                .frame(width: 54)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.6))
                        .padding(.horizontal, 28)
                    }
                    
                    if showTray {
                        controlsDrawerView
                    }
                    
                    HStack(spacing: 6) {
                        ForEach(zoomLevels, id: \.self) { level in
                            Button {
                                camera.switchCameraLens(factor: level)
                            } label: {
                                Text(level == 0.5 ? ".5" : "\(Int(level))×")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundStyle(camera.currentZoom == level ? camera.selectedProfile.badgeColor : .white)
                                    .frame(width: 34, height: 34)
                                    .background(camera.currentZoom == level ? Color.black.opacity(0.65) : Color.clear)
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(camera.uiRotationDegrees))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
                            }
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.5))
                    .padding(.bottom, 10)
                }
            }
            .frame(width: outerGeo.size.width, height: outerGeo.size.height)
        }
    }
    
    private var controlsDrawerView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                trayTabPill(index: 0, title: "Tone")
                trayTabPill(index: 1, title: "RGB")
                trayTabPill(index: 2, title: "Grain")
                trayTabPill(index: 3, title: "Format")
                
                Spacer(minLength: 2)
                
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
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
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
                
                glassSliderRow(title: "DARK CRUSH", value: $camera.shadowCrush, range: 0.0...1.0, text: "\(Int(camera.shadowCrush * 100))%")
                
                glassSliderRow(title: "CREAM SKY", value: $camera.creamHighlights, range: 0.0...1.0, text: "\(Int(camera.creamHighlights * 100))%")
            } else if activeDrawerTab == 1 {
                glassSliderRow(title: "RED GAIN", value: $camera.redTrim, range: -0.6...0.6, text: String(format: "%+.2f", camera.redTrim))
                
                glassSliderRow(title: "GREEN PINE", value: $camera.greenTrim, range: -0.6...0.6, text: String(format: "%+.2f", camera.greenTrim))
                
                glassSliderRow(title: "BLUE SKY", value: $camera.blueTrim, range: -0.6...0.6, text: String(format: "%+.2f", camera.blueTrim))
                
                glassSliderRow(title: "SATURACIÓN", value: $camera.saturationAdjust, range: -0.6...0.5, text: String(format: "%+.2f", camera.saturationAdjust))
            } else if activeDrawerTab == 2 {
                glassSliderRow(title: "HALATION", value: $camera.bloomIntensity, range: 0.0...1.0, text: "\(Int(camera.bloomIntensity * 100))%")
                
                glassSliderRow(title: "GRANO 35MM", value: $camera.grainIntensity, range: 0.0...1.0, text: "\(Int(camera.grainIntensity * 100))%")
                
                glassSliderRow(title: "VIÑETEADO", value: $camera.vignetteIntensity, range: 0.0...1.0, text: "\(Int(camera.vignetteIntensity * 100))%")
                
                glassSliderRow(title: "MATTE FADE", value: $camera.fadeMatteAmount, range: 0.0...1.0, text: "\(Int(camera.fadeMatteAmount * 100))%")
            } else {
                HStack(spacing: 6) {
                    ForEach(AspectRatioOption.allCases, id: \.self) { ratio in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            camera.aspectRatio = ratio
                        } label: {
                            Text(ratio.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(camera.aspectRatio == ratio ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(camera.aspectRatio == ratio ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    ForEach(FrameStyleOption.allCases, id: \.self) { style in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            camera.frameStyle = style
                        } label: {
                            Text(style.rawValue)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(camera.frameStyle == style ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(camera.frameStyle == style ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.18), lineWidth: 0.7))
        .padding(.horizontal, 24)
    }
    
    private var filmCarouselView: some View {
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
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
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
    }
    
    private var bottomShutterBarView: some View {
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
            .rotationEffect(.degrees(camera.uiRotationDegrees))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
            
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
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
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
            .rotationEffect(.degrees(camera.uiRotationDegrees))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private var fullPreviewSheet: some View {
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
    
    @ViewBuilder
    private func trayTabPill(index: Int, title: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                activeDrawerTab = index
            }
        } label: {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(activeDrawerTab == index ? .black : .white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(activeDrawerTab == index ? Color.white : Color.white.opacity(0.12))
                .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func glassSliderRow(title: String, value: Binding<Float>, range: ClosedRange<Float>, text: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 74, alignment: .leading)
            Slider(value: value, in: range)
                .tint(camera.selectedProfile.badgeColor)
            Text(text)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(camera.selectedProfile.badgeColor)
                .frame(width: 48, alignment: .trailing)
        }
    }
    
    private func liveContrast(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400, .bleachBypass: return 1.22
        case .cineChrome, .kodak2383: return 1.14
        case .ocamMaster, .nocturnaClub: return 1.10
        case .polaroid600, .ilfordHP5: return 0.96
        default: return 1.08
        }
    }
    
    private func liveSaturation(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400, .ilfordHP5: return 0.0
        case .bleachBypass: return 0.45
        case .velvia50: return 1.16
        case .cineChrome: return 0.78
        case .ocamMaster, .polaroid600: return 0.86
        default: return 0.92
        }
    }
}
// FIN DEL ARCHIVO
