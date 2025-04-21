//
//  ContentView.swift
//  YourDrugs
//
//  Created by Patryk Opiela on 21/04/2025.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Update health data", destination: HealthInfoView())
                NavigationLink("Scan drug", destination: ScanView())
            }
            .navigationTitle("YourDrugs")
        }
    }
}

struct HealthInfoView: View {
    @State private var allergies: String = ""
    @State private var chronicConditions: String = ""

    var body: some View {
        Form {
            Section(header: Text("Allergy")) {
                TextField("Ie. penicillin", text: $allergies)
            }

            Section(header: Text("Chronic conditions")) {
                TextField("Ie. diebetes", text: $chronicConditions)
            }

            Button("Save") {
                // Tu zapisze dane do UserDefaults lub CoreData
            }
        }
        .navigationTitle("Health data")
    }
}

struct ScanView: View {
    @State private var isShowingScanner = false
    @State private var scannedCode: String = ""
    @State private var resultText: String = "Scan drug, to check contraindications."

    var body: some View {
        VStack(spacing: 20) {
            Text(resultText)
                .padding()

            Button("Scan code") {
                isShowingScanner = true
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView { result in
                    switch result {
                    case .success(let code):
                        scannedCode = code
                        isShowingScanner = false
                        checkForWarnings(ean: code)
                    case .failure:
                        resultText = "Scan error. Try again."
                        isShowingScanner = false
                    }
                }
            }
        }
        .navigationTitle("Scanning")
    }

    func checkForWarnings(ean: String) {
        // Przykład: W prawdziwej aplikacji tutaj będzie wywołanie API
        let simulatedDangerousSubstance = ["1234567890123": "Contain penicillin"]

        if let warning = simulatedDangerousSubstance[ean] {
            resultText = "WARNING: \(warning) - do not reccomend with your health conditions."
        } else {
            resultText = "There no contraindications for using this drug."
        }
    }
}

// MARK: - Minimalna implementacja kodu skanera
// Do działania wymagany będzie CodeScannerView lub podpięcie AVFoundation

struct CodeScannerView: UIViewControllerRepresentable {
    var completion: (Result<String, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let completion: (Result<String, Error>) -> Void

        init(completion: @escaping (Result<String, Error>) -> Void) {
            self.completion = completion
        }

        func didFind(code: String) {
            completion(.success(code))
        }

        func didFail(error: Error) {
            completion(.failure(error))
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(code: String)
    func didFail(error: Error)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    weak var delegate: ScannerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didFail(error: error)
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didFail(error: NSError(domain: "InputError", code: -1, userInfo: nil))
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8]
        } else {
            delegate?.didFail(error: NSError(domain: "OutputError", code: -1, userInfo: nil))
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            delegate?.didFind(code: stringValue)
        } else {
            delegate?.didFail(error: NSError(domain: "ScanError", code: -1, userInfo: nil))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

#Preview {
    ContentView()
}
