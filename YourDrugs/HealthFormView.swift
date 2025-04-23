//
//  HealthFormView.swift
//  YourDrugs
//
//  Created by Patryk Opiela on 23/04/2025.
//

import SwiftUI
import CoreData

struct HealthFormView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var healthInfos: FetchedResults<HealthInfo>

    @State private var allergies = ""
    @State private var chronicDiseases = ""

    var body: some View {
        Form {
            Section(header: Text("Allergies")) {
                TextField("Ie. penniciline, peanuts", text: $allergies)
            }

            Section(header: Text("Chronic Diseases")) {
                TextField("Ie. diabedies, astma", text: $chronicDiseases)
            }

            Button("Save") {
                saveHealthInfo()
            }

            if let latest = healthInfos.last {
                Section(header: Text("Latest data")) {
                    Text("Allergies: \(latest.allergies ?? "-")")
                    Text("Diseases: \(latest.chronicDiseases ?? "-")")
                }
            }
        }
        .navigationTitle("Health profile")
    }

    private func saveHealthInfo() {
        for info in healthInfos {
            viewContext.delete(info)
        }

        let newInfo = HealthInfo(context: viewContext)
        newInfo.allergies = allergies
        newInfo.chronicDiseases = chronicDiseases

        do {
            try viewContext.save()
            allergies = ""
            chronicDiseases = ""
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }

}
