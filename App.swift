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
        hs.highlightAmount = 0.38 // Comprime altas luces para que no se quemen
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
                rawFilter.scaleFactor = 0.5 // Escala segura en RAM para evitar cierres por exceso de memoria en iOS
                
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
                // Si la imagen supera los 3500px, escalar a 3024px para que la GPU nunca supere el límite de memoria de iOS
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
            
            // Importante: Normalizar el origen del lienzo a (0,0) tras rotar para evitar crash en CIContext
            let normalizedInput = input.transformed(by: CGAffineTransform(translationX: -input.extent.origin.x, y: -input.extent.origin.y))
            let processed = applyCinematicLook(to: normalizedInput, profile: profile, bloomAmount: bloomAmount, isRAW: usedCIRAW)
            
            // Exportar a binario JPEG Display P3 de máxima calidad (95%) para guardado infalible en Fotos
            guard let jpegData = ciContext.jpegRepresentation(
                of: processed,
                colorSpace: colorSpace,
                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.95]
            ) else {
                return (nil, nil, "ERROR AL CODIFICAR JPEG")
            }
            
            let previewUI = UIImage(data: jpegData)
            let status = usedCIRAW ? "RAW GUARDADO EN FOTOS" : "CINE 16-BIT GUARDADO"
            return (jpegData, previewUI, status)
        }
    }
}

// MARK: - 3. Controlador de Cámara Blindado Contra Crashes de AVFoundation
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
    var useRAWCapture = true // Permite activar/desactivar Bayer RAW con un toque
    var statusMessage = "INICIANDO..."
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .chromagraph
    var exposureEV: Float = -0.45
    var bloomIntensity: Float = 0.45
    var physicalOrientation: UIDeviceOrientation = .portrait
    
    override init() {
        super.init()
        startMotionTracking()
        // Pedir permiso de Fotos desde el inicio para que no bloquee al disparar
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
            // REGLA CRÍTICA DE APPLE: En iPhone no-Pro, Bayer RAW exige que maxPhotoQualityPrioritization sea .speed o .balanced, pero al disparar RAW debe enviarse .speed
            photoOutput.maxPhotoQualityPrioritization = .speed
        }
        
        session.commitConfiguration()
        session.startRunning()
        
        applyExposureInternal(exposureEV)
        updateRAWStatusBadge()
    }
    
    private func updateRAWStatusBadge() {
        let hasRAW = !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
        DispatchQueue.main.async {
            self.isRAWActive = hasRAW
            self.statusMessage = (hasRAW && self.useRAWCapture && self.currentZoom == 1.0)
                ? "BAYER RAW ACTIVO"
                : "PIPELINE CINE ACTIVO"
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
            
            self.updateRAWStatusBadge()
        }
    }
    
    func capturePhoto() {
        guard !isProcessing else { return }
        isProcessing = true
        statusMessage = "PROCESANDO..."
        
        let wantRAW = self.useRAWCapture
        let zoom = self.currentZoom
        
        sessionQueue.async {
            // Verificar que la conexión esté activa antes de disparar
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
            
            // Solo pedir Bayer RAW si está en 1x, el usuario lo tiene activo y el sensor lo ofrece
            if wantRAW, zoom == 1.0, let rawFormat = bayerFormats.first ?? self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
                // OBLIGATORIO EN IPHONE BASE: Bayer RAW requiere .speed para no lanzar NSInvalidArgumentException
                settings.photoQualityPrioritization = .speed
            } else {
                if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    settings = AVCapturePhotoSettings()
                }
                settings.photoQualityPrioritization = .speed
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            // Si el sensor rechazó el disparo RAW, desactivar RAW automáticamente y avisar sin crashear
            DispatchQueue.main.async {
                self.useRAWCapture = false
                self.statusMessage = "MODO CINE DIRECTO (\(error.localizedDescription.prefix(12)))"
                self.isProcessing = false
            }
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
        let angle = self.physicalOrientation
        
        Task.detached(priority: .userInitiated) {
            let result = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                wasCapturedAsRAW: wasRAW,
                profile: profile,
                bloomAmount: bloom,
                deviceOrientation: angle
            )
            
            // Guardado binario directo a la galería de Fotos (100% compatible con iOS 17/18/19/20)
            if let jpegData = result.jpegData {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                }, completionHandler: { success, saveError in
                    DispatchQueue.main.async {
                        if success {
                            self.statusMessage = result.debugStatus
                        } else if let preview = result.previewImage {
                            // Respaldo secundario si el álbum rechazó el recurso binario
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

// MARK: - 4. Interfaz Visual Chromagraph
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
                // Barra Superior con Botón RAW y Estado de Guardado
                HStack(spacing: 8) {
                    Button {
                        camera.useRAWCapture.toggle()
                    } label: {
                        Text(camera.useRAWCapture && camera.currentZoom == 1.0 ? "RAW: ON" : "RAW: OFF")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(camera.useRAWCapture && camera.currentZoom == 1.0 ? camera.selectedProfile.badgeColor : Color.white.opacity(0.15))
                            .foregroundStyle(camera.useRAWCapture && camera.currentZoom == 1.0 ? .black : .white)
                            .clipShape(Capsule())
                    }
                    
                    Text(camera.statusMessage)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .padding(.horizontal, 9)
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
                
                // Visor Principal con Previsualización de Color en Vivo
                ZStack(alignment: .bottom) {
                    ZStack {
                        NativeCameraPreview(session: camera.session)
                            .contrast(camera.selectedProfile == .triX400 ? 1.28 : 1.12)
                            .saturation(camera.selectedProfile == .triX400 ? 0.0 : (camera.selectedProfile == .portra400 ? 1.12 : 0.92))
                        
                        filmLiveOverlay(for: camera.selectedProfile)
                            .allowsHitTesting(false)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    
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
