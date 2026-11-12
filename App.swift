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

// MARK: - 1. Catálogo de 8 Películas Cinematográficas Profesionales
enum FilmProfile: String, CaseIterable, Identifiable {
    case chromagraph = "Chroma"
    case portra400 = "Portra 400"
    case cinestill800T = "800T"
    case velvia50 = "Velvia 50"
    case gold200 = "Gold 200"
    case ektachrome = "E100"
    case bleachBypass = "Bleach"
    case triX400 = "Tri-X B&W"
    
    var id: String { self.rawValue }
    
    var subtitle: String {
        switch self {
        case .chromagraph: return "CINE PIPELINE"
        case .portra400: return "WARM SKIN & DAYLIGHT"
        case .cinestill800T: return "TUNGSTEN NIGHT"
        case .velvia50: return "VIVID LANDSCAPE"
        case .gold200: return "VINTAGE GOLDEN"
        case .ektachrome: return "CLEAN SLIDE FILM"
        case .bleachBypass: return "SILVER RETENTION"
        case .triX400: return "CLASSIC MONOCHROME"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .chromagraph: return Color(red: 0.90, green: 0.74, blue: 0.45)
        case .portra400: return Color(red: 0.95, green: 0.58, blue: 0.35)
        case .cinestill800T: return Color(red: 0.32, green: 0.78, blue: 0.94)
        case .velvia50: return Color(red: 0.35, green: 0.88, blue: 0.52)
        case .gold200: return Color(red: 0.98, green: 0.82, blue: 0.28)
        case .ektachrome: return Color(red: 0.55, green: 0.72, blue: 0.98)
        case .bleachBypass: return Color(red: 0.72, green: 0.78, blue: 0.80)
        case .triX400: return Color(white: 0.88)
        }
    }
}

struct DevelopedPhotoResult {
    let jpegData: Data?
    let previewImage: UIImage?
    let status: String
}

// MARK: - 2. Motor de Revelado Cinematográfico (Soporte 48MP Real + 12MP RAW + Galería)
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
        exposureAdjust: Float = 0.0,
        isRAW: Bool,
        is48MP: Bool
    ) -> CIImage {
        var current = input
        let extent = current.extent
        guard extent.width > 0, extent.height > 0 else { return input }
        
        // 0. Ajuste de exposición adicional (útil en editor de galería)
        if abs(exposureAdjust) > 0.02 {
            let exp = CIFilter.exposureAdjust()
            exp.inputImage = current
            exp.ev = exposureAdjust
            if let out = exp.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 1. Neutralizar dominante verde de matriz Bayer RGGB en RAW
        if isRAW {
            let wbFix = CIFilter.temperatureAndTint()
            wbFix.inputImage = current
            wbFix.neutral = CIVector(x: 6200, y: 0)
            wbFix.targetNeutral = CIVector(x: 5750, y: 20)
            if let out = wbFix.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 2. Compresión suave de Altas Luces (Highlight Roll-off)
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        hs.highlightAmount = isRAW ? 0.25 : 0.36
        hs.shadowAmount = isRAW ? 0.42 : 0.25
        if let out = hs.outputImage?.cropped(to: extent) { current = out }
        
        // 3. Curvas de Cine y Matrices Químicas de Color
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
        
        // 4. Halation / Bloom (En 12MP o previsualización para cuidar la RAM en 48MP)
        if !is48MP && bloomAmount > 0.05 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = 11.0
            bloom.intensity = bloomAmount * 0.45
            if let out = bloom.outputImage?.cropped(to: extent) {
                current = out
            }
        }
        
        // 5. Viñeteado óptico regulable
        if vignetteAmount > 0.02 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = current
            vignette.intensity = vignetteAmount * 0.85
            vignette.radius = 1.75
            if let out = vignette.outputImage?.cropped(to: extent) { current = out }
        }
        
        // 6. Grano orgánico de 35mm regulable
        if grainAmount > 0.02, let noise = CIFilter.randomGenerator().outputImage {
            let grainAlpha = CGFloat(grainAmount * 0.045)
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
    
    func renderPreviewUIImage(
        from ciInput: CIImage,
        profile: FilmProfile,
        bloomAmount: Float,
        grainAmount: Float,
        vignetteAmount: Float,
        exposureAdjust: Float
    ) -> UIImage? {
        let filtered = applyCinematicLook(
            to: ciInput,
            profile: profile,
            bloomAmount: bloomAmount,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            exposureAdjust: exposureAdjust,
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
        exposureAdjust: Float = 0.0,
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
            exposureAdjust: exposureAdjust,
            isRAW: usedCIRAW,
            is48MP: is48MP
        )
        
        guard let cgImage = ciContext.createCGImage(processed, from: processed.extent) else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: nil, status: "ERROR RENDER GPU")
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.96) else {
            return DevelopedPhotoResult(jpegData: nil, previewImage: uiImage, status: "ERROR JPEG")
        }
        
        let w = Int(processed.extent.width)
        let h = Int(processed.extent.height)
        let mp = Int(round((Double(w) * Double(h)) / 1_000_000.0))
        let statusText = usedCIRAW ? "RAW \(mp)MP (\(w)x\(h))" : "CINE \(mp)MP (\(w)x\(h))"
        return DevelopedPhotoResult(jpegData: jpegData, previewImage: uiImage, status: statusText)
    }
}

