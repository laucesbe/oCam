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

// MARK: - 2. Tubería de Color + Corrección Física de Orientación
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
        
        // 1. Compresión suave de Altas Luces (Highlight Roll-off)
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = current
        hs.highlightAmount = 0.42
        hs.shadowAmount = isRAW ? 0.32 : 0.24
        if let out = hs.outputImage { current = out }
        
        // 2. Curvas y Matrices de Película
        let curve = CIFilter.toneCurve()
        curve.inputImage = current
        
        switch profile {
        case .chromagraph:
            curve.point0 = CGPoint(x: 0.00, y: 0.04)
            curve.point1 = CGPoint(x: 0.22, y: 0.16)
            curve.point2 = CGPoint(x: 0.50, y: 0.52)
            curve.point3 = CGPoint(x: 0.78, y: 0.80)
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
        
        // 3. Halation / Bloom en altas luces
        if bloomAmount > 0.05 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = current
            bloom.radius = Float(min(extent.width, extent.height) * 0.025)
            bloom.intensity = bloomAmount * 0.65
            if let out = bloom.outputImage?.cropped(to: extent) {
                current = out
            }
        }
        
        // 4. Viñeteado suave
        let vignette = CIFilter.vignette()
        vignette.inputImage = current
        vignette.intensity = 0.45
        vignette.radius = 1.6
        if let out = vignette.outputImage { current = out }
        
        // 5. Grano de 35mm
        if let noise = CIFilter.randomGenerator().outputImage {
            let grainIntensity: CGFloat = isRAW ? 0.032 : 0.024
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
    
    /// Revela la foto y rota físicamente los píxeles según el ángulo real del iPhone al disparar
    func developFinalPhoto(data: Data, profile: FilmProfile, bloomAmount: Float, deviceOrientation: UIDeviceOrientation) -> UIImage? {
        var baseImage: CIImage?
        var isRAW = false
        
        // Mapear el ángulo físico del iPhone a orientación EXIF estándar para rotar el sensor nativo
        let targetExifOrientation: CGImagePropertyOrientation
        switch deviceOrientation {
        case .landscapeLeft:
            targetExifOrientation = .up        // Teléfono inclinado a la izquierda (cámara arriba)
        case .landscapeRight:
            targetExifOrientation = .down      // Teléfono inclinado a la derecha
        case .portraitUpsideDown:
            targetExifOrientation = .left      // Vertical cabeza abajo
        default:
            targetExifOrientation = .right     // Vertical normal (90° sentido horario)
        }
        
        if let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
            rawFilter.luminanceNoiseReductionAmount = 0.75
            rawFilter.colorNoiseReductionAmount = 0.90
            rawFilter.sharpnessAmount = 0.05
            rawFilter.localToneMapAmount = 0.0
            rawFilter.boostAmount = 0.35
            rawFilter.baselineExposure = 0.20
            
            // Si el RAW viene acostado de fábrica (ancho > alto), le aplicamos la rotación física de los píxeles
            if var rawOut = rawFilter.outputImage {
                if rawOut.extent.width > rawOut.extent.height {
                    rawOut = rawOut.oriented(targetExifOrientation)
                } else if deviceOrientation == .landscapeLeft {
                    rawOut = rawOut.oriented(.left)
                } else if deviceOrientation == .landscapeRight {
                    rawOut = rawOut.oriented(.right)
                }
                baseImage = rawOut
            }
            isRAW = true
        } else if var std = CIImage(data: data, options: [.applyOrientationProperty: true]) {
            if std.extent.width > std.extent.height && (deviceOrientation == .portrait || !deviceOrientation.isLandscape) {
                std = std.oriented(.right)
            }
            baseImage = std
        }
        
        guard let input = baseImage else { return nil }
        let processed = applyCinematicLook(to: input, profile: profile, bloomAmount: bloomAmount, isRAW: isRAW)
        
        // Al haber rotado los píxeles en CIImage, creamos un UIImage ya derecho (.up) que nunca se voltea en la galería
        guard let cgImage = ciContext.createCGImage(processed, from: processed.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}

// MARK: - 3. Controlador de Cámara + Sensor de Ángulo (Acelerómetro CoreMotion)
@Observable
class CameraManager: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "com.chromacam.videoQueue", qos: .userInteractive)
    private let motionManager = CMMotionManager()
    
    private var currentDevice: AVCaptureDevice?
    
    var livePreviewImage: CGImage?
    var capturedImage: UIImage?
    var isProcessing = false
    var isRAWActive = false
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .chromagraph
    var exposureEV: Float = -0.5
    var bloomIntensity: Float = 0.55
    var physicalOrientation: UIDeviceOrientation = .portrait
    
    override init() {
        super.init()
        startMotionTracking()
        configureSession()
    }
    
    /// Lee el acelerómetro real del iPhone (funciona incluso con el bloqueo de rotación activado)
    private func startMotionTracking() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.2
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
        if session.canAddInput(input) { session.addInput(input) }
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            if let connection = videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
            }
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
            isRAWActive = !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
        }
        
        session.commitConfiguration()
        setExposure(exposureEV)
        Task.detached { self.session.startRunning() }
    }
    
    func setExposure(_ ev: Float) {
        exposureEV = ev
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(ev, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {}
    }
    
    func switchCameraLens(factor: CGFloat) {
        currentZoom = factor
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        
        let targetType: AVCaptureDevice.DeviceType = (factor == 0.5) ? .builtInUltraWideCamera : .builtInWideAngleCamera
        if let newDevice = AVCaptureDevice.default(targetType, for: .video, position: .back),
           let newInput = try? AVCaptureDeviceInput(device: newDevice) {
            currentDevice = newDevice
            if session.canAddInput(newInput) { session.addInput(newInput) }
        }
        
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
        }
        
        session.commitConfiguration()
        isRAWActive = !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
        
        if let device = currentDevice {
            do {
                try device.lockForConfiguration()
                let zoom = (factor >= 1.0) ? factor : 1.0
                device.videoZoomFactor = min(zoom, device.maxAvailableVideoZoomFactor)
                device.setExposureTargetBias(exposureEV, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {}
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Garantizar que el visor siempre esté en vertical aunque el driver entregue el buffer acostado
        if ciImage.extent.width > ciImage.extent.height {
            ciImage = ciImage.oriented(.right)
        }
        
        let filtered = CinematicPipeline.shared.applyCinematicLook(
            to: ciImage,
            profile: selectedProfile,
            bloomAmount: bloomIntensity,
            isRAW: false
        )
        if let cgImg = CinematicPipeline.shared.ciContext.createCGImage(filtered, from: filtered.extent) {
            DispatchQueue.main.async {
                self.livePreviewImage = cgImg
            }
        }
    }
    
    func capturePhoto() {
        isProcessing = true
        let settings: AVCapturePhotoSettings
        
        if let bayerRAW = photoOutput.availableRawPhotoPixelFormatTypes.first {
            settings = AVCapturePhotoSettings(rawPixelFormatType: bayerRAW)
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        // Informar también a la conexión de captura el ángulo actual del teléfono
        if let photoConnection = photoOutput.connection(with: .video) {
            switch physicalOrientation {
            case .landscapeLeft: photoConnection.videoRotationAngle = 0
            case .landscapeRight: photoConnection.videoRotationAngle = 180
            case .portraitUpsideDown: photoConnection.videoRotationAngle = 270
            default: photoConnection.videoRotationAngle = 90
            }
        }
        
        settings.photoQualityPrioritization = .quality
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            isProcessing = false
            return
        }
        let profile = self.selectedProfile
        let bloom = self.bloomIntensity
        let currentAngle = self.physicalOrientation
        
        Task.detached(priority: .userInitiated) {
            let finalImage = CinematicPipeline.shared.developFinalPhoto(
                data: data,
                profile: profile,
                bloomAmount: bloom,
                deviceOrientation: currentAngle
            )
            if let img = finalImage {
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            }
            await MainActor.run {
                self.capturedImage = finalImage
                self.isProcessing = false
            }
        }
    }
}

// MARK: - 4. Interfaz Visual Chromagraph
struct ContentView: View {
    @State private var camera = CameraManager()
    @State private var showControls = false
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text(camera.selectedProfile.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(camera.selectedProfile.badgeColor.opacity(0.22))
                        .foregroundStyle(camera.selectedProfile.badgeColor)
                        .clipShape(Capsule())
                    
                    Text(camera.isRAWActive ? "BAYER RAW 14-BIT" : "CINE PIPELINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .foregroundStyle(.white.opacity(0.85))
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
                .padding(.horizontal, 20)
                
                ZStack(alignment: .bottom) {
                    GeometryReader { geo in
                        if let cgImage = camera.livePreviewImage {
                            Image(decorative: cgImage, scale: 1.0, orientation: .up)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Color(white: 0.06)
                        }
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
                            .background(Color.black.opacity(0.75))
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
                        }
                        
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
                        
                        HStack {
                            if let lastPhoto = camera.capturedImage {
                                Image(uiImage: lastPhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 48, height: 48)
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
    }
}
