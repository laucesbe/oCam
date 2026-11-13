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

// MARK: - 1. Estructura de los 20 Parámetros del Motor Cinematográfico de oCam
struct FilmLookParameters {
    var ev: Float = -0.25
    var contrastSCurve: Float = 0.55
    var curvePivot: Float = 0.64        // Pivote de curva S (0.64 como en referencia)
    var skyGlow: Float = 0.35           // Levanta y suaviza las nubes/cielo sin ensuciarlas
    var shadows: Float = 0.0
    var highlights: Float = 0.20
    var blackCrush: Float = 0.22
    var fadeMatte: Float = 0.14
    var warmth: Float = 0.0
    var tint: Float = 0.0
    var saturation: Float = -0.12
    var vibrance: Float = -0.15
    var foliageHue: Float = 0.0         // Desplaza el verde hacia pino profundo/bosque (sin amarillo)
    var foliageDensity: Float = 0.0     // Oscurece suavemente el verde brillante digital
    var skyHue: Float = 0.0             // Suaviza el azul eléctrico del cielo
    var splitHighWarmth: Float = 0.25   // Tiñe SOLO las luces altas de marfil/crema limpio
    var splitShadowCool: Float = 0.15   // Da profundidad neutra/fría a las sombras
    var redTrim: Float = 0.0
    var greenTrim: Float = 0.0
    var blueTrim: Float = 0.0
    var softMist: Float = 0.20          // Difusión óptica tipo filtro Black Pro-Mist
    var bloom: Float = 0.35
    var grain: Float = 0.24
    var vignette: Float = 0.15
    var nightMode: Bool = false
}

// MARK: - 2. Catálogo de 17 Cámaras (oCam Primero y por Defecto + Opción Normal Sin Filtro)
enum FilmProfile: String, CaseIterable, Identifiable {
    case ocamMaster = "oCam"
    case normalClean = "Normal"
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
        case .ocamMaster: return "BALANCED CINEMA MASTER"
        case .normalClean: return "NO FILTER • PURE SENSOR"
        case .cineChrome: return "SOFT IVORY SKY & DEEP PALMS"
        case .kodak2383: return "HOLLYWOOD PRINT FILM"
        case .nocturnaClub: return "NIGHT CLUB & NEON"
        case .portra400: return "WARM SKIN & DAYLIGHT"
        case .cinestill800T: return "TUNGSTEN CYAN HALO"
        case .dispo98: return "90s POCKET FLASH"
        case .ccd2004: return "Y2K DIGICAM"
        case .polaroid600: return "CREAMY INSTANT"
        case .superia400: return "FUJI EMERALD"
        case .velvia50: return "VIVID SLIDE CHROME"
        case .gold200: return "SUNSET VINTAGE GOLD"
        case .aerochrome: return "INFRARED CRIMSON"
        case .bleachBypass: return "SILVER RETENTION"
        case .ilfordHP5: return "DOCUMENTARY B&W"
        case .triX400: return "CLASSIC MONO 400"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .ocamMaster: return Color(red: 0.92, green: 0.84, blue: 0.70)
        case .normalClean: return Color.white
        case .cineChrome: return Color(red: 0.94, green: 0.78, blue: 0.52)
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
    