// MARK: - 3. Controlador de Cámara con Desbloqueo Real de 48MP (.inputPriority + .quality)
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
    var exposureEV: Float = -0.40
    var bloomIntensity: Float = 0.38
    var grainIntensity: Float = 0.35
    var vignetteIntensity: Float = 0.30
    var showGrid = true
    var timerSeconds: Int = 0
    var countdownRemaining: Int = 0
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
    
    /// Desbloquea el formato de 48MP usando .inputPriority para que iOS no lo fuerce a 12MP
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
                // Preferir formato 4:3 de foto completa (8064x6048) con binned video
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
                // CLAVE PARA 48MP REALES: Cambiar el preset de la sesión a .inputPriority antes de fijar activeFormat
                if self.session.canSetSessionPreset(.inputPriority) {
                    self.session.sessionPreset = .inputPriority
                }
                try device.lockForConfiguration()
                device.activeFormat = format48
                device.unlockForConfiguration()
                
                self.photoOutput.maxPhotoDimensions = d48
                // Los 48MP requieren Deep Fusion (.quality) habilitado en el photoOutput
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
        
        // Reconfigurar photoOutput según el modo elegido (48MP necesita .quality, 12MP RAW necesita .speed)
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
                // Bayer RAW en modelos no-Pro exige .speed y 12MP
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
                    // CLAVE: Para que el sensor entregue 8064x6048 reales, usar .quality (o el máximo permitido por el output)
                    self.photoOutput.maxPhotoDimensions = d48
                    settings.maxPhotoDimensions = d48
                    settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
                } else {
                    self.photoOutput.maxPhotoDimensions = self.max12MPDimension
                    settings.maxPhotoDimensions = self.max12MPDimension
                    settings.photoQualityPrioritization = .balanced
                }
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
        let angle = self.physicalOrientation
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                wasCapturedAsRAW: wasRAW,
                profile: profile,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vignette,
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

// MARK: - 4. Laboratorio de Revelado para Imágenes de la Galería (Darkroom)
struct GalleryDarkroomView: View {
    let originalData: Data
    var onSaveSuccess: (UIImage, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProfile: FilmProfile = .chromagraph
    @State private var exposureAdjust: Float = 0.0
    @State private var bloomAmount: Float = 0.35
    @State private var grainAmount: Float = 0.35
    @State private var vignetteAmount: Float = 0.30
    @State private var previewImage: UIImage?
    @State private var scaledCIImage: CIImage?
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 14) {
                // Barra superior del Laboratorio
                HStack {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("DARKROOM LAB")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(selectedProfile.subtitle)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(selectedProfile.badgeColor)
                    }
                    
                    Spacer()
                    
                    Button {
                        saveDevelopedGalleryPhoto()
                    } label: {
                        Text(isSaving ? "..." : "Guardar")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedProfile.badgeColor)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Visor de foto importada
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(white: 0.07))
                    
