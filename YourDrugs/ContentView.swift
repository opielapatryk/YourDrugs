//
//  ContentView.swift
//  YourDrugs
//
//  Created by Patryk Opiela on 21/04/2025.
//

import SwiftUI
import AVFoundation
import Foundation

struct ProductLookupResult: Decodable {
    let products: [Product]
}

struct Product: Decodable {
    let title: String
    let brand: String?
    let description: String?
    let ingredients: String?
}

func fetchProduct(by barcode: String, completion: @escaping (Product?) -> Void) {
    let apiKey = "42miy4tmiqdmiimz69biwezag709uo"
    let urlStr = "https://api.barcodelookup.com/v3/products?barcode=\(barcode)&formatted=y&key=\(apiKey)"
    print("🌍 URL: \(urlStr)")

    guard let url = URL(string: urlStr) else {
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("❌ Request error: \(error.localizedDescription)")
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP status code: \(httpResponse.statusCode)")
        }

        if let data = data {
            print("📨 Raw JSON:")
            print(String(data: data, encoding: .utf8) ?? "⚠️ Cannot decode JSON to string")
        }

        do {
            let result = try JSONDecoder().decode(ProductLookupResult.self, from: data!)
            print("✅ Decoded product count: \(result.products.count)")

            if let product = result.products.first {
                print("🎯 Found product: \(product.title)")
                completion(product)
            } else {
                print("⚠️ No products found in API response.")
                completion(nil)
            }
        } catch {
            print("❌ JSON decode failed: \(error)")
            completion(nil)
        }
    }.resume()

}

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Update Health data", destination: HealthFormView())
                NavigationLink("Scan drug", destination: ScanView())
            }
            .navigationTitle("YourDrugs")
        }
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
                        print("📦 Scanned barcode: \(code)")
                        fetchProduct(by: code) { product in
                            DispatchQueue.main.async {
                                if let product = product {
                                    resultText = """
                                    ✅ Found: \(product.title)
                                    🏷 Brand: \(product.brand ?? "-")
                                    🧪 Ingredients: \(product.ingredients ?? "-")
                                    """
                                } else {
                                    resultText = "Cannot find drug for this EAN."
                                }
                            }
                        }
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
        let simulatedDangerousSubstance = ["1234567890123": "Contain penicillin"]

        if let warning = simulatedDangerousSubstance[ean] {
            resultText = "WARNING: \(warning) - do not reccomend with your health conditions."
        } else {
            resultText = "There no contraindications for using this drug."
        }
    }
}

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
