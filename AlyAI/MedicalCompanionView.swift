import SwiftUI

struct MedicalCompanionView: View {
    let userAnswers: [String: Any]
    @State private var symptoms: [SymptomLog] = []
    @State private var medications: [Medication] = []
    @State private var showAddSymptom = false
    @State private var showAddMedication = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.alyaiMental)
                        
                        Text("Medical Companion")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Track symptoms, medications, and wellness metrics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Quick Health Overview
                    healthOverviewCard
                    
                    // Symptoms Tracker
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Symptom Log")
                                .font(.headline)
                            Spacer()
                            Button {
                                showAddSymptom = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.alyaiMental)
                            }
                        }
                        
                        if symptoms.isEmpty {
                            EmptyStateCard(
                                icon: "heart.text.square",
                                title: "No symptoms logged",
                                subtitle: "Track how you're feeling"
                            )
                        } else {
                            ForEach(symptoms) { symptom in
                                SymptomCard(symptom: symptom)
                            }
                        }
                    }
                    
                    // Medications
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Medications")
                                .font(.headline)
                            Spacer()
                            Button {
                                showAddMedication = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.alyaiMental)
                            }
                        }
                        
                        if medications.isEmpty {
                            EmptyStateCard(
                                icon: "pills",
                                title: "No medications added",
                                subtitle: "Track your prescriptions"
                            )
                        } else {
                            ForEach(medications) { med in
                                MedicationCard(medication: med)
                            }
                        }
                    }
                    
                    // Health Metrics
                    healthMetricsSection
                    
                    // Upcoming Appointments
                    appointmentsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.alyaiPrimary)
                    }
                }
            }
        }
        .onAppear {
            loadSampleData()
        }
        .sheet(isPresented: $showAddSymptom) {
            AddSymptomSheet { symptom in
                symptoms.append(symptom)
            }
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationSheet { medication in
                medications.append(medication)
            }
        }
    }
    
    private var healthOverviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                HealthMetricView(icon: "heart.fill", value: "72", unit: "bpm", label: "Heart Rate", color: .red)
                HealthMetricView(icon: "figure.walk", value: "6,234", unit: "steps", label: "Steps", color: .green)
                HealthMetricView(icon: "bed.double.fill", value: "7.2", unit: "hrs", label: "Sleep", color: .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.alyaiLightBlue.opacity(0.2))
        )
    }
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
            
            VStack(spacing: 12) {
                MetricRowCard(icon: "heart.circle.fill", title: "Blood Pressure", value: "120/80", unit: "mmHg", color: .red)
                MetricRowCard(icon: "thermometer", title: "Temperature", value: "98.6", unit: "°F", color: .orange)
                MetricRowCard(icon: "drop.fill", title: "Blood Sugar", value: "95", unit: "mg/dL", color: .blue)
                MetricRowCard(icon: "lungs.fill", title: "Oxygen Level", value: "98", unit: "%", color: .cyan)
            }
        }
    }
    
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Appointments")
                .font(.headline)
            
            AppointmentCard(
                doctor: "Dr. Sarah Johnson",
                specialty: "General Practitioner",
                date: "Jan 15, 2025",
                time: "10:30 AM"
            )
            
            AppointmentCard(
                doctor: "Dr. Michael Chen",
                specialty: "Dentist",
                date: "Jan 22, 2025",
                time: "2:00 PM"
            )
        }
    }
    
    private func loadSampleData() {
        // Sample symptom
        symptoms = [
            SymptomLog(name: "Headache", severity: 3, notes: "Mild headache after lunch", date: Date()),
            SymptomLog(name: "Fatigue", severity: 2, notes: "Feeling tired in afternoon", date: Date().addingTimeInterval(-86400))
        ]
        
        // Sample medication
        medications = [
            Medication(name: "Vitamin D", dosage: "1000 IU", frequency: "Once daily", time: "Morning")
        ]
    }
}

// MARK: - Models

struct SymptomLog: Identifiable {
    let id = UUID()
    let name: String
    let severity: Int // 1-5
    let notes: String
    let date: Date
}

struct Medication: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let time: String
}

// MARK: - Supporting Views

struct HealthMetricView: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SymptomCard: View {
    let symptom: SymptomLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(symptom.name)
                        .font(.headline)
                    Text(symptom.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Severity indicator
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= symptom.severity ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            if !symptom.notes.isEmpty {
                Text(symptom.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct MedicationCard: View {
    let medication: Medication
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "pills.fill")
                .font(.system(size: 32))
                .foregroundColor(.alyaiMental)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                Text(medication.dosage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(medication.frequency) - \(medication.time)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                // Mark as taken
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.alyaiMental)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.alyaiLightBlue.opacity(0.2))
        )
    }
}

struct MetricRowCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Last updated: Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct AppointmentCard: View {
    let doctor: String
    let specialty: String
    let date: String
    let time: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundColor(.alyaiMental)
            }
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.alyaiLightPurple.opacity(0.3))
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doctor)
                    .font(.headline)
                Text(specialty)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(date) at \(time)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Add Sheets (Simplified)

struct AddSymptomSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (SymptomLog) -> Void
    
    @State private var symptomName = ""
    @State private var severity = 3
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Symptom name", text: $symptomName)
                Picker("Severity", selection: $severity) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Log Symptom")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(SymptomLog(name: symptomName, severity: severity, notes: notes, date: Date()))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Medication) -> Void
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    @State private var time = "Morning"
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Medication name", text: $name)
                TextField("Dosage", text: $dosage)
                TextField("Frequency", text: $frequency)
                TextField("Time", text: $time)
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(Medication(name: name, dosage: dosage, frequency: frequency, time: time))
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MedicalCompanionView(userAnswers: [:])
}