                    if let preview = previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(8)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 14)
                
                // Controles de ajuste fino
                VStack(spacing: 10) {
                    darkroomSlider(title: "EXPOSICIÓN", value: $exposureAdjust, range: -1.5...1.5, format: "%+.1f EV")
                    darkroomSlider(title: "HALATION", value: $bloomAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                    darkroomSlider(title: "GRANO 35MM", value: $grainAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                    darkroomSlider(title: "VIÑETEADO", value: $vignetteAmount, range: 0.0...1.0, format: "%.0f%%", multiplier: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)
                
                // Selector de las 8 películas
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(FilmProfile.allCases) { profile in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedProfile = profile
                                updatePreview()
                            } label: {
                                VStack(spacing: 4) {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(profile.badgeColor)
                                            .frame(width: 8, height: 8)
                                        Text(profile.rawValue)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    }
                                    Text(profile.subtitle.prefix(12))
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
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
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            prepareScaledPreviewInput()
        }
    }
    
    @ViewBuilder
    private func darkroomSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String, multiplier: Float = 1.0) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 82, alignment: .leading)
            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { newVal in
                    value.wrappedValue = newVal
                    updatePreview()
                }
            ), in: range)
            .tint(selectedProfile.badgeColor)
            Text(String(format: format, value.wrappedValue * multiplier))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 48, alignment: .trailing)
        }
    }
    
    private func prepareScaledPreviewInput() {
        Task.detached(priority: .userInitiated) {
            guard var ci = CIImage(data: originalData, options: [.applyOrientationProperty: true]) else { return }
            ci = ci.transformed(by: CGAffineTransform(translationX: -ci.extent.origin.x, y: -ci.extent.origin.y))
            let maxDim = max(ci.extent.width, ci.extent.height)
            if maxDim > 1400 {
                let scale = 1400.0 / maxDim
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
        let exp = exposureAdjust
        
        Task.detached(priority: .userInteractive) {
            let img = CinematicPipeline.shared.renderPreviewUIImage(
                from: baseCI,
                profile: prof,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                exposureAdjust: exp
            )
            await MainActor.run {
                self.previewImage = img
            }
        }
    }
    
    private func saveDevelopedGalleryPhoto() {
        isSaving = true
        let prof = selectedProfile
        let bloom = bloomAmount
        let grain = grainAmount
        let vig = vignetteAmount
        let exp = exposureAdjust
        let rawData = originalData
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: rawData,
                wasCapturedAsRAW: true,
                profile: prof,
                bloomAmount: bloom,
                grainAmount: grain,
                vignetteAmount: vig,
                exposureAdjust: exp,
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
                    onSaveSuccess(img, "REVELADA: \(result.status)")
                }
                dismiss()
            }
        }
    }
}

