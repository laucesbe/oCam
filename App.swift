import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMotion
import Photos
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

// MARK: - 2. Motor de Revelado RAW Cinematográfico (Seguro en Memoria GPU)
class CinematicPipeline {
    static let shared = CinematicPipeline()
    
    let ciContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        .workingFormat: CIFormat.RGBAh,
        .cacheIntermediates: false
    ])
    
    func applyCinematicLook(to input: CIImage, profile: FilmProfile, bloomAmount: Float, isRAW: Bool) -> CIImage {
        var current = input
        let extent = current.extent
        guard extent.width > 0, extent.height > 0 else { return input }
        
        // 1. Compresión suave de Altas Luces (Highlight Roll-off) y apertura de sombras
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        hs.highlightAmount = 0.40 // Comprime altas luces para evitar quemados
        hs.shadowAmount = isRAW ? 0.35 : 0.24
        if let out = hs.outputImage { current = out }
        
        // 2. Curva en S y Matrices Químicas de Color
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        switch profile {
        case .chromagraph:
            curve.point0 = CGPoint(x: 0.00, y: 0.04)
            curve.point1 = CGPoint(x: 0.22, y: 0.16)
            curve.point2 = CGPoint(x: 0.50, y: 0.52)
            curve.point3 = CGPoint(x: 0.78, y: 0.81)
            curve.point4 = CGPoint(x: 1.00, y: 0.91)
            if let out = curve.outputImage { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.08, y: 0.02, z: -0.02, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 1.02, z: 0.01, w: 0)
            matrix.bVector = CIVector(x: -0.04, y: 0.02, z: 0.92, w: 0)
            matrix.biasVector = CIVector(x: -0.01, y: 0.00, z: 0.015, w: 0)
            if let out = matrix.outputImage { current = out }
            
        case .portra400:
            curve.point0 = CGPoint(x: 0.00, y: 0.06)
            curve.point1 = CGPoint(x: 0.25, y: 0.22)
            curve.point2 = CGPoint(x: 0.50, y: 0.55)
            curve.point3 = CGPoint(x: 0.75, y: 0.82)
            curve.point4 = CGPoint(x: 1.00, y: 0.93)
            if let out = curve.outputImage { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 1.14, y: 0.03, z: -0.03, w: 0)
            matrix.gVector = CIVector(x: 0.02, y: 1.03, z: -0.02, w: 0)
            matrix.bVector = CIVector(x: -0.05, y: -0.02, z: 0.88, w: 0)
            matrix.biasVector = CIVector(x: 0.01, y: 0.005, z: -0.01, w: 0)
            if let out = matrix.outputImage { current = out }
            
        case .cinestill800T:
            curve.point0 = CGPoint(x: 0.00, y: 0.03)
            curve.point1 = CGPoint(x: 0.25, y: 0.15)
            curve.point2 = CGPoint(x: 0.50, y: 0.48)
            curve.point3 = CGPoint(x: 0.75, y: 0.81)
            curve.point4 = CGPoint(x: 1.00, y: 0.94)
            if let out = curve.outputImage { current = out }
            
            let matrix = CIFilter.colorMatrix()
            matrix.inputImage = current
            matrix.rVector = CIVector(x: 0.92, y: 0.02, z: 0.00, w: 0)
            matrix.gVector = CIVector(x: 0.00, y: 1.04, z: 0.04, w: 0)
            matrix.bVector = CIVector(x: -0.02, y: 0.06, z: 1.15, w: 0)
            matrix.biasVector = CIVector(x: -0.015, y: 0.01, z: 0.025, w: 0)
            if let out = matrix.outputImage { current = out }
            
        case .triX400:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = current
            if let out = noir.outputImage { current = out }
            
            curve.inputImage = current
            curve.point0 = CGPoint(x: 0.00, y: 0.03)
            curve.point1 = CGPoint(x: 0.25, y: 0.16)
            curve.point2 = CGPoint(x: 0.50, y: 0.50)
            curve.point3 = CGPoint(x: 0.75, y: 0.84)
            curve.point4 = CGPoint(x: 1.00, y: 0.95)
            if let out = curve.outputImage { current = out }
        }
        
        // 3. Halation / Bloom seguro en memoria (Radio acotado a 14px máx para evitar crash por RAM)
        if bloomAmount > 0.05 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current.clampedToExtent()
            bloom.radius = 12.0
            bloom.intensity = bloomAmount * 0.55
            if let out = bloom.outputImage?.cropped(to: extent) {
                current = out
            }
        }
        
        // 4. Viñeteado suave de lente fijo
        let vignette = CIFilter.vignette()
        vignette.inputImage = current
        vignette.intensity = 0.40
        vignette.radius = 1.6
        if let out = vignette.outputImage { current = out }
        
        // 5. Grano orgánico de 35mm
        if let noise = CIFilter.randomGenerator().outputImage {
            let grainIntensity: CGFloat = isRAW ? 0.030 : 0.022
            let monoNoise = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: grainIntensity)
            ]).cropped(to: extent)
            current = monoNoise.composited(over: current)
        }
        
        return current.cropped(to: extent)
    }
    
    func developFinalPhoto(
        data: Data,
        wasCapturedAsRAW: Bool,
        profile: FilmProfile,
        bloomAmount: Float,
        deviceOrientation: UIDeviceOrientation
    ) -> (image: UIImage?, debugStatus: String) {
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
            
            // 1. Revelar con CIRAWFilter si viene en DNG/Bayer RAW directo del sensor
            if wasCapturedAsRAW, let rawFilter = CIRAWFilter(imageData: data, identifierHint: "com.adobe.raw-image") ?? CIRAWFilter(imageData: data, identifierHint: nil) {
                // Desactivar todo el procesado artificial de Apple (Smart HDR / Deep Fusion sharpening)
                rawFilter.luminanceNoiseReductionAmount = 0.72
                rawFilter.colorNoiseReductionAmount = 0.88
                rawFilter.sharpnessAmount = 0.08 // Sin bordes duros digitales
                rawFilter.localToneMapAmount = 0.0 // Cero efecto HDR falso
                rawFilter.boostAmount = 0.30 // Respuesta logarítmica de cine
                rawFilter.baselineExposure = 0.25
                
                // Si el sensor dispara en 48MP, escalar a 12MP (4032px) para no desbordar la RAM de iOS
                rawFilter.scaleFactor = 1.0
                if var rawOut = rawFilter.outputImage {
                    if max(rawOut.extent.width, rawOut.extent.height) > 4200 {
                        rawFilter.scaleFactor = 0.5
                        rawOut = rawFilter.outputImage ?? rawOut
                    }
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
            
            // 2. Respaldo por si se usó el lente 0.5x o zoom 2x (donde Apple no entrega Bayer RAW)
            if baseImage == nil, var std = CIImage(data: data, options: [.applyOrientationProperty: true]) {
                if std.extent.width > std.extent.height && !deviceOrientation.isLandscape {
                    std = std.oriented(.right)
                }
                baseImage = std
            }
            
            guard let input = baseImage else {
                return (nil, "ERROR AL DECODIFICAR IMAGEN")
            }
            
            let processed = applyCinematicLook(to: input, profile: profile, bloomAmount: bloomAmount, isRAW: usedCIRAW)
            guard let cgImage = ciContext.createCGImage(processed, from: processed.extent) else {
                return (nil, "ERROR DE MEMORIA GPU")
            }
            
            let finalUIImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            let w = Int(processed.extent.width)
            let h = Int(processed.extent.height)
            let statusText = usedCIRAW
                ? "RAW REAL REVELADO (\(w)x\(h))"
                : "PIPELINE CINE 16-BIT (\(w)x\(h))"
            
            return (finalUIImage, statusText)
        }
    }
}

