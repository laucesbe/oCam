import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
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

// MARK: - 1. Perfiles de Película
enum FilmProfile: String, CaseIterable, Identifiable {
    case chromagraph = "Chroma"
    case portra400 = "Portra 400"
    case cinestill800T = "800T"
    case triX400 = "Tri-X B&W"
    
    var id: String { self.rawValue }
    
    var badgeColor: Color {
        switch self {
        case .chromagraph: return Color(red: 0.85, green: 0.72, blue: 0.48)
        case .portra400: return Color(red: 0.92, green: 0.58, blue: 0.35)
        case .cinestill800T: return Color(red: 0.35, green: 0.75, blue: 0.88)
        case .triX400: return Color(white: 0.75)
        }
    }
}

// MARK: - 2. Motor de Revelado RAW (Emulación Bayer RAW + Highlight Roll-off)
class CinematicPipeline {
    static let shared = CinematicPipeline()
    private let ciContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        .workingFormat: CIFormat.RGBAh
    ])
    
    func developPhoto(data: Data, profile: FilmProfile) -> UIImage? {
        var image: CIImage?
        
        // Si el sensor entregó Bayer RAW puro, desactivar nitidez artificial de Apple
        if let rawFilter = CIRAWFilter(imageData: data, identifierHint: nil) {
            rawFilter.luminanceNoiseReductionAmount = 0.70 // Sombras ultra limpias ("Low Noise")
            rawFilter.colorNoiseReductionAmount = 0.85
            rawFilter.sharpnessAmount = 0.12 // Cero bordes digitales falsos
            rawFilter.localToneMapAmount = 0.20 // Evita el look HDR plástico
            rawFilter.baselineExposure = 0.15 // Compensa la subexposición protectora de luces
            image = rawFilter.outputImage
        } else {
            image = CIImage(data: data)
        }
        
        guard var currentImage = image else { return nil }
        
        // Recuperación de altas luces (Better Highlights) y apertura de sombras
        let highlightShadow = CIFilter.highlightShadowAdjust()
        highlightShadow.inputImage = currentImage
        highlightShadow.highlightAmount = 0.55 // Comprime luces altas como película de cine
        highlightShadow.shadowAmount = 0.22    // Levanta sombras limpias
        if let hsOutput = highlightShadow.outputImage { currentImage = hsOutput }
        
        // Curva Tonal Cinematográfica
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = currentImage
        
        switch profile {
        case .chromagraph:
            toneCurve.point0 = CGPoint(x: 0.00, y: 0.02)
            toneCurve.point1 = CGPoint(x: 0.25, y: 0.20)
            toneCurve.point2 = CGPoint(x: 0.50, y: 0.50)
            toneCurve.point3 = CGPoint(x: 0.75, y: 0.78)
            toneCurve.point4 = CGPoint(x: 1.00, y: 0.94)
            if let out = toneCurve.outputImage { currentImage = out }
            currentImage = applyTempTint(to: currentImage, temp: 6100, tint: -5)
            
        case .portra400:
            toneCurve.point0 = CGPoint(x: 0.00, y: 0.04)
            toneCurve.point1 = CGPoint(x: 0.25, y: 0.23)
            toneCurve.point2 = CGPoint(x: 0.50, y: 0.53)
            toneCurve.point3 = CGPoint(x: 0.75, y: 0.80)
            toneCurve.point4 = CGPoint(x: 1.00, y: 0.96)
            if let out = toneCurve.outputImage { currentImage = out }
            currentImage = applyTempTint(to: currentImage, temp: 5600, tint: 8)
            
        case .cinestill800T:
            toneCurve.point0 = CGPoint(x: 0.00, y: 0.01)
            toneCurve.point1 = CGPoint(x: 0.25, y: 0.18)
            toneCurve.point2 = CGPoint(x: 0.50, y: 0.49)
            toneCurve.point3 = CGPoint(x: 0.75, y: 0.79)
            toneCurve.point4 = CGPoint(x: 1.00, y: 0.95)
            if let out = toneCurve.outputImage { currentImage = out }
            currentImage = applyTempTint(to: currentImage, temp: 7600, tint: -12)
            
        case .triX400:
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = currentImage
            if let monoOut = mono.outputImage { currentImage = monoOut }
            
            toneCurve.inputImage = currentImage
            toneCurve.point0 = CGPoint(x: 0.00, y: 0.01)
            toneCurve.point1 = CGPoint(x: 0.25, y: 0.17)
            toneCurve.point2 = CGPoint(x: 0.50, y: 0.50)
            toneCurve.point3 = CGPoint(x: 0.75, y: 0.82)
            toneCurve.point4 = CGPoint(x: 1.00, y: 0.96)
            if let out = toneCurve.outputImage { currentImage = out }
        }
        
        // Grano de película ultra fino para dar textura orgánica en sombras
        if let noise = CIFilter.randomGenerator().outputImage {
            let monochromeNoise = noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.018)
            ]).cropped(to: currentImage.extent)
            currentImage = monochromeNoise.composited(over: currentImage)
        }
        
        guard let cgImage = ciContext.createCGImage(currentImage, from: currentImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
    
    private func applyTempTint(to image: CIImage, temp: CGFloat, tint: CGFloat) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500, y: 0)
        filter.targetNeutral = CIVector(x: temp, y: tint)
        return filter.outputImage ?? image
    }
}