// MARK: - 5. Interfaz Principal Chromagraph Pro
struct NativeCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
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
            
            VStack(spacing: 10) {
                // Barra Superior Estilo Telemetría de Cine
                HStack(spacing: 8) {
                    Button {
                        camera.toggleSensorMode()
                    } label: {
                        HStack(spacing: 5) {
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
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.11))
                        .foregroundStyle(.white.opacity(0.9))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Botón de Temporizador (Off / 3s)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.timerSeconds = (camera.timerSeconds == 0) ? 3 : 0
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.system(size: 13, weight: .semibold))
                            if camera.timerSeconds > 0 {
                                Text("3s")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                        }
                        .foregroundStyle(camera.timerSeconds > 0 ? camera.selectedProfile.badgeColor : .white.opacity(0.8))
                        .padding(7)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    // Botón de Cuadrícula (Grid)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        camera.showGrid.toggle()
                    } label: {
                        Image(systemName: "squareshape.split.3x3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(camera.showGrid ? camera.selectedProfile.badgeColor : .white.opacity(0.8))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Botón de Ajustes Químicos
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring) { showControls.toggle() }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(showControls ? camera.selectedProfile.badgeColor : .white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14)
                
                // Visor Principal con Emulación en Tiempo Real y Cuadrícula
                ZStack(alignment: .bottom) {
                    ZStack {
                        NativeCameraPreview(session: camera.session)
                            .contrast(camera.selectedProfile == .triX400 ? 1.28 : (camera.selectedProfile == .bleachBypass ? 1.22 : 1.10))
                            .saturation(liveSaturation(for: camera.selectedProfile))
                        
                        filmLiveOverlay(for: camera.selectedProfile)
                            .allowsHitTesting(false)
                        
                        if camera.showGrid {
                            GridOverlayView()
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
                    VStack(spacing: 12) {
                        if showControls {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("LUCES (EV)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .frame(width: 78, alignment: .leading)
                                    Slider(value: Binding(
                                        get: { camera.exposureEV },
                                        set: { camera.setExposure($0) }
                                    ), in: -2.0...1.0)
                                    .tint(camera.selectedProfile.badgeColor)
                                    Text(String(format: "%+.1f", camera.exposureEV))
                                        .font(.system(size: 10, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("HALATION")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .frame(width: 78, alignment: .leading)
                                    Slider(value: $camera.bloomIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.bloomIntensity * 100))%")
                                        .font(.system(size: 10, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("GRANO 35MM")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .frame(width: 78, alignment: .leading)
                                    Slider(value: $camera.grainIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.grainIntensity * 100))%")
                                        .font(.system(size: 10, design: .monospaced))
                                        .frame(width: 36)
                                }
                                HStack {
                                    Text("VIÑETEADO")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .frame(width: 78, alignment: .leading)
                                    Slider(value: $camera.vignetteIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.vignetteIntensity * 100))%")
                                        .font(.system(size: 10, design: .monospaced))
                                        .frame(width: 36)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 18)
                        }
                        
                        // Carrusel de 8 Películas con Subtítulo Técnico
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
                            .padding(.horizontal, 18)
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
                        
                        // Barra Inferior: Última Foto | Obturador | Importar de Galería (Darkroom)
                        HStack {
                            // Miniatura de última foto revelada
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
                            
                            // Botón de Obturador Cinematográfico
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
                            
                            // Botón para Importar Foto de la Galería y Revelarla
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
                        .padding(.bottom, 16)
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
        .fullScreenCover(isPresented: $showDarkroom) {
            if let data = importedPhotoData {
                GalleryDarkroomView(originalData: data) { savedImg, msg in
                    camera.capturedImage = savedImg
                    camera.statusMessage = msg
                }
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
    
    private func liveSaturation(for profile: FilmProfile) -> Double {
        switch profile {
        case .triX400: return 0.0
        case .bleachBypass: return 0.45
        case .velvia50: return 1.30
        case .portra400, .gold200: return 1.12
        default: return 0.94
        }
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
            Color(red: 1.0, green: 0.68, blue: 0.35)
                .opacity(0.11)
                .blendMode(.overlay)
        case .cinestill800T:
            Color(red: 0.15, green: 0.65, blue: 0.95)
                .opacity(0.13)
                .blendMode(.colorBurn)
        case .velvia50:
            Color(red: 0.15, green: 0.85, blue: 0.45)
                .opacity(0.07)
                .blendMode(.softLight)
        case .gold200:
            Color(red: 1.0, green: 0.80, blue: 0.20)
                .opacity(0.14)
                .blendMode(.softLight)
        case .ektachrome:
            Color(red: 0.35, green: 0.65, blue: 1.0)
                .opacity(0.09)
                .blendMode(.softLight)
        case .bleachBypass, .triX400:
            Color.clear
        }
    }
}
// FIN DEL ARCHIVO