    var recommended: FilmLookParameters {
        switch self {
        case .ocamMaster:
            return FilmLookParameters(
                ev: -0.30, contrastSCurve: 0.58, curvePivot: 0.64, skyGlow: 0.30,
                shadows: 0.05, highlights: 0.25, blackCrush: 0.22, fadeMatte: 0.14,
                warmth: 0.04, tint: 0.0, saturation: -0.12, vibrance: -0.14,
                foliageHue: -0.15, foliageDensity: 0.25, skyHue: -0.15,
                splitHighWarmth: 0.28, splitShadowCool: 0.18,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.0,
                softMist: 0.22, bloom: 0.35, grain: 0.24, vignette: 0.16, nightMode: false
            )
        case .normalClean:
            return FilmLookParameters(
                ev: 0.0, contrastSCurve: 0.0, curvePivot: 0.50, skyGlow: 0.0,
                shadows: 0.0, highlights: 0.0, blackCrush: 0.0, fadeMatte: 0.0,
                warmth: 0.0, tint: 0.0, saturation: 0.0, vibrance: 0.0,
                foliageHue: 0.0, foliageDensity: 0.0, skyHue: 0.0,
                splitHighWarmth: 0.0, splitShadowCool: 0.0,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.0,
                softMist: 0.0, bloom: 0.0, grain: 0.0, vignette: 0.0, nightMode: false
            )
        case .cineChrome:
            // CALIBRACIÓN MATEMÁTICA EXACTA DE LA REFERENCIA (image_c6935c.jpg):
            // - Cielo luminoso y aireado con difusión marfil (skyGlow: 0.68, splitHighWarmth: 0.58)
            // - Casas blancas limpias (sin tinte mostaza en medios tonos: red/green/blueTrim neutros)
            // - Palmeras y pasto desaturados hacia verde bosque/oliva frío (foliageHue: -0.45, foliageDensity: 0.52, saturation: -0.26)
            // - Viñeta en 0.0 (0%) y Halation al máximo (1.0 / 100%)
            return FilmLookParameters(
                ev: -0.15, contrastSCurve: 0.66, curvePivot: 0.64, skyGlow: 0.68,
                shadows: -0.12, highlights: 0.45, blackCrush: 0.34, fadeMatte: 0.16,
                warmth: 0.08, tint: 0.02, saturation: -0.26, vibrance: -0.28,
                foliageHue: -0.45, foliageDensity: 0.52, skyHue: -0.35,
                splitHighWarmth: 0.58, splitShadowCool: 0.22,
                redTrim: 0.02, greenTrim: -0.03, blueTrim: -0.08,
                softMist: 0.48, bloom: 1.00, grain: 0.28, vignette: 0.00, nightMode: false
            )
        case .kodak2383:
            return FilmLookParameters(
                ev: -0.30, contrastSCurve: 0.74, curvePivot: 0.62, skyGlow: 0.25,
                shadows: -0.10, highlights: 0.30, blackCrush: 0.36, fadeMatte: 0.14,
                warmth: 0.04, tint: 0.0, saturation: -0.14, vibrance: -0.12,
                foliageHue: -0.25, foliageDensity: 0.35, skyHue: -0.25,
                splitHighWarmth: 0.42, splitShadowCool: 0.38,
                redTrim: 0.04, greenTrim: 0.0, blueTrim: -0.04,
                softMist: 0.25, bloom: 0.40, grain: 0.26, vignette: 0.24, nightMode: false
            )
        case .nocturnaClub:
            return FilmLookParameters(
                ev: -0.50, contrastSCurve: 0.70, curvePivot: 0.60, skyGlow: 0.20,
                shadows: 0.15, highlights: 0.40, blackCrush: 0.30, fadeMatte: 0.10,
                warmth: -0.04, tint: 0.05, saturation: -0.05, vibrance: 0.05,
                foliageHue: 0.0, foliageDensity: 0.20, skyHue: 0.10,
                splitHighWarmth: 0.35, splitShadowCool: 0.40,
                redTrim: 0.06, greenTrim: -0.04, blueTrim: 0.06,
                softMist: 0.45, bloom: 0.85, grain: 0.32, vignette: 0.30, nightMode: true
            )
        case .portra400:
            return FilmLookParameters(
                ev: -0.20, contrastSCurve: 0.50, curvePivot: 0.64, skyGlow: 0.45,
                shadows: 0.12, highlights: 0.35, blackCrush: 0.16, fadeMatte: 0.18,
                warmth: 0.10, tint: 0.03, saturation: -0.10, vibrance: -0.12,
                foliageHue: -0.20, foliageDensity: 0.28, skyHue: -0.20,
                splitHighWarmth: 0.40, splitShadowCool: 0.10,
                redTrim: 0.04, greenTrim: 0.0, blueTrim: -0.05,
                softMist: 0.30, bloom: 0.35, grain: 0.22, vignette: 0.12, nightMode: false
            )
        case .cinestill800T:
            return FilmLookParameters(
                ev: -0.40, contrastSCurve: 0.66, curvePivot: 0.60, skyGlow: 0.30,
                shadows: 0.05, highlights: 0.35, blackCrush: 0.28, fadeMatte: 0.12,
                warmth: -0.22, tint: 0.04, saturation: -0.08, vibrance: -0.05,
                foliageHue: -0.15, foliageDensity: 0.25, skyHue: 0.25,
                splitHighWarmth: 0.20, splitShadowCool: 0.55,
                redTrim: -0.05, greenTrim: 0.02, blueTrim: 0.12,
                softMist: 0.42, bloom: 0.88, grain: 0.34, vignette: 0.26, nightMode: true
            )
        case .dispo98:
            return FilmLookParameters(
                ev: -0.15, contrastSCurve: 0.68, curvePivot: 0.62, skyGlow: 0.35,
                shadows: 0.10, highlights: 0.25, blackCrush: 0.18, fadeMatte: 0.30,
                warmth: 0.04, tint: -0.08, saturation: -0.14, vibrance: -0.10,
                foliageHue: -0.10, foliageDensity: 0.20, skyHue: -0.20,
                splitHighWarmth: 0.35, splitShadowCool: 0.25,
                redTrim: 0.0, greenTrim: 0.06, blueTrim: -0.06,
                softMist: 0.35, bloom: 0.42, grain: 0.50, vignette: 0.38, nightMode: false
            )
        case .ccd2004:
            return FilmLookParameters(
                ev: -0.25, contrastSCurve: 0.64, curvePivot: 0.55, skyGlow: 0.10,
                shadows: -0.05, highlights: 0.15, blackCrush: 0.25, fadeMatte: 0.04,
                warmth: -0.04, tint: 0.02, saturation: 0.08, vibrance: 0.10,
                foliageHue: 0.0, foliageDensity: 0.0, skyHue: 0.10,
                splitHighWarmth: 0.05, splitShadowCool: 0.15,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.05,
                softMist: 0.05, bloom: 0.16, grain: 0.16, vignette: 0.18, nightMode: false
            )
        case .polaroid600:
            return FilmLookParameters(
                ev: -0.10, contrastSCurve: 0.48, curvePivot: 0.66, skyGlow: 0.55,
                shadows: 0.15, highlights: 0.40, blackCrush: 0.12, fadeMatte: 0.34,
                warmth: 0.12, tint: 0.02, saturation: -0.22, vibrance: -0.20,
                foliageHue: -0.30, foliageDensity: 0.35, skyHue: -0.30,
                splitHighWarmth: 0.52, splitShadowCool: 0.15,
                redTrim: 0.05, greenTrim: 0.0, blueTrim: -0.08,
                softMist: 0.45, bloom: 0.50, grain: 0.30, vignette: 0.32, nightMode: false
            )
        case .superia400:
            return FilmLookParameters(
                ev: -0.30, contrastSCurve: 0.64, curvePivot: 0.62, skyGlow: 0.25,
                shadows: 0.0, highlights: 0.25, blackCrush: 0.26, fadeMatte: 0.14,
                warmth: 0.0, tint: 0.06, saturation: -0.08, vibrance: -0.06,
                foliageHue: -0.35, foliageDensity: 0.30, skyHue: -0.10,
                splitHighWarmth: 0.22, splitShadowCool: 0.20,
                redTrim: 0.02, greenTrim: 0.06, blueTrim: -0.02,
                softMist: 0.20, bloom: 0.28, grain: 0.28, vignette: 0.22, nightMode: false
            )
        case .velvia50:
            return FilmLookParameters(
                ev: -0.35, contrastSCurve: 0.78, curvePivot: 0.58, skyGlow: 0.15,
                shadows: -0.15, highlights: 0.20, blackCrush: 0.40, fadeMatte: 0.05,
                warmth: 0.04, tint: 0.04, saturation: 0.16, vibrance: 0.18,
                foliageHue: -0.10, foliageDensity: 0.20, skyHue: 0.15,
                splitHighWarmth: 0.15, splitShadowCool: 0.25,
                redTrim: 0.04, greenTrim: 0.02, blueTrim: 0.04,
                softMist: 0.10, bloom: 0.22, grain: 0.16, vignette: 0.26, nightMode: false
            )
        case .gold200:
            return FilmLookParameters(
                ev: -0.25, contrastSCurve: 0.60, curvePivot: 0.64, skyGlow: 0.48,
                shadows: 0.05, highlights: 0.35, blackCrush: 0.22, fadeMatte: 0.18,
                warmth: 0.14, tint: 0.02, saturation: -0.10, vibrance: -0.10,
                foliageHue: -0.25, foliageDensity: 0.30, skyHue: -0.25,
                splitHighWarmth: 0.48, splitShadowCool: 0.10,
                redTrim: 0.06, greenTrim: 0.02, blueTrim: -0.08,
                softMist: 0.32, bloom: 0.38, grain: 0.26, vignette: 0.22, nightMode: false
            )
        case .aerochrome:
            return FilmLookParameters(
                ev: -0.30, contrastSCurve: 0.70, curvePivot: 0.60, skyGlow: 0.25,
                shadows: -0.05, highlights: 0.25, blackCrush: 0.30, fadeMatte: 0.10,
                warmth: 0.0, tint: 0.10, saturation: 0.05, vibrance: 0.05,
                foliageHue: 0.80, foliageDensity: 0.10, skyHue: -0.20,
                splitHighWarmth: 0.20, splitShadowCool: 0.20,
                redTrim: 0.20, greenTrim: -0.20, blueTrim: 0.0,
                softMist: 0.25, bloom: 0.38, grain: 0.26, vignette: 0.24, nightMode: false
            )
        case .bleachBypass:
            return FilmLookParameters(
                ev: -0.40, contrastSCurve: 0.84, curvePivot: 0.60, skyGlow: 0.20,
                shadows: -0.20, highlights: 0.30, blackCrush: 0.45, fadeMatte: 0.14,
                warmth: -0.04, tint: 0.0, saturation: -0.55, vibrance: -0.40,
                foliageHue: -0.30, foliageDensity: 0.40, skyHue: -0.20,
                splitHighWarmth: 0.25, splitShadowCool: 0.30,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: -0.04,
                softMist: 0.20, bloom: 0.20, grain: 0.44, vignette: 0.38, nightMode: false
            )
        case .ilfordHP5:
            return FilmLookParameters(
                ev: -0.25, contrastSCurve: 0.56, curvePivot: 0.62, skyGlow: 0.30,
                shadows: 0.10, highlights: 0.30, blackCrush: 0.20, fadeMatte: 0.22,
                warmth: 0.0, tint: 0.0, saturation: -1.0, vibrance: 0.0,
                foliageHue: 0.0, foliageDensity: 0.25, skyHue: 0.0,
                splitHighWarmth: 0.0, splitShadowCool: 0.0,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.0,
                softMist: 0.20, bloom: 0.24, grain: 0.46, vignette: 0.26, nightMode: false
            )
        case .triX400:
            return FilmLookParameters(
                ev: -0.35, contrastSCurve: 0.82, curvePivot: 0.60, skyGlow: 0.20,
                shadows: -0.15, highlights: 0.25, blackCrush: 0.42, fadeMatte: 0.10,
                warmth: 0.0, tint: 0.0, saturation: -1.0, vibrance: 0.0,
                foliageHue: 0.0, foliageDensity: 0.35, skyHue: 0.0,
                splitHighWarmth: 0.0, splitShadowCool: 0.0,
                redTrim: 0.0, greenTrim: 0.0, blueTrim: 0.0,
                softMist: 0.15, bloom: 0.22, grain: 0.58, vignette: 0.36, nightMode: false
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

// MARK: - 3. Motor Polinómico de Emulsión de 20 Parámetros (Fidelidad 1:1 con Palmeras de Referencia)
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
        params: FilmLookParameters,
        filterEnabled: Bool = true,
        portraitDepthBlur: Float = 0.0,
        lightLeakEnabled: Bool = false,
        anamorphicMode: Bool = false,
        isRAW: Bool,
        is48MP: Bool
    ) -> CIImage {
        var current = input
        let extent = current.extent
        guard extent.width > 0, extent.height > 0 else { return input }
        
        // Si el usuario eligió Cámara Normal o desactivó los filtros, devolver la imagen limpia del sensor
        if !filterEnabled || profile == .normalClean {
            return current
        }
        
        let scaleMultiplier = max(1.0, min(extent.width, extent.height) / 1080.0)
        
        // 1. Corrección de Exceso de Verde exclusiva para Bayer RAW
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
        
        // 2. Temperatura (WB) y Matiz (Tint)
        if abs(params.warmth) > 0.01 || abs(params.tint) > 0.01 {
            let wbFix = CIFilter.temperatureAndTint()
            wbFix.inputImage = current
            wbFix.neutral = CIVector(x: 6500, y: 0)
            let tempShift = CGFloat(-params.warmth * 950)
            let tintShift = CGFloat(params.tint * 45)
            wbFix.targetNeutral = CIVector(x: 6500 + tempShift, y: tintShift)
            if let out = wbFix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 3. Recuperación de Rango Dinámico y Brillo Aireado de Cielo (Sky Glow)
        // A diferencia de la versión anterior que oscurecía las nubes, aquí mantenemos el cielo luminoso y suave como en image_c6935c.jpg
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        let hlTarget = max(0.35, min(1.0, 0.78 - (params.highlights * 0.35) + (params.skyGlow * 0.18)))
        let shTarget = max(-0.4, min(0.8, 0.12 + (params.shadows * 0.45)))
        hs.highlightAmount = hlTarget
        hs.shadowAmount = shTarget
        hs.radius = Float(32.0 * scaleMultiplier)
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 4. SELECTOR QUÍMICO DE FOLLAJE Y CIELO (Cambia el verde lima digital a verde pino oscuro sin volver amarillo el pasto)
        if profile == .aerochrome {
            let aero = CIFilter.colorMatrix()
            aero.inputImage = current
            aero.rVector = CIVector(x: 0.45, y: 0.68, z: -0.10, w: 0)
            aero.gVector = CIVector(x: 0.22, y: 0.52, z: 0.20, w: 0)
            aero.bVector = CIVector(x: -0.05, y: 0.08, z: 0.95, w: 0)
            if let out = aero.outputImage?.cropped(to: extent) { current = out }
        } else if abs(params.foliageDensity) > 0.01 || abs(params.foliageHue) > 0.01 || abs(params.skyHue) > 0.01 || abs(params.redTrim) > 0.01 || abs(params.greenTrim) > 0.01 || abs(params.blueTrim) > 0.01 {
            // Matriz balanceada en grises: cuando R=G=B (nubes blancas y casas blancas), la suma de cada fila se mantiene limpia
            // pero cuando G > R (hojas de palmeras y pasto), atenúa el verde amarillo y lo lleva a verde pino profundo
            let folDens = CGFloat(params.foliageDensity * 0.14)
            let folCool = CGFloat(params.foliageHue * 0.10)
            let rT = CGFloat(params.redTrim * 0.18)
            let gT = CGFloat(params.greenTrim * 0.18)
            let bT = CGFloat(params.blueTrim * 0.18)
            
            let hslMatrix = CIFilter.colorMatrix()
            hslMatrix.inputImage = current
            // En las hojas verdes (G alto), restar un poco de G en el canal Rojo quita el tono amarillo-lima y da verde bosque
            hslMatrix.rVector = CIVector(x: 1.00 + folDens * 0.5 + rT, y: -folDens * 0.6 + folCool * 0.4, z: folDens * 0.1, w: 0)
            hslMatrix.gVector = CIVector(x: 0.02, y: 0.96 - folDens * 0.35 + gT, z: 0.02 + folDens * 0.35, w: 0)
            hslMatrix.bVector = CIVector(x: -0.01, y: -folCool * 0.3, z: 1.01 + folCool * 0.3 + bT, w: 0)
            hslMatrix.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            if let out = hslMatrix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 5. Desaturación Orgánica de Película (Apaga los colores chillones de iPhone como en la referencia de las palmeras)
        if abs(params.vibrance) > 0.01 {
            let vib = CIFilter.vibrance()
            vib.inputImage = current
            vib.amount = params.vibrance
            if let out = vib.outputImage?.cropped(to: extent) { current = out }
        }
        
        let cc = CIFilter.colorControls()
        cc.inputImage = current
        if profile == .ilfordHP5 {
            cc.saturation = 0.0
            cc.contrast = 0.98
        } else if profile == .triX400 {
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = current
            if let out = noir.outputImage?.cropped(to: extent) { current = out }
            cc.inputImage = current
            cc.saturation = 0.0
            cc.contrast = 1.06
        } else {
            cc.saturation = max(0.0, 1.0 + params.saturation * 0.65)
            cc.contrast = 1.02
        }
        if let out = cc.outputImage?.cropped(to: extent) { current = out }
        
        // 6. SPLIT-TONING POLINÓMICO REAL (CIColorPolynomial):
        // En lugar de teñir toda la foto de marrón/mostaza, aplica el tono marfil cálido SOLO en las altas luces (término cuadrático x^2)
        // y mantiene las sombras densas y limpias
        if (params.splitHighWarmth > 0.01 || params.splitShadowCool > 0.01) && profile != .ilfordHP5 && profile != .triX400 {
            let poly = CIFilter.colorPolynomial()
            poly.inputImage = current
            let hiWarm = CGFloat(params.splitHighWarmth)
            let shCool = CGFloat(params.splitShadowCool)
            let skyLift = CGFloat(params.skyGlow * 0.06)
            
            // Polinomio: C0 + C1*x + C2*x^2 + C3*x^3
            // Canal Rojo: sube suavemente en altas luces (x^2) para dar el cielo marfil/crema luminoso de image_c6935c.jpg
            poly.redCoefficients = CIVector(
                x: 0.004 * hiWarm,
                y: 0.96 - (0.04 * shCool),
                z: 0.06 * hiWarm + skyLift,
                w: 0.0
            )
            // Canal Verde: neutro-cálido arriba para que el cielo sea crema y no rosado
            poly.greenCoefficients = CIVector(
                x: 0.002 * hiWarm,
                y: 0.97,
                z: 0.03 * hiWarm + skyLift * 0.7,
                w: 0.0
            )
            // Canal Azul: ligeramente más fresco en sombras bajas (C0) y suave roll-off en el cielo alto (C2 negativo suave)
            poly.blueCoefficients = CIVector(
                x: 0.008 * shCool,
                y: 0.96,
                z: -0.07 * hiWarm + skyLift * 0.2,
                w: 0.0
            )
            if let out = poly.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 7. CURVA S CON PIVOTE AJUSTABLE (Pivot 0.64) + SKY GLOW AIREADO
        // Mantiene las luces altas brillantes (0.955) para que el cielo nunca salga gris oscuro como en image_c62203.jpg
        let sAmount = Double(params.contrastSCurve)
        let crush = Double(params.blackCrush)
        let matteLift = Double(params.fadeMatte) * 0.065
        let pivotShift = Double(params.curvePivot - 0.50) * 0.14
        let skyBright = Double(params.skyGlow) * 0.045
        
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        let p0 = min(0.09, 0.010 + matteLift)
        let p1 = max(p0 + 0.05, 0.22 - (sAmount * 0.065) - (crush * 0.06) + (matteLift * 0.25))
        let p2 = max(0.45, min(0.56, 0.49 + pivotShift + (skyBright * 0.4)))
        let p3 = min(0.88, 0.76 + (sAmount * 0.04) + skyBright)
        let p4 = min(0.98, 0.945 + (skyBright * 0.5)) // Cielo luminoso marfil (0.95+), nunca apagado
        
        curve.point0 = CGPoint(x: 0.00, y: p0)
        curve.point1 = CGPoint(x: 0.25, y: p1)
        curve.point2 = CGPoint(x: 0.50, y: p2)
        curve.point3 = CGPoint(x: 0.75, y: p3)
        curve.point4 = CGPoint(x: 1.00, y: p4)
        if let out = curve.outputImage?.cropped(to: extent) { current = out }
        
        // 8. Filtro Óptico Soft Mist / Halation (Crea el velo atmosférico soleado alrededor de las copas de las palmeras)
        let totalGlow = max(params.bloom, params.softMist)
        if totalGlow > 0.04 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = Float(min(28.0, (16.0 + Double(params.softMist) * 10.0) * scaleMultiplier))
            bloom.intensity = (params.bloom * 0.34) + (params.softMist * 0.18)
            if let out = bloom.outputImage?.cropped(to: extent) { current = out }
        }
        
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
        
        // 10. Viñeteado Óptico (0.0 por defecto en Palms 70s)
        if params.vignette > 0.02 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = current
            vignette.intensity = params.vignette * 1.35
            vignette.radius = 1.75
            if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 11. Light Leak y Anamórfico Opcionales
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
        
        // 12. Grano 35mm Real Escalado a los Megapíxeles
        if params.grain > 0.02, let rawNoise = CIFilter.randomGenerator().outputImage {
            let grainScale = max(1.8, min(extent.width, extent.height) / 920.0)
            let scaledNoise = rawNoise.transformed(by: CGAffineTransform(scaleX: grainScale, y: grainScale))
            let grainStrength = CGFloat(params.grain * 0.20)
            
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
    
    func encodeJPEGWithMetadata(cgImage: CGImage, originalMetadata: [String: Any]?, profileName: String) -> (data: Data?, summary: String) {
        var meta = originalMetadata ?? [:]
        meta[kCGImagePropertyOrientation as String] = 1
        
        var tiffDict = (meta[kCGImagePropertyTIFFDictionary as String] as? [String: Any]) ?? [:]
        if tiffDict[kCGImagePropertyTIFFMake as String] == nil {
            tiffDict[kCGImagePropertyTIFFMake as String] = "Apple"
        }
        if tiffDict[kCGImagePropertyTIFFModel as String] == nil {
            tiffDict[kCGImagePropertyTIFFModel as String] = UIDevice.current.model
        }
        tiffDict[kCGImagePropertyTIFFSoftware as String] = "oCam Engine - \(profileName)"
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
        params: FilmLookParameters,
        portraitDepthBlur: Float,
        lightLeakEnabled: Bool,
        anamorphicMode: Bool
    ) -> UIImage? {
        let filtered = applyCinematicLook(
            to: ciInput,
            profile: profile,
            params: params,
            filterEnabled: true,
            portraitDepthBlur: portraitDepthBlur,
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
        params: FilmLookParameters,
        filterEnabled: Bool = true,
        portraitDepthBlur: Float = 0.0,
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
            params: params,
            filterEnabled: filterEnabled,
            portraitDepthBlur: portraitDepthBlur,
            lightLeakEnabled: lightLeakEnabled,
            anamorphicMode: anamorphicMode,
            isRAW: usedCIRAW,
            is48MP: is48MP
        )
        
        guard let cgImage = ciContext.createCGImage(processed, from: processed.extent) else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: nil, status: "ERROR GPU", exifSummary: "")
        }
        
        var uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        if filterEnabled && (aspectRatio != .fourThree || frameStyle != .none || dateStampEnabled) {
            uiImage = applyFinalTouches(
                to: uiImage,
                aspectRatio: aspectRatio,
                frameStyle: frameStyle,
                dateStampEnabled: dateStampEnabled
            )
        }
        
        let finalCG = uiImage.cgImage ?? cgImage
        let encoded = encodeJPEGWithMetadata(
            cgImage: finalCG,
            originalMetadata: extractedMeta,
            profileName: filterEnabled ? profile.rawValue : "Normal Clean"
        )
        let finalData = encoded.data ?? uiImage.jpegData(compressionQuality: 0.96)
        
        let w = finalCG.width
        let h = finalCG.height
        let mp = max(1, Int(round((Double(w) * Double(h)) / 1_000_000.0)))
        let statusText = usedCIRAW ? "RAW \(mp)MP" : "\(mp)MP"
        return DevelopedPhotoResult(jpegData: finalData, previewImage: uiImage, status: statusText, exifSummary: encoded.summary)
    }
}

// MARK: - 4. Controlador de Hardware oCam (Abre en oCam por defecto + Modo DUAL Normal+Filtro)
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
    
    // NUEVAS OPCIONES PEDIDAS:
    var filtersEnabled = true          // Permite desactivar todos los filtros y usar Cámara Normal
    var dualCaptureEnabled = false     // Guarda 2 fotos de un solo disparo: 1 Normal sin filtro + 1 con Filtro
    
    var doubleExposureEnabled = false
    var showHorizonAndHistogram = false
    var horizonAngleDegrees: Double = 0.0
    var statusMessage = "48MP PRO"
    var lastExifSummary = "1/125s | f/1.6 | ISO 64"
    var currentZoom: CGFloat = 1.0
    
    // oCam va PRIMERO y abierto por defecto al iniciar la app
    var selectedProfile: FilmProfile = .ocamMaster
    var params: FilmLookParameters = FilmProfile.ocamMaster.recommended
    
    var portraitDepthBlur: Float = 0.0
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
        filtersEnabled = (profile != .normalClean)
        applyRecommendedForCurrentProfile()
    }
    
    func applyRecommendedForCurrentProfile() {
        params = selectedProfile.recommended
        setExposure(params.ev)
        updateNightModeHardware()
    }
    
    func resetToNeutral() {
        params = FilmProfile.normalClean.recommended
        portraitDepthBlur = 0.0
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
        
        applyExposureInternal(params.ev)
        updateStatusBadge()
    }
    
    func updateNightModeHardware() {
        let isNight = params.nightMode
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
        let targetEV = params.ev
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            self.session.beginConfiguration()
            self.configureSensorFormat(for: device, prefer48MP: want48)
            self.session.commitConfiguration()
            self.applyExposureInternal(targetEV)
            self.updateStatusBadge()
        }
    }
    
    func updateStatusBadge() {
        let hasRAW = !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
        DispatchQueue.main.async {
            self.isRAWActive = hasRAW
            if !self.filtersEnabled || self.selectedProfile == .normalClean {
                self.statusMessage = "NORMAL SIN FILTRO"
            } else if self.dualCaptureEnabled {
                self.statusMessage = "DUAL (NORMAL + FILTRO)"
            } else if self.doubleExposureEnabled {
                self.statusMessage = self.doubleExposureFirstShot == nil ? "2X EXP: TOMA 1/2" : "2X EXP: TOMA 2/2"
            } else if self.params.nightMode {
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
        params.ev = ev
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
        let targetEV = params.ev
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
        let isNight = self.params.nightMode
        statusMessage = dualCaptureEnabled ? "GUARDANDO DUAL..." : (want48MP ? "48MP..." : (wantRAW ? "RAW..." : "REVELANDO..."))
        
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
        let currentParams = self.params
        let filterOn = self.filtersEnabled
        let saveDual = self.dualCaptureEnabled
        let portrait = self.portraitDepthBlur
        let leak = self.lightLeakEnabled
        let anamorphic = self.anamorphicMode
        let stamp = self.dateStampEnabled
        let ratio = self.aspectRatio
        let frame = self.frameStyle
        let angle = self.physicalOrientation
        let isDoubleExp = self.doubleExposureEnabled
        let firstShot = self.doubleExposureFirstShot
        
        Task.detached(priority: .userInitiated) {
            // 1. Si está activo DUAL SHOT (y los filtros están activos), revelar también la foto 100% Normal sin filtro
            var cleanJPEGData: Data? = nil
            if saveDual && filterOn && profile != .normalClean {
                let cleanResult = CinematicPipeline.shared.developFinalPhoto(
                    data: data,
                    rawMetadata: photoMeta,
                    wasCapturedAsRAW: wasRAW,
                    wbTemp: measuredTemp,
                    wbTint: measuredTint,
                    profile: .normalClean,
                    params: FilmProfile.normalClean.recommended,
                    filterEnabled: false,
                    deviceOrientation: angle
                )
                cleanJPEGData = cleanResult.jpegData
            }
            
            // 2. Revelar la foto con la estética seleccionada (o Normal si filtersEnabled == false)
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                rawMetadata: photoMeta,
                wasCapturedAsRAW: wasRAW,
                wbTemp: measuredTemp,
                wbTint: measuredTint,
                profile: profile,
                params: currentParams,
                filterEnabled: filterOn,
                portraitDepthBlur: portrait,
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
            
            // Guardar en Fototeca (Si Dual Shot está activo, guarda primero la Normal y enseguida la Filtrada)
            if let jpegData = finalDataToSave {
                PHPhotoLibrary.shared().performChanges({
                    if let cleanData = cleanJPEGData {
                        let cleanReq = PHAssetCreationRequest.forAsset()
                        cleanReq.addResource(with: .photo, data: cleanData, options: nil)
                    }
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                }, completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        if success {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            if saveDual && cleanJPEGData != nil {
                                self.statusMessage = "DUAL (2 FOTOS) OK"
                            } else {
                                self.statusMessage = isDoubleExp ? "2X EXP OK" : result.status
                            }
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

// MARK: - 5. Visor Óptico de Alta Precisión
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

// MARK: - 6. Capa de Previsualización Fiel en Vivo
struct LiveOpticalEffectsView: View {
    let profile: FilmProfile
    let params: FilmLookParameters
    let filterEnabled: Bool
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
            if filterEnabled && profile != .normalClean {
                ZStack {
                    filmLiveOverlay(for: profile)
                    
                    // Brillo suave de cielo marfil (Sky Glow + Split High Warmth)
                    if params.skyGlow > 0.05 || params.splitHighWarmth > 0.05 {
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.96, blue: 0.86).opacity(Double(params.skyGlow * 0.16 + params.splitHighWarmth * 0.12)),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .blendMode(.screen)
                    }
                    
                    if params.fadeMatte > 0.02 {
                        Color(white: 0.14)
                            .opacity(Double(params.fadeMatte) * 0.20)
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
                    
                    if abs(params.warmth) > 0.02 {
                        (params.warmth > 0
                            ? Color(red: 1.0, green: 0.80, blue: 0.48)
                            : Color(red: 0.35, green: 0.75, blue: 1.0))
                            .opacity(Double(abs(params.warmth)) * 0.14)
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
                    
                    if params.bloom > 0.04 || params.softMist > 0.04 {
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.96, blue: 0.88).opacity(Double(max(params.bloom, params.softMist)) * 0.15),
                                profile.badgeColor.opacity(Double(params.bloom) * 0.08),
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
                    
                    if params.vignette > 0.01 {
                        RadialGradient(
                            colors: [
                                .clear,
                                Color.black.opacity(Double(params.vignette) * 0.38),
                                Color.black.opacity(min(0.88, Double(params.vignette) * 0.85))
                            ],
                            center: .center,
                            startRadius: min(geo.size.width, geo.size.height) * CGFloat(0.48 - Double(params.vignette) * 0.15),
                            endRadius: max(geo.size.width, geo.size.height) * 0.72
                        )
                    }
                    
                    if params.grain > 0.02 {
                        TimelineView(.periodic(from: .now, by: 0.09)) { timeline in
                            Canvas { context, size in
                                let seed = Int(timeline.date.timeIntervalSinceReferenceDate * 14)
                                let count = Int(420 * params.grain)
                                var rng = SeededRandomGenerator(seed: UInt64(abs(seed) + 1))
                                for _ in 0..<count {
                                    let x = CGFloat.random(in: 0..<size.width, using: &rng)
                                    let y = CGFloat.random(in: 0..<size.height, using: &rng)
                                    let isBright = Bool.random(using: &rng)
                                    let rect = CGRect(x: x, y: y, width: 1.8, height: 1.8)
                                    context.fill(
                                        Path(ellipseIn: rect),
                                        with: .color((isBright ? Color.white : Color.black).opacity(Double(params.grain) * 0.28))
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
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func filmLiveOverlay(for profile: FilmProfile) -> some View {
        switch profile {
        case .cineChrome:
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.84).opacity(0.14),
                    Color(red: 0.10, green: 0.24, blue: 0.20).opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .ocamMaster, .kodak2383:
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.86).opacity(0.08),
                    Color(red: 0.08, green: 0.18, blue: 0.22).opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        case .aerochrome:
            Color(red: 0.95, green: 0.20, blue: 0.45).opacity(0.16).blendMode(.softLight)
        case .cinestill800T:
            Color(red: 0.20, green: 0.65, blue: 0.95).opacity(0.10).blendMode(.softLight)
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

// MARK: - 7. Laboratorio oCam Studio con los 20 Controles en 5 Pestañas
struct GalleryDarkroomView: View {
    let originalData: Data
    var onSaveSuccess: (UIImage, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfile: FilmProfile = .cineChrome
    @State private var params: FilmLookParameters = FilmProfile.cineChrome.recommended
    @State private var activeTab: Int = 0 // 0: Tone, 1: Split & Sky, 2: HSL & RGB, 3: Optics, 4: Crop
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
                            params = selectedProfile.recommended
                            updatePreview()
                        }
                        Button("Sin Filtro (Cámara Normal)", systemImage: "camera") {
                            selectedProfile = .normalClean
                            params = FilmProfile.normalClean.recommended
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
                        Text("Sky Glow \(Int(params.skyGlow * 100))% | Pivot \(String(format: "%.2f", params.curvePivot))")
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
                
                // Carrusel de Cámaras siempre accesible en Studio
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilmProfile.allCases) { profile in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedProfile = profile
                                params = profile.recommended
                                updatePreview()
                            } label: {
                                Text(profile.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundStyle(selectedProfile == profile ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedProfile == profile ? profile.badgeColor : Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Panel de 20 Controles organizados en 5 Pestañas
                VStack(spacing: 7) {
                    if activeTab == 0 {
                        darkroomSlider(title: "Exposure (EV)", value: $params.ev, range: -1.5...1.5, format: "%+.2f")
                        darkroomSlider(title: "Sky Glow (Airy Clouds)", value: $params.skyGlow, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "S-Curve Contrast", value: $params.contrastSCurve, range: 0.0...1.0, format: "%.2f", multiplier: 4.0)
                        darkroomSlider(title: "Curve Pivot", value: $params.curvePivot, range: 0.35...0.75, format: "%.2f")
                        darkroomSlider(title: "Black Crush / Matte", value: $params.blackCrush, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                    } else if activeTab == 1 {
                        darkroomSlider(title: "Ivory Sky (Split High)", value: $params.splitHighWarmth, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Cool Shadows (Split Low)", value: $params.splitShadowCool, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Shadows Lift / Deep", value: $params.shadows, range: -0.6...0.6, format: "%+.2f")
                        darkroomSlider(title: "Highlights Roll-Off", value: $params.highlights, range: -0.5...1.0, format: "%+.2f")
                        darkroomSlider(title: "Matte Fade Lift", value: $params.fadeMatte, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                    } else if activeTab == 2 {
                        darkroomSlider(title: "Foliage Hue (Pine Green)", value: $params.foliageHue, range: -1.0...1.0, format: "%+.2f")
                        darkroomSlider(title: "Foliage Density (Dark)", value: $params.foliageDensity, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Saturation (Organic)", value: $params.saturation, range: -1.0...0.5, format: "%+.2f")
                        darkroomSlider(title: "Warmth (WB)", value: $params.warmth, range: -1.0...1.0, format: "%+.2f")
                        darkroomSlider(title: "Blue Trim (Sky)", value: $params.blueTrim, range: -0.5...0.5, format: "%+.2f")
                    } else if activeTab == 3 {
                        darkroomSlider(title: "Halation Glow", value: $params.bloom, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Soft Mist Diffusion", value: $params.softMist, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "35mm Film Grain", value: $params.grain, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                        darkroomSlider(title: "Optical Vignette", value: $params.vignette, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.15), lineWidth: 0.7))
                .padding(.horizontal, 14)
                
                HStack(spacing: 8) {
                    studioTabButton(index: 0, icon: "chart.xyaxis.line", title: "Tone")
                    studioTabButton(index: 1, icon: "sun.max", title: "Split")
                    studioTabButton(index: 2, icon: "leaf", title: "HSL")
                    studioTabButton(index: 3, icon: "sparkles", title: "Optics")
                    studioTabButton(index: 4, icon: "crop", title: "Crop")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
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
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 9.5, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(activeTab == index ? selectedProfile.badgeColor : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(activeTab == index ? Color.white.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func darkroomSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String, multiplier: Float = 1.0) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 125, alignment: .leading)
            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { newVal in
                    value.wrappedValue = newVal
                    updatePreview()
                }
            ), in: range)
            .tint(selectedProfile.badgeColor)
            Text(String(format: format, value.wrappedValue * multiplier))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(selectedProfile.badgeColor)
                .frame(width: 44, alignment: .trailing)
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
        let currentParams = params
        let port = portraitDepthBlur
        let leak = lightLeakEnabled
        let stamp = dateStampEnabled
        let ratio = aspectRatio
        let frame = frameStyle
        
        Task.detached(priority: .userInitiated) {
            guard var img = CinematicPipeline.shared.renderPreviewUIImage(
                from: baseCI,
                profile: prof,
                params: currentParams,
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
        let currentParams = params
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
                params: currentParams,
                filterEnabled: prof != .normalClean,
                portraitDepthBlur: port,
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

// MARK: - 8. Interfaz Principal oCam (Con Botón DUAL y Opción Sin Filtro)
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
    @State private var activeDrawerTab: Int = 0 // 0: Tone, 1: Split, 2: HSL, 3: Optics, 4: Format
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
        !camera.filtersEnabled || camera.dualCaptureEnabled || camera.timerSeconds > 0 || camera.params.nightMode || camera.portraitDepthBlur > 0.05 || camera.doubleExposureEnabled || camera.dateStampEnabled || camera.lightLeakEnabled
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
        HStack(spacing: 8) {
            Button {
                camera.toggleSensorMode()
            } label: {
                Text(modeButtonTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(camera.useRAWCapture || camera.use48MPMode ? camera.selectedProfile.badgeColor : Color.white.opacity(0.15))
                    .foregroundStyle(camera.useRAWCapture || camera.use48MPMode ? .black : .white)
                    .clipShape(Capsule())
            }
            
            // Botón Rápido DUAL (Guarda foto Normal sin filtro + foto con Filtro de un solo disparo)
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                camera.dualCaptureEnabled.toggle()
                camera.updateStatusBadge()
            } label: {
                Text("DUAL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(camera.dualCaptureEnabled ? Color.yellow : Color.white.opacity(0.12))
                    .foregroundStyle(camera.dualCaptureEnabled ? .black : .white.opacity(0.85))
                    .clipShape(Capsule())
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                camera.flashEnabled.toggle()
            } label: {
                Image(systemName: camera.flashEnabled ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(camera.flashEnabled ? .yellow : .white.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
                    .rotationEffect(.degrees(camera.uiRotationDegrees))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: camera.uiRotationDegrees)
            }
            
            Spacer(minLength: 2)
            
            HStack(spacing: 5) {
                Text("oCam")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
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
            
            Spacer(minLength: 2)
            
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
                    .frame(width: 32, height: 32)
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
                    .frame(width: 32, height: 32)
                    .background(showTray ? camera.selectedProfile.badgeColor : Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.6))
        .padding(.horizontal, 14)
    }
    
    private var extraFeaturesMenu: some View {
        Menu {
            // Nuevas funciones de Filtro ON/OFF y Captura Dual
            Button(camera.filtersEnabled ? "Desactivar Filtros (Cámara Normal)" : "Activar Filtros de Cámara") {
                camera.filtersEnabled.toggle()
                camera.updateStatusBadge()
            }
            
            Button(camera.dualCaptureEnabled ? "Captura Dual (Normal + Filtro): ON" : "Activar Captura Dual (Normal + Filtro)") {
                camera.dualCaptureEnabled.toggle()
                camera.updateStatusBadge()
            }
            
            Divider()
            
            Button("Temporizador: OFF") { camera.timerSeconds = 0 }
            Button("Temporizador: 3s") { camera.timerSeconds = 3 }
            Button("Temporizador: 10s") { camera.timerSeconds = 10 }
            
            Divider()
            
            Button(camera.params.nightMode ? "Modo Noche: ON" : "Activar Modo Noche") {
                camera.params.nightMode.toggle()
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
                .frame(width: 32, height: 32)
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
                    .contrast(!camera.filtersEnabled || camera.selectedProfile == .normalClean ? 1.0 : (1.02 + Double(camera.params.contrastSCurve) * 0.14))
                    .saturation(!camera.filtersEnabled || camera.selectedProfile == .normalClean ? 1.0 : max(0.0, 1.0 + Double(camera.params.saturation) * 0.60))
                    
                    LiveOpticalEffectsView(
                        profile: camera.selectedProfile,
                        params: camera.params,
                        filterEnabled: camera.filtersEnabled,
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
                        Text("\(camera.filtersEnabled ? camera.selectedProfile.rawValue : "Normal") • \(camera.statusMessage)")
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
                                get: { camera.params.ev },
                                set: { camera.setExposure($0) }
                            ), in: -2.0...1.5)
                            .tint(camera.selectedProfile.badgeColor)
                            Text(String(format: "%+.1f EV", camera.params.ev))
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
    
    // Cajón de 20 Controles en Vivo (5 Pestañas compactas en 1 sola línea)
    private var controlsDrawerView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                trayTabPill(index: 0, title: "Tone")
                trayTabPill(index: 1, title: "Split")
                trayTabPill(index: 2, title: "HSL")
                trayTabPill(index: 3, title: "Optics")
                trayTabPill(index: 4, title: "Crop")
                
                Spacer(minLength: 2)
                
                Menu {
                    Button("Recomendado (\(camera.selectedProfile.rawValue))", systemImage: "sparkles") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        camera.applyRecommendedForCurrentProfile()
                    }
                    Button("Por defecto (Sin Filtro)", systemImage: "arrow.counterclockwise") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        camera.resetToNeutral()
                    }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(7)
                        .background(camera.selectedProfile.badgeColor)
                        .clipShape(Circle())
                }
            }
            
            if activeDrawerTab == 0 {
                glassSliderRow(title: "EXPOSICIÓN", value: Binding(
                    get: { camera.params.ev },
                    set: { camera.setExposure($0) }
                ), range: -2.0...1.5, text: String(format: "%+.1f EV", camera.params.ev))
                
                glassSliderRow(title: "SKY GLOW", value: $camera.params.skyGlow, range: 0.0...1.0, text: "\(Int(camera.params.skyGlow * 100))%")
                
                glassSliderRow(title: "S-CURVE", value: $camera.params.contrastSCurve, range: 0.0...1.0, text: String(format: "%.2f", camera.params.contrastSCurve * 4.0))
                
                glassSliderRow(title: "PIVOT", value: $camera.params.curvePivot, range: 0.35...0.75, text: String(format: "%.2f", camera.params.curvePivot))
            } else if activeDrawerTab == 1 {
                glassSliderRow(title: "IVORY SKY", value: $camera.params.splitHighWarmth, range: 0.0...1.0, text: "\(Int(camera.params.splitHighWarmth * 100))%")
                
                glassSliderRow(title: "COOL SHAD", value: $camera.params.splitShadowCool, range: 0.0...1.0, text: "\(Int(camera.params.splitShadowCool * 100))%")
                
                glassSliderRow(title: "BLACK CRUSH", value: $camera.params.blackCrush, range: 0.0...1.0, text: "\(Int(camera.params.blackCrush * 100))%")
                
                glassSliderRow(title: "MATTE FADE", value: $camera.params.fadeMatte, range: 0.0...1.0, text: "\(Int(camera.params.fadeMatte * 100))%")
            } else if activeDrawerTab == 2 {
                glassSliderRow(title: "PINE HUE", value: $camera.params.foliageHue, range: -1.0...1.0, text: String(format: "%+.2f", camera.params.foliageHue))
                
                glassSliderRow(title: "PINE DARK", value: $camera.params.foliageDensity, range: 0.0...1.0, text: "\(Int(camera.params.foliageDensity * 100))%")
                
                glassSliderRow(title: "SATURACIÓN", value: $camera.params.saturation, range: -1.0...0.5, text: String(format: "%+.2f", camera.params.saturation))
                
                glassSliderRow(title: "TEMP (WB)", value: $camera.params.warmth, range: -1.0...1.0, text: String(format: "%+.2f", camera.params.warmth))
            } else if activeDrawerTab == 3 {
                glassSliderRow(title: "HALATION", value: $camera.params.bloom, range: 0.0...1.0, text: "\(Int(camera.params.bloom * 100))%")
                
                glassSliderRow(title: "SOFT MIST", value: $camera.params.softMist, range: 0.0...1.0, text: "\(Int(camera.params.softMist * 100))%")
                
                glassSliderRow(title: "GRANO 35MM", value: $camera.params.grain, range: 0.0...1.0, text: "\(Int(camera.params.grain * 100))%")
                
                glassSliderRow(title: "VIÑETEADO", value: $camera.params.vignette, range: 0.0...1.0, text: "\(Int(camera.params.vignette * 100))%")
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
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(activeDrawerTab == index ? .black : .white.opacity(0.85))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(activeDrawerTab == index ? Color.white : Color.white.opacity(0.12))
                .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func glassSliderRow(title: String, value: Binding<Float>, range: ClosedRange<Float>, text: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 72, alignment: .leading)
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
}
// FIN DEL ARCHIVO