// MARK: - 3. Controlador de Cámara Thread-Safe + Habilitación Real de Bayer RAW
@Observable
class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.chromacam.sessionQueue")
    private let motionManager = CMMotionManager()
    
    private var currentDevice: AVCaptureDevice?
    private var lastExposureUpdate: Date = .distantPast
    
    var capturedImage: UIImage?
    var isProcessing = false
    var isRAWActive = false
    var statusMessage = "INICIANDO SENSOR..."
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .chromagraph
    var exposureEV: Float = -0.45
    var bloomIntensity: Float = 0.45
    var physicalOrientation: UIDeviceOrientation = .portrait
    
    override init() {
        super.init()
        startMotionTracking()
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
    
    private func configureSession() {
        session.beginConfiguration()
        // CLAVE: Usar .photo sin VideoDataOutput permite que el iPhone 17 base active Bayer RAW al 100%
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
            // En iPhone 17 base, .balanced permite simultáneamente Bayer RAW sin crashear AVFoundation
            photoOutput.maxPhotoQualityPrioritization = .balanced
            if photoOutput.isAppleProRAWSupported {
                photoOutput.isAppleProRAWEnabled = true
            }
        }
        
        session.commitConfiguration()
        session.startRunning()
        
        applyExposureInternal(exposureEV)
        updateRAWStatusBadge()
    }
    
    private func updateRAWStatusBadge() {
        let rawFormats = photoOutput.availableRawPhotoPixelFormatTypes
        let hasRAW = !rawFormats.isEmpty
        DispatchQueue.main.async {
            self.isRAWActive = hasRAW
            self.statusMessage = hasRAW ? "SENSOR BAYER RAW ACTIVO" : "MODO LENTE SECUNDARIO (HEIC 16-BIT)"
        }
    }
    
    func setExposure(_ ev: Float) {
        exposureEV = ev
        // Throttling de 50ms para que deslizar el dedo rápido jamás bloquee ni crashee el hilo de cámara
        let now = Date()
        guard now.timeIntervalSince(lastExposureUpdate) > 0.05 else { return }
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
        currentZoom = factor
        let targetEV = exposureEV
        
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            
            // NOTA TÉCNICA: Apple solo soporta Bayer RAW en el lente 1x (builtInWideAngleCamera) sin zoom digital.
            let targetType: AVCaptureDevice.DeviceType = (factor == 0.5) ? .builtInUltraWideCamera : .builtInWideAngleCamera
            if let newDevice = AVCaptureDevice.default(targetType, for: .video, position: .back),
               let newInput = try? AVCaptureDeviceInput(device: newDevice) {
                self.currentDevice = newDevice
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                }
            }
            
            self.session.commitConfiguration()
            
            if let device = self.currentDevice {
                do {
                    try device.lockForConfiguration()
                    // Si es 2x, aplicamos recorte óptico; si es 1x dejamos zoom 1.0 para que RAW permanezca activo
                    let zoom = (factor > 1.0) ? factor : 1.0
                    device.videoZoomFactor = min(zoom, device.maxAvailableVideoZoomFactor)
                    let clampedEV = max(device.minExposureTargetBias, min(targetEV, device.maxExposureTargetBias))
                    device.setExposureTargetBias(clampedEV, completionHandler: nil)
                    device.unlockForConfiguration()
                } catch {}
            }
            
            self.updateRAWStatusBadge()
        }
    }
    
    func capturePhoto() {
        guard !isProcessing else { return }
        isProcessing = true
        statusMessage = "CAPTURANDO DEL SENSOR..."
        
        let currentAngle = self.physicalOrientation
        
        sessionQueue.async {
            let settings: AVCapturePhotoSettings
            
            // CRÍTICO: En iOS, Bayer RAW solo es válido cuando el zoom es 1.0x. Si el usuario puso 2x, Apple lanza excepción si pides RAW.
            let canCaptureRAWNow = (self.currentZoom == 1.0) && !self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
            
            if canCaptureRAWNow, let rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
                // Para evitar el crash de AVFoundation, respetamos el maxPhotoQualityPrioritization actual
                settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
            } else {
                settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
            }
            
            if let photoConnection = self.photoOutput.connection(with: .video) {
                switch currentAngle {
                case .landscapeLeft: photoConnection.videoRotationAngle = 0
                case .landscapeRight: photoConnection.videoRotationAngle = 180
                case .portraitUpsideDown: photoConnection.videoRotationAngle = 270
                default: photoConnection.videoRotationAngle = 90
                }
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR CAPTURA: \(error.localizedDescription)"
                self.isProcessing = false
            }
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.statusMessage = "SIN DATOS DE SENSOR"
                self.isProcessing = false
            }
            return
        }
        
        let wasRAW = photo.isRawPhoto
        let profile = self.selectedProfile
        let bloom = self.bloomIntensity
        let angle = self.physicalOrientation
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                wasCapturedAsRAW: wasRAW,
                profile: profile,
                bloomAmount: bloom,
                deviceOrientation: angle
            )
            
            if let finalImg = result.image {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    guard status == .authorized || status == .limited else { return }
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: finalImg)
                    }, completionHandler: nil)
                }
            }
            
            await MainActor.run {
                self.capturedImage = result.image
                self.statusMessage = result.debugStatus
                self.isProcessing = false
            }
        }
    }
}

