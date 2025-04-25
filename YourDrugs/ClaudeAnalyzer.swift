//
//  ClaudeAnalyzer.swift
//  YourDrugs
//
//  Created by Patryk Opiela on 23/04/2025.
//

import SwiftUI
import AVFoundation
import Foundation
import KeychainAccess

struct ClaudeAPIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

func analyzeDrugSafety(drugBarcode: String, allergies: String, conditions: String, completion: @escaping (String?) -> Void) {
    let prompt = """
    Look up the medication with barcode “\(drugBarcode)” and tell me if it is allowed for human with conditions like \(conditions) and allergies \(allergies). Verify if drug with given barcode exists if yes respond with a very brief and strict statement either "Allowed" or "Not allowed" + reason. Do NOT mention the barcode, refer only to the medication name.
    """

    let body: [String: Any] = [
        "max_tokens": 300,
        "model": "anthropic/claude-3-sonnet",
        "messages": [
            ["role": "user", "content": prompt]
        ]
    ]

    let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    print("📤 Request Body: \(body)")
    print("📡 Request URL: \(request.url?.absoluteString ?? "")")

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data else {
            print("❌ Error: No data")
            completion("No response from server.")
            return
        }

        print("📨 JSON response:")
        if let jsonString = String(data: data, encoding: .utf8) {
            print(jsonString)
        } else {
            print("⚠️ Cannot convert data to text.")
        }

        do {
            let decoded = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
            if let reply = decoded.choices.first?.message.content {
                completion(reply)
            } else {
                print("⚠️ No content in message.")
                completion("Claude do not respond.")
            }
        } catch {
            print("❌ Decode error: \(error)")
            completion("Decode error.")
        }
    }.resume()
}

func getAPIKey() -> String {
    let keychain = Keychain(service: "com.yourdrugs.app")
    do {
        if let apiKey = try keychain.get("openrouter_api_key"), !apiKey.isEmpty {
            return apiKey
        } else {
            fatalError("❌ There is no key in Keychain")
        }
    } catch {
        fatalError("❌ Read error from Keychain: \(error)")
    }
}

func storeApiKeyInKeychain(_ key: String) {
    let keychain = Keychain(service: "com.yourdrugs.app")
    do {
        try keychain.set(key, key: "openrouter_api_key")
        print("✅ Key saved in Keychain")
    } catch {
        print("❌ Error occured while saving key in Keychain: \(error)")
    }
}

struct APIKeyAlertView: View {
    @State private var showAlert = false
    @State private var apiKeyInput = ""

    var body: some View {
        Button("🔑 Insert API key") {
            showAlert = true
        }
        .alert("Insert API key", isPresented: $showAlert) {
            TextField("sk-or-...", text: $apiKeyInput)
            Button("Save") {
                storeApiKeyInKeychain(apiKeyInput)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Insert OpenRouter key for calude, which will be saved in keychain.")
        }
    }
}
