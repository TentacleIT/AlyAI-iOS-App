import SwiftUI

struct SchedulingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedProfessional: Professional?
    @State private var selectedTime: String?
    @State private var showConfirmation = false
    
    // Mock Professionals
    private let professionals = [
        Professional(name: "Dr. Sarah Chen", specialty: "Clinical Psychologist", rating: 4.9, image: "person.crop.circle"),
        Professional(name: "Mark Wilson", specialty: "Wellness Coach", rating: 4.8, image: "person.crop.circle.fill"),
        Professional(name: "Elena Rodriguez", specialty: "Mindfulness Instructor", rating: 5.0, image: "person.circle")
    ]
    
    // Mock Time Slots
    private let timeSlots = ["09:00 AM", "10:00 AM", "11:30 AM", "02:00 PM", "03:30 PM", "05:00 PM"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentPrimary)
                        
                        Text("Schedule Appointment")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Connect with a professional for personalized support")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // 1. Choose Professional
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose a Specialist")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(professionals) { prof in
                                    ProfessionalCard(professional: prof, isSelected: selectedProfessional?.id == prof.id) {
                                        withAnimation {
                                            selectedProfessional = prof
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 2. Select Date
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Date")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.surfacePrimary)
                                    .shadow(color: Color.shadow, radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal)
                    }
                    
                    // 3. Select Time
                    if selectedProfessional != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Times")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(timeSlots, id: \.self) { time in
                                    Button {
                                        selectedTime = time
                                    } label: {
                                        Text(time)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedTime == time ? Color.backgroundPrimary : Color.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedTime == time ? Color.accentPrimary : Color.surfacePrimary)
                                                    .shadow(color: Color.shadow, radius: 4, x: 0, y: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Confirm Button
                    Button {
                        confirmAppointmentAction()
                    } label: {
                        Text("Confirm Appointment")
                            .font(.headline)
                            .foregroundColor(Color.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill((selectedProfessional != nil && selectedTime != nil) ? Color.accentPrimary : Color.textSecondary)
                            )
                    }
                    .disabled(selectedProfessional == nil || selectedTime == nil)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
            .alert("Appointment Confirmed!", isPresented: $showConfirmation) {
                Button("Done") { dismiss() }
            } message: {
                if let prof = selectedProfessional, let time = selectedTime {
                    Text("You are scheduled with \(prof.name) on \(selectedDate.formatted(date: .abbreviated, time: .omitted)) at \(time).")
                }
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
    }
    
    private func confirmAppointmentAction() {
        guard let prof = selectedProfessional, let timeStr = selectedTime else { return }

        // 1. Combine Date and Time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        guard let timeDate = dateFormatter.date(from: timeStr) else { return }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        let scheduledDateTime = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: selectedDate) ?? selectedDate

        // 2. Create Appointment Object
        let appointment = Appointment(
            specialistType: prof.specialty,
            appointmentType: "Virtual", // Assuming virtual for now
            scheduledDateTime: scheduledDateTime,
            timezone: TimeZone.current.identifier,
            status: "Scheduled",
            notes: nil,
            specialistMetadata: SpecialistMetadata(name: prof.name, specialty: prof.specialty)
        )

        // 3. Save to Firestore via Manager
        AppointmentManager.shared.createAppointment(appointment: appointment) { [self] error in
            if let error = error {
                // Handle error (e.g., show an error alert)
                print("❌ Failed to save appointment: \(error.localizedDescription)")
            } else {
                // Show confirmation on success
                self.showConfirmation = true
            }
        }
    }
}

struct Professional: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let rating: Double
    let image: String
}

struct ProfessionalCard: View {
    let professional: Professional
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: professional.image)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? Color.backgroundPrimary : Color.accentPrimary)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.backgroundPrimary.opacity(0.3) : Color.surfacePrimary.opacity(0.3))
                    )
                
                VStack(spacing: 4) {
                    Text(professional.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? Color.backgroundPrimary : Color.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(professional.specialty)
                        .font(.caption)
                        .foregroundColor(isSelected ? Color.backgroundPrimary.opacity(0.9) : Color.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(Color.warning)
                        Text(String(format: "%.1f", professional.rating))
                            .font(.caption2)
                            .foregroundColor(isSelected ? Color.backgroundPrimary : Color.textSecondary)
                    }
                }
            }
            .padding()
            .frame(width: 160, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentPrimary : Color.surfacePrimary)
                    .shadow(color: Color.shadow, radius: 8, x: 0, y: 4)
            )
        }
    }
}

#Preview {
    SchedulingView()
}