// MARK: - 3. Controlador de Cámara para iPhone 17 (Dual Wide: 0.5x, 1x, 2x)
@Observable
class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    
    var capturedImage: UIImage?
    var isProcessing = false
    var currentZoom: CGFloat = 1.0
    var selectedProfile: FilmProfile = .chromagraph
    var exposureBias: Float = -0.35 // Protege altas luces por defecto
    
    override init() {
        super.init()
        configureSession()
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // El iPhone 17 base usa builtInDualWideCamera (Ultra Wide 0.5x + Fusion 1x/2x)
        guard let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        currentDevice = device
        if session.canAddInput(input) { session.addInput(input) }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
        
        // Ajustar subexposición ligera para proteger altas luces como en cámaras de cine
        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(exposureBias, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {}
        
        session.commitConfiguration()
        Task.detached { self.session.startRunning() }
    }
    
    func setZoom(_ factor: CGFloat) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            // En DualWideCamera: 1.0 = 0.5x, 2.0 = 1x, 4.0 = 2x
            let isDualWide = device.deviceType == .builtInDualWideCamera
            let nativeFactor = isDualWide ? (factor * 2.0) : max(1.0, factor)
            device.ramp(toVideoZoomFactor: max(1.0, min(nativeFactor, device.maxAvailableVideoZoomFactor)), withRate: 4.0)
            device.unlockForConfiguration()
            currentZoom = factor
        } catch {}
    }
    
    func capturePhoto() {
        isProcessing = true
        
        let settings: AVCapturePhotoSettings
        // En iPhone 17 base buscamos el formato Bayer RAW directo del sensor
        if let bayerRAW = photoOutput.availableRawPhotoPixelFormatTypes.first(where: { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }) {
            settings = AVCapturePhotoSettings(rawPixelFormatType: bayerRAW)
        } else {
            // Si está usando el zoom 2x o lente secundario, usar captura de máxima calidad con fusión
            settings = AVCapturePhotoSettings()
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
        
        Task.detached(priority: .userInitiated) {
            let finalImage = CinematicPipeline.shared.developPhoto(data: data, profile: profile)
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
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async { layer.frame = uiView.bounds }
        }
    }
}

struct ContentView: View {
    @State private var camera = CameraManager()
    @State private var showFilmStrip = true
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0] // Lentes del iPhone 17 normal
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack {
                    Text(camera.selectedProfile.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(camera.selectedProfile.badgeColor.opacity(0.2))
                        .foregroundStyle(camera.selectedProfile.badgeColor)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring) { showFilmStrip.toggle() }
                    } label: {
                        Image(systemName: "film")
                            .foregroundStyle(showFilmStrip ? camera.selectedProfile.badgeColor : .white)
                    }
                }
                .padding(.horizontal, 24)
                
                ZStack(alignment: .bottom) {
                    CameraPreview(session: camera.session)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    VStack(spacing: 14) {
                        if showFilmStrip {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(FilmProfile.allCases) { profile in
                                        Button {
                                            camera.selectedProfile = profile
                                        } label: {
                                            VStack(spacing: 4) {
                                                Circle()
                                                    .fill(profile.badgeColor)
                                                    .frame(width: 14, height: 14)
                                                Text(profile.rawValue)
                                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                    .foregroundStyle(camera.selectedProfile == profile ? .black : .white)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(camera.selectedProfile == profile ? profile.badgeColor : Color.black.opacity(0.65))
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        HStack(spacing: 10) {
                            ForEach(zoomLevels, id: \.self) { level in
                                Button {
                                    camera.setZoom(level)
                                } label: {
                                    Text(level == 0.5 ? "0.5x" : "\(Int(level))x")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(camera.currentZoom == level ? .black : .white)
                                        .frame(width: 38, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(camera.currentZoom == level ? camera.selectedProfile.badgeColor : Color.black.opacity(0.6))
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
                                        .fill(camera.isProcessing ? Color.gray : Color.white)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .disabled(camera.isProcessing)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 48, height: 48)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
    }
}