// MARK: - 4. Visor Nativo Fluido + Overlay de Previsualización de Película en Tiempo Real
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

struct ContentView: View {
    @State private var camera = CameraManager()
    @State private var showControls = false
    @State private var showFullPreview = false
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Barra Superior con Telemetría Real de Sensor RAW
                HStack(spacing: 8) {
                    Text(camera.selectedProfile.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(camera.selectedProfile.badgeColor.opacity(0.22))
                        .foregroundStyle(camera.selectedProfile.badgeColor)
                        .clipShape(Capsule())
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(camera.isRAWActive && camera.currentZoom == 1.0 ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(camera.statusMessage)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .foregroundStyle(.white.opacity(0.9))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring) { showControls.toggle() }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(showControls ? camera.selectedProfile.badgeColor : .white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                
                // Visor Principal con Emulación de Película en Tiempo Real y Cero Consumo de RAM
                ZStack(alignment: .bottom) {
                    ZStack {
                        NativeCameraPreview(session: camera.session)
                            .contrast(camera.selectedProfile == .triX400 ? 1.28 : 1.12)
                            .saturation(camera.selectedProfile == .triX400 ? 0.0 : (camera.selectedProfile == .portra400 ? 1.12 : 0.92))
                        
                        // Tinte óptico en vivo según película seleccionada para ver el look antes de disparar
                        filmLiveOverlay(for: camera.selectedProfile)
                            .allowsHitTesting(false)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    
                    // Controles Inferiores
                    VStack(spacing: 12) {
                        if showControls {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("LUCES (EV)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .frame(width: 75, alignment: .leading)
                                    Slider(value: Binding(
                                        get: { camera.exposureEV },
                                        set: { camera.setExposure($0) }
                                    ), in: -2.0...1.0)
                                    .tint(camera.selectedProfile.badgeColor)
                                    Text(String(format: "%+.1f", camera.exposureEV))
                                        .font(.system(size: 10, design: .monospaced))
                                        .frame(width: 34)
                                }
                                HStack {
                                    Text("HALATION")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .frame(width: 75, alignment: .leading)
                                    Slider(value: $camera.bloomIntensity, in: 0.0...1.0)
                                        .tint(camera.selectedProfile.badgeColor)
                                    Text("\(Int(camera.bloomIntensity * 100))%")
                                        .font(.system(size: 10, design: .monospaced))
                                        .frame(width: 34)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.78))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                        }
                        
                        // Selector de Película
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FilmProfile.allCases) { profile in
                                    Button {
                                        camera.selectedProfile = profile
                                    } label: {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(profile.badgeColor)
                                                .frame(width: 10, height: 10)
                                            Text(profile.rawValue)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundStyle(camera.selectedProfile == profile ? .black : .white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(camera.selectedProfile == profile ? profile.badgeColor : Color.black.opacity(0.7))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Selector de Lentes (Nota: 1x mantiene el puntito verde de RAW encendido)
                        HStack(spacing: 10) {
                            ForEach(zoomLevels, id: \.self) { level in
                                Button {
                                    camera.switchCameraLens(factor: level)
                                } label: {
                                    Text(level == 0.5 ? "0.5x" : "\(Int(level))x")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(camera.currentZoom == level ? .black : .white)
                                        .frame(width: 40, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(camera.currentZoom == level ? camera.selectedProfile.badgeColor : Color.black.opacity(0.65))
                                        )
                                }
                            }
                        }
                        
                        // Barra de Disparo y Visor de Última Foto
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
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.4), lineWidth: 1))
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                camera.capturePhoto()
                            } label: {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .frame(width: 72, height: 72)
                                    Circle()
                                        .fill(camera.isProcessing ? camera.selectedProfile.badgeColor : Color.white)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .disabled(camera.isProcessing)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 48, height: 48)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
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
                .opacity(0.12)
                .blendMode(.overlay)
        case .cinestill800T:
            Color(red: 0.15, green: 0.65, blue: 0.95)
                .opacity(0.14)
                .blendMode(.colorBurn)
        case .triX400:
            Color.clear
        }
    }
}
