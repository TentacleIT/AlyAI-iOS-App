import SwiftUI

struct ExpandedSymptomLogView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager = CycleManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Physical Symptoms")) {
                    SymptomRow(title: "Cramps", icon: "stomach", entry: Binding(
                        get: { manager.todayLog?.symptoms.cramps ?? SymptomEntry() },
                        set: { updateSymptom(\.cramps, value: $0) }
                    ))
                    
                    SymptomRow(title: "Bloating", icon: "wind", entry: Binding(
                        get: { manager.todayLog?.symptoms.bloating ?? SymptomEntry() },
                        set: { updateSymptom(\.bloating, value: $0) }
                    ))
                    
                    SymptomRow(title: "Breast Tenderness", icon: "heart.fill", entry: Binding(
                        get: { manager.todayLog?.symptoms.breastTenderness ?? SymptomEntry() },
                        set: { updateSymptom(\.breastTenderness, value: $0) }
                    ))
                    
                    SymptomRow(title: "Headache", icon: "brain.head.profile", entry: Binding(
                        get: { manager.todayLog?.symptoms.headache ?? SymptomEntry() },
                        set: { updateSymptom(\.headache, value: $0) }
                    ))
                    
                    SymptomRow(title: "Back Pain", icon: "figure.walk", entry: Binding(
                        get: { manager.todayLog?.symptoms.backPain ?? SymptomEntry() },
                        set: { updateSymptom(\.backPain, value: $0) }
                    ))
                    
                    SymptomRow(title: "Joint Pain", icon: "figure.stand", entry: Binding(
                        get: { manager.todayLog?.symptoms.jointPain ?? SymptomEntry() },
                        set: { updateSymptom(\.jointPain, value: $0) }
                    ))
                    
                    SymptomRow(title: "Nausea", icon: "face.dashed", entry: Binding(
                        get: { manager.todayLog?.symptoms.nausea ?? SymptomEntry() },
                        set: { updateSymptom(\.nausea, value: $0) }
                    ))
                    
                    SymptomRow(title: "Cravings", icon: "fork.knife", entry: Binding(
                        get: { manager.todayLog?.symptoms.cravings ?? SymptomEntry() },
                        set: { updateSymptom(\.cravings, value: $0) }
                    ))
                }
                
                Section(header: Text("Discharge")) {
                    DischargePicker(selection: Binding(
                        get: { manager.todayLog?.symptoms.discharge ?? DischargeEntry() },
                        set: {
                            var log = manager.todayLog ?? CycleLog(date: Date(), phase: manager.currentPhase)
                            log.symptoms.discharge = $0
                            manager.saveLog(log)
                        }
                    ))
                }
            }
            .navigationTitle("Log Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func updateSymptom(_ keyPath: WritableKeyPath<CycleSymptoms, SymptomEntry?>, value: SymptomEntry) {
        var log = manager.todayLog ?? CycleLog(date: Date(), phase: manager.currentPhase)
        log.symptoms[keyPath: keyPath] = value
        manager.saveLog(log)
    }
}

struct SymptomRow: View {
    let title: String
    let icon: String
    @Binding var entry: SymptomEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.accentPrimary)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Toggle("", isOn: $entry.isPresent)
                    .labelsHidden()
            }
            
            if entry.isPresent {
                VStack(alignment: .leading) {
                    Text("Severity").font(.caption).foregroundColor(Color.textSecondary)
                    Picker("Severity", selection: $entry.severity) {
                        ForEach(SymptomSeverity.allCases, id: \.self) { severity in
                            Text(severity.rawValue).tag(severity)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Notes (optional)", text: Binding(
                        get: { entry.notes ?? "" },
                        set: { entry.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DischargePicker: View {
    @Binding var selection: DischargeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Type", selection: $selection.type) {
                ForEach(DischargeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            // .pickerStyle(.wheel) // Wheel takes too much space, or menu? Default is fine for List
            
            TextField("Notes (optional)", text: Binding(
                get: { selection.notes ?? "" },
                set: { selection.notes = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
