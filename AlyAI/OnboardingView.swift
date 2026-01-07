import SwiftUI
import AuthenticationServices

// MARK: - Models

fileprivate enum QuestionType {
    case intro
    case privacyIntro
    case singleChoice
    case multipleChoice
    case dateOfBirth
    case textInput
    case slider
}

fileprivate struct OptionItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String? // For the dot patterns or icons
    var color: Color = .accentPrimary
    var isCustom: Bool = false
}

fileprivate struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let subtitle: String?
    let type: QuestionType
    let options: [OptionItem]?
    // Graph Data could be added here if needed, but we'll hardcode for visual demo
}

fileprivate enum OnboardingStage {
    case questions
    case analyzing // Step 15
    case result // Step 16
    case requestHealth // New
    case requestNotifications // New
    case createAccount // Step 17
}

// MARK: - View

struct OnboardingView: View {
    @EnvironmentObject var userSession: UserSession
    
    let onComplete: ([String: Any], AssessmentResult, [SupportPlanItem]) -> Void

    // MARK: State
    @State private var stage: OnboardingStage = .questions
    @State private var index = 0
    
    // Form Values
    @State private var answers: [String: Any] = [:]
    
    // Specific State for Custom Inputs
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var textValue: String = ""
    @State private var sliderValue: Double = 5.0
    @State private var customInputText: String = "" // For inline custom goals
    @FocusState private var isCustomFieldFocused: Bool

    // Analysis & Results
    @State private var loadingProgress: Double = 0.0
    @State private var loadingStageText: String = "Preparing your companion..."
    @State private var assessmentResult: AssessmentResult?
    @State private var recommendedSupports: [SupportPlanItem] = []
    
    @State private var selectedFeature: SupportPlanItem?
    @State private var showFeatureDetail = false
    
    // Error Handling
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: Questions Definition
    private let questions: [OnboardingQuestion] = [
        
        // 2. Introduction Screen
        OnboardingQuestion(
            key: "intro",
            title: "Welcome to AlyAI",
            subtitle: "Your pocket mental health companion.",
            type: .intro,
            options: nil
        ),
        
        // 3. Gender
        OnboardingQuestion(
            key: "gender",
            title: "How do you identify?",
            subtitle: "This helps us tailor your personal support.",
            type: .singleChoice,
            options: [
                OptionItem(title: "Female", subtitle: nil, icon: "figure.stand.dress", color: .alyaiEmotional),
                OptionItem(title: "Male", subtitle: nil, icon: "figure.stand", color: .alyaiMental),
                OptionItem(title: "Non-binary", subtitle: nil, icon: "figure.2.arms.open", color: .accentPrimary),
                OptionItem(title: "Prefer not to say", subtitle: nil, icon: "person.fill.questionmark", color: .textSecondary)
            ]
        ),
        
        // 4. When were u born
        OnboardingQuestion(
            key: "dob",
            title: "When were you born?",
            subtitle: "We tailor our conversations to your life stage.",
            type: .dateOfBirth,
            options: nil
        ),
        
        // 6. Whats your goal
        OnboardingQuestion(
            key: "main_goal",
            title: "What is your primary goal?",
            subtitle: nil,
            type: .multipleChoice,
            options: [
                OptionItem(title: "Feel better emotionally", subtitle: nil, icon: "heart.fill", color: .alyaiEmotional),
                OptionItem(title: "Sleep better", subtitle: nil, icon: "moon.stars.fill", color: .indigo),
                OptionItem(title: "Mental peace", subtitle: nil, icon: "brain.head.profile", color: .alyaiMental),
                OptionItem(title: "Reduce Stress", subtitle: nil, icon: "leaf.fill", color: .alyaiPhysical),
                OptionItem(title: "Understand myself", subtitle: nil, icon: "sparkles", color: .accentPrimary),
                OptionItem(title: "Overcome Anxiety", subtitle: nil, icon: "sun.max.fill", color: .orange),
                OptionItem(title: "Something else", subtitle: "Write my own goal", icon: "pencil", color: .textSecondary, isCustom: true)
            ]
        ),
        
        // 7. Whats Your greatest need?
        OnboardingQuestion(
            key: "greatest_need",
            title: "What is your greatest need right now?",
            subtitle: nil,
            type: .multipleChoice,
            options: [
                OptionItem(title: "A Safe Space to Vent", subtitle: "I need to talk without being judged.", icon: "bubble.right.fill", color: .alyaiMental),
                OptionItem(title: "Emotional Clarity", subtitle: "I need help understanding my feelings.", icon: "sparkles", color: .accentPrimary),
                OptionItem(title: "Coping Strategies", subtitle: "I need practical tools for stress.", icon: "shield.fill", color: .alyaiPhysical),
                OptionItem(title: "Daily Encouragement", subtitle: "I need a friendly nudge to keep going.", icon: "hand.thumbsup.fill", color: .alyaiEmotional),
                
                // New Options
                OptionItem(title: "Calm My Anxiety", subtitle: "I need help calming my racing thoughts or panic.", icon: "wind", color: .alyaiMental),
                OptionItem(title: "Help Me Sleep", subtitle: "I struggle to sleep or my thoughts keep me awake.", icon: "moon.zzz.fill", color: .indigo),
                OptionItem(title: "Stop Overthinking", subtitle: "I keep replaying the same thoughts and can’t stop.", icon: "arrow.triangle.2.circlepath", color: .alyaiPhysical),
                OptionItem(title: "Feel Understood", subtitle: "I want support from someone who truly gets me.", icon: "heart.text.square.fill", color: .alyaiEmotional),
                OptionItem(title: "I want to describe it", subtitle: "In my own words", icon: "pencil", color: .textSecondary, isCustom: true)
            ]
        ),
        
        // 8. Body Connection (Restored)
        OnboardingQuestion(
            key: "body_connection",
            title: "How connected do you feel to your body?",
            subtitle: "0 = disconnected, 10 = very connected",
            type: .slider,
            options: nil
        ),
        
        // 9. What would you like to achieve with AlyAI
        OnboardingQuestion(
            key: "achievement",
            title: "What would you like to achieve with AlyAI?",
            subtitle: "Select the outcome that matters most.",
            type: .singleChoice,
            options: [
                OptionItem(title: "Feel Happier", subtitle: nil, icon: "face.smiling.fill", color: .alyaiEmotional),
                OptionItem(title: "Find Peace", subtitle: nil, icon: "sun.haze.fill", color: .alyaiMental),
                OptionItem(title: "Build Resilience", subtitle: nil, icon: "shield.fill", color: .alyaiPhysical),
                OptionItem(title: "Understand Myself", subtitle: nil, icon: "lightbulb.fill", color: .accentPrimary),
                OptionItem(title: "Write my own intention", subtitle: nil, icon: "pencil", color: .textSecondary, isCustom: true)
            ]
        ),
        
        // 13. What should AlyAI call you
        OnboardingQuestion(
            key: "name",
            title: "What should AlyAI call you?",
            subtitle: nil,
            type: .textInput,
            options: nil
        ),
        
        // 14. Thanks for trusting us
        OnboardingQuestion(
            key: "privacy_intro",
            title: "Thank you for trusting us!",
            subtitle: "Your privacy is our priority.",
            type: .privacyIntro,
            options: nil
        )
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack {
                switch stage {
                case .questions:
                    questionsView
                case .analyzing:
                    analysisView
                case .result:
                    resultView
                case .requestHealth:
                    HealthPermissionView {                        withAnimation { stage = .requestNotifications }                    }
                case .requestNotifications:
                    NotificationPermissionView {                        withAnimation { moveToCreateAccount() }                    }
                case .createAccount:
                    createAccountView
                }
            }
        }
        .sheet(isPresented: $showFeatureDetail) {
            if let feature = selectedFeature {
                SupportFeatureDetailView(feature: feature, userAnswers: answers)
            }
        }
        .alert("Assessment Issue", isPresented: $showError) {
            Button("Retry", role: .cancel) {
                startAnalysis()
            }
            Button("Go Back") {
                stage = .questions
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Questions Flow

    private var questionsView: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                if index > 0 {
                    Button {
                        withAnimation { index -= 1 }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(Color.textPrimary)
                            .padding(12)
                            .background(Circle().fill(Color.surfacePrimary))
                    }
                } else {
                    Spacer().frame(width: 44)
                }
                
                Spacer()
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.surfacePrimary)
                        Capsule()
                            .fill(Color.alyaiGradient)
                            .frame(width: geo.size.width * (Double(index + 1) / Double(questions.count)))
                    }
                }
                .frame(height: 6)
                .frame(maxWidth: 200)
                
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding()

            Spacer()
            
            // Content
            questionContent
                .transition(.opacity)
                .id(index) // Force redraw on index change
            
            Spacer()
            
            // Continue Button
            Button {
                nextQuestion()
            } label: {
                Text(questions[index].type == .intro ? "Get Started" : "Continue")
            }
            .buttonStyle(AlyPrimaryButtonStyle())
            .padding()
            .disabled(!canContinue())
            .opacity(canContinue() ? 1 : 0.5)
        }
    }

    private var questionContent: some View {
        let q = questions[index]
        
        return VStack(spacing: 24) {
            Text(q.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let subtitle = q.subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            switch q.type {
            case .intro:
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo or Hero Image
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.surfacePrimary, Color.backgroundPrimary],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)
                            .shadow(color: Color.shadow.opacity(0.12), radius: 12, y: 6)

                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.alyaiPrimary.opacity(0.3), radius: 15, y: 8) // Subtle glow
                    }
                    
                    VStack(spacing: 16) {
                        Text("Your Pocket\nCompanion")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("A safe, private space to open up and find support.")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                
            case .privacyIntro:
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Illustration placeholder
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.surfacePrimary, Color.backgroundPrimary],
                                    center: .center, startRadius: 50, endRadius: 140
                                )
                            )
                            .frame(width: 280, height: 280)
                        
                        Image(systemName: "hand.raised.fill") // Placeholder for trust
                            .font(.system(size: 120))
                            .foregroundStyle(Color.textPrimary)
                            .rotationEffect(.degrees(-10))
                            .shadow(color: .black.opacity(0.1), radius: 10)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("Your privacy and security matter to us.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("We promise to always keep your\npersonal information private and secure.")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.surfacePrimary))
                }
                .padding(.horizontal)

            case .singleChoice:
                VStack(spacing: 12) {
                    ForEach(q.options!) { option in
                        Button {
                            answers[q.key] = option.title
                        } label: {
                            let isSelected = (answers[q.key] as? String) == option.title
                            
                            HStack(spacing: 16) {
                                if let iconName = option.icon {
                                    Image(systemName: iconName)
                                        .font(.system(size: 22))
                                        .foregroundStyle(isSelected ? Color.backgroundPrimary : option.color)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(isSelected ? Color.backgroundPrimary.opacity(0.2) : option.color.opacity(0.1))
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.title)
                                        .font(.headline)
                                        .foregroundColor(isSelected ? .backgroundPrimary : .textPrimary)
                                    
                                    if let sub = option.subtitle {
                                        Text(sub)
                                            .font(.caption)
                                            .foregroundColor(isSelected ? .backgroundPrimary.opacity(0.9) : .textSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.backgroundPrimary)
                                }
                            }
                            .padding()
                            .background(
                                ZStack {
                                    if isSelected {
                                        option.color
                                    } else {
                                        Color.surfacePrimary
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.shadow, radius: 4, x: 0, y: 2) // Darker shadow for dark mode
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isSelected ? Color.clear : Color.surfacePrimary.opacity(0.5), lineWidth: 1)
                                )
                            )
                        }
                    }
                    
                    // Show TextField if custom option is selected
                    if let selectedTitle = answers[q.key] as? String,
                       let selectedOption = q.options?.first(where: { $0.title == selectedTitle }),
                       selectedOption.isCustom {
                        
                        TextField("Type your own...", text: $customInputText)
                            .font(.body)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfacePrimary))
                            .focused($isCustomFieldFocused)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isCustomFieldFocused = true
                                }
                            }
                    }
                }
                .padding(.horizontal)

            case .multipleChoice:
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(q.options!) { option in
                            Button {
                                var selected = (answers[q.key] as? [String]) ?? []
                                if let idx = selected.firstIndex(of: option.title) {
                                    selected.remove(at: idx)
                                } else {
                                    selected.append(option.title)
                                }
                                answers[q.key] = selected
                            } label: {
                                let selected = (answers[q.key] as? [String]) ?? []
                                let isSelected = selected.contains(option.title)
                                
                                HStack(spacing: 16) {
                                    if let iconName = option.icon {
                                        Image(systemName: iconName)
                                            .font(.system(size: 22))
                                            .foregroundStyle(isSelected ? Color.backgroundPrimary : option.color)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(isSelected ? Color.backgroundPrimary.opacity(0.2) : option.color.opacity(0.1))
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.title)
                                            .font(.headline)
                                            .foregroundColor(isSelected ? .backgroundPrimary : .textPrimary)
                                        
                                        if let sub = option.subtitle {
                                            Text(sub)
                                                .font(.caption)
                                                .foregroundColor(isSelected ? .backgroundPrimary.opacity(0.9) : .textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.backgroundPrimary)
                                    }
                                }
                                .padding()
                                .background(
                                    ZStack {
                                        if isSelected {
                                            option.color
                                        } else {
                                            Color.surfacePrimary
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.shadow, radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isSelected ? Color.clear : Color.borderSubtle, lineWidth: 1)
                                    )
                                )
                            }
                        }
                        
                        // Show TextField if custom option is selected
                        if let selected = answers[q.key] as? [String],
                           let customOption = q.options?.first(where: { $0.isCustom }),
                           selected.contains(customOption.title) {
                            
                            TextField("Describe it here...", text: $customInputText)
                                .font(.body)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfacePrimary))
                                .focused($isCustomFieldFocused)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isCustomFieldFocused = true
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

            case .dateOfBirth:
                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            
            case .textInput:
                TextField("Type here...", text: $textValue)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.surfacePrimary)
                            .shadow(color: Color.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    .onChange(of: textValue) { oldValue, newValue in
                        answers[q.key] = newValue
                    }
                
            case .slider:
                VStack(spacing: 40) {
                    Text("\(Int(sliderValue)) / 10")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.alyaiGradient)
                    
                    CustomSlider(value: $sliderValue, range: 0...10, step: 1)
                        .padding(.horizontal, 20) // Add padding for knob overhang
                        .onAppear {
                            // Ensure default is saved if user doesn't move slider
                            if answers[q.key] == nil {
                                answers[q.key] = Int(sliderValue)
                            }
                        }
                        .onChange(of: sliderValue) { _, newValue in
                            answers[q.key] = Int(newValue)
                        }
                }
                .padding()
                
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Navigation Logic

    private func canContinue() -> Bool {
        let q = questions[index]
        let result = _canContinueCheck(q)
        print("✅ [OnboardingView] canContinue() = \(result) for index \(index), type: \(q.type)")
        return result
    }
    
    private func _canContinueCheck(_ q: OnboardingQuestion) -> Bool {
        
        // Check custom input validity
        if let customOption = q.options?.first(where: { $0.isCustom }) {
            if q.type == .singleChoice {
                if let selected = answers[q.key] as? String, selected == customOption.title {
                    return !customInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            } else if q.type == .multipleChoice {
                if let selected = answers[q.key] as? [String], selected.contains(customOption.title) {
                    return !customInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            }
        }
        
        switch q.type {
        case .intro, .privacyIntro, .dateOfBirth, .slider:
            return true
        case .textInput:
            return !textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .multipleChoice:
            if let selected = answers[q.key] as? [String] {
                return !selected.isEmpty
            }
            return false
        default:
            return answers[q.key] != nil
        }
    }
    
    private func nextQuestion() {
        print("🔘 [OnboardingView] nextQuestion() called - Current index: \(index), Type: \(questions[index].type)")
        let q = questions[index]
        
        // Handle Custom Input Saving (Swap placeholder for real text)
        if let customOption = q.options?.first(where: { $0.isCustom }) {
            if q.type == .singleChoice {
                if let selected = answers[q.key] as? String, selected == customOption.title {
                    answers[q.key] = customInputText
                }
            } else if q.type == .multipleChoice {
                if var selected = answers[q.key] as? [String], selected.contains(customOption.title) {
                    selected.removeAll { $0 == customOption.title }
                    if !customInputText.isEmpty {
                        selected.append(customInputText)
                    }
                    answers[q.key] = selected
                }
            }
        }

        // Save intermediate state if needed
        if questions[index].key == "name" {
            userSession.userName = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if questions[index].type == .textInput && questions[index].key != "name" {
            answers[questions[index].key] = textValue
            textValue = "" // Reset for next text input if any
        }
        
        if index < questions.count - 1 {
            withAnimation {
                index += 1
                customInputText = "" // Reset custom input for next screen
            }
        } else {
            // Finished questions
            startAnalysis()
        }
    }
    
    // MARK: - Analysis View (Loading)
    
    private var analysisView: some View {
        VStack(spacing: 32) {
            Text("\(Int(loadingProgress * 100))%")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(Color.alyaiGradient)
            
            Text("We\'re setting everything\nup for you")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            ProgressView(value: loadingProgress, total: 1.0)
                .tint(Color.accentPrimary)
                .frame(width: 200)
            
            Text(loadingStageText)
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Optimizing your plan for")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                analysisRow(title: "Emotional Support", isChecked: loadingProgress > 0.2)
                analysisRow(title: "Stress Resilience", isChecked: loadingProgress > 0.4)
                analysisRow(title: "Personal Privacy", isChecked: loadingProgress > 0.6)
                analysisRow(title: "Daily Guidance", isChecked: loadingProgress > 0.8)
                analysisRow(title: "Mental Peace", isChecked: loadingProgress > 0.9)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.surfacePrimary))
            .padding(.horizontal)
        }
    }
    
    private func analysisRow(title: String, isChecked: Bool) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.textPrimary)
            Spacer()
            if isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.success)
                    .font(.system(size: 24))
            } else {
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.backgroundPrimary))
        .shadow(color: Color.shadow.opacity(0.08), radius: 5, x: 0, y: 3)
    }
    
    private func startAnalysis() {
        stage = .analyzing
        
        // Construct Prompt
        print("🔍 [Onboarding] Answers State: \(answers)")
        let name = userSession.userName
        
        print("🔍 [Onboarding] Generating plan for Name: '" + name + "'")
        
        let gender = answers["gender"] as? String ?? "Not specified"
        let goals: String
        if let gArray = answers["main_goal"] as? [String] {
             goals = gArray.joined(separator: ", ")
        } else if let gString = answers["main_goal"] as? String {
             goals = gString
        } else {
             goals = "General wellness"
        }
        
        // Collect Greatest Needs in structured format
        var greatestNeedsPayload: [[String: String]] = []
        if let selectedTitles = answers["greatest_need"] as? [String],
           let question = questions.first(where: { $0.key == "greatest_need" }),
           let options = question.options {
            
            for title in selectedTitles {
                if let option = options.first(where: { $0.title == title }) {
                    greatestNeedsPayload.append([
                        "title": option.title,
                        "description": option.subtitle ?? "",
                        "icon": option.icon ?? ""
                    ])
                } else {
                    // Custom user input (not found in predefined options)
                    greatestNeedsPayload.append([
                        "title": title,
                        "description": "User\'s own words",
                        "icon": "person.fill"
                    ])
                }
            }
        }
        
        let achievement = answers["achievement"] as? String ?? "Peace"
        let bodyConnection = answers["body_connection"] as? Int ?? 5
        
        let prompt = """
        You are AlyAI, a supportive, calm, and emotionally intelligent pocket mental health companion.
        
        USER IDENTITY:
        The user\'s name is: "\(name)"
        
        CRITICAL INSTRUCTION:
        1. You must address the user as "\(name)".
        2. NEVER use "Friend", "User", or "Buddy".
        3. Start the message with "Welcome, \(name)!".

        CRITICAL PERSONALIZATION RULE (NON-NEGOTIABLE):
        - The user’s name is \(name).
        - You MUST always address the user directly by \(name).
        - You are STRICTLY FORBIDDEN from using generic terms such as: "Friend", "User", "There", "Someone", or any placeholder name.
        - If a response would normally include a greeting, it MUST include \(name) naturally.

        CONTEXT YOU WILL RECEIVE:
        - User name: \(name)
        - Gender: \(gender)
        - Goals: \(goals)
        - Greatest Needs: \(greatestNeedsPayload)
        - Desired Achievement: \(achievement)
        - Body Connection Score: \(bodyConnection)/10
        - Onboarding answers: \(answers)

        CORE RESPONSIBILITIES:
        1. Generate personalized assessment summaries using the user’s name.
        2. Tailor recommendations based on user’s selected onboarding answers and emotional patterns.
        3. Adapt tone and suggestions as the user’s journey progresses.
        4. Reference past activity when relevant (continuity is essential).

        STYLE & TONE:
        - Warm, human, supportive, and encouraging
        - Never clinical, robotic, or generic
        - Short paragraphs, easy-to-read language
        - Speak directly to \(name) as a trusted guide
        - Validate feelings without reinforcing helplessness

        MENTAL HEALTH SAFETY RULES:
        - Do NOT describe or depict self-harm, suicide, or graphic distress.
        - Do NOT encourage dependency on the app.
        - Encourage healthy coping, reflection, and gradual progress.
        - If distress is implied, respond with grounding, reassurance, and supportive guidance.

        RECOMMENDATIONS LOGIC:
        - All suggested actions must align with the user’s assessment results.
        - Avoid repeating the same advice unless it is intentional and explained.

        TASK:
        Generate a personalized wellness plan for \(name) based on their profile.

        CRITICAL: 
        1. You MUST address the user by their name "\(name)" in the message. NEVER use 'Friend'.
        2. You MUST explicitly acknowledge each selected "Greatest Need" in the assessment.
        3. Recommendations MUST be directly tied to these needs.
        4. Based on the user’s final assessment and selected onboarding answers, generate clear, actionable next steps.
        5. Each action must directly support a user-identified need and be suitable for display as a dashboard task.
        6. Do not include generic wellness advice or actions unrelated to the assessment.
        7. If \(name) exists and your response does NOT include it, the response is considered INVALID.
        
        OUTPUT FORMAT:
        Provide a valid JSON object with the following keys:

        - "message":
          A warm, encouraging welcome message (max 30 words).
          IMPORTANT:
          - You MUST address the user by their actual name provided as \(name).
          - You are STRICTLY FORBIDDEN from using the words "Friend", "User", or any generic placeholder.
          - If the name is missing, ask for the user\'s name instead of continuing.

        - "assessment_summary":
          A personalized summary explaining how \(name)’s needs relate to their emotional state.
          The summary MUST reference \(name) naturally.

        - "key_insights":
          Array of short, personalized bullet-point insights.
          DO NOT use generic phrasing.
          Each insight should feel tailored to \(name).

        - "planExplanation":
          A short, 2-sentence explanation of why this specific balance of check-ins, sleep, and mindfulness is recommended for \(name).

        - "dailyCheckins": Integer (1–5)

        - "sleepHours": Double (6.0–9.0)

        - "mindfulnessMinutes": Integer (5–30)

        - "emotionalResilience": Integer (50–95)

        - "healthScore": Integer (5–9)

        - "identified_needs":
          Array of strings representing needs explicitly selected or inferred from \(name)’s onboarding answers.

        - "recommendations":
          Array of objects, each with:
            - "title": String
            - "icon": String (valid SF Symbol name)
            - "description": String (Why this helps \(name))
            - "related_needs": Array of Strings

        - "recommended_actions":
          Array of objects, each with:
            - "title": String
            - "description": String (Why it matters to \(name))
            - "related_need": String
            - "suggested_frequency": String ("Daily", "Weekly", "As needed")
            - "priority": String ("High", "Medium", "Low")
        """
        
        print("📤 [Onboarding] Sending Prompt to OpenAI:\n\(prompt)")
        
        // Start API Call
        OpenAIService.shared.runAssessment(prompt: prompt, jsonMode: true) { response in
            DispatchQueue.main.async {
        print("📥 [Onboarding] Raw Response from OpenAI:\n\(response)")
        
        // Parse JSON
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ [Onboarding] Assessment Failed. Response was not valid JSON.")
                    self.handleAssessmentError(message: "We couldn\'t generate your plan at this time. Please check your connection and try again.")
                    return
                }
                
                // Attempt to decode AssessmentResult directly
                do {
                    let decoder = JSONDecoder()
                    // We need to handle that `message` maps to `title` in our struct via CodingKeys
                    // But our struct expects `message` key in JSON because we set CodingKeys title = "message"
                    
                    // Decode manual fields if needed or rely on Codable
                    // Since we have a mix of parsing logic, let's try to decode the whole object into AssessmentResult if possible, 
                    // or construct it.
                    
                    // Client-side fix: Ensure name is used instead of "Friend" if OpenAI defaults to generic
                    var cleanJson = json
                    
                    print("✅ [Onboarding] Final Cleaned Response used for App:\n\(cleanJson)")

                    // Re-encode JSON dictionary to data to decode into struct (cleaner than manual parsing)
                    let jsonData = try JSONSerialization.data(withJSONObject: cleanJson)
                    let result = try decoder.decode(AssessmentResult.self, from: jsonData)
                    
                    // Parse Recommendations (SupportPlanItem) separately as they are not in AssessmentResult
                    var parsedSupports: [SupportPlanItem] = []
                    if let recs = json["recommendations"] as? [[String: Any]] {
                        for r in recs {
                            if let title = r["title"] as? String,
                               let icon = r["icon"] as? String {
                                let desc = r["description"] as? String
                                let related = r["related_needs"] as? [String]
                                parsedSupports.append(SupportPlanItem(title: title, icon: icon, description: desc, relatedNeeds: related))
                            }
                        }
                    }
                    
                    self.recommendedSupports = parsedSupports
                    self.assessmentResult = result
                    self.stage = .result
                    
                } catch {
                    print("❌ [Onboarding] Failed to decode AssessmentResult: \(error)")
                    // Fallback to manual parsing if decode fails
                    let message = json["message"] as? String ?? "Welcome!"
                    let assessmentSummary = json["assessment_summary"] as? String ?? message
                    let keyInsights = json["key_insights"] as? [String] ?? []
                    let planExplanation = json["planExplanation"] as? String ?? "Designed for balance."
                    let dailyCheckins = json["dailyCheckins"] as? Int ?? 2
                    let sleepHours = json["sleepHours"] as? Double ?? 7.5
                    let mindfulnessMinutes = json["mindfulnessMinutes"] as? Int ?? 15
                    let emotionalResilience = json["emotionalResilience"] as? Int ?? 85
                    let healthScore = json["healthScore"] as? Int ?? 8
                    let identifiedNeeds = json["identified_needs"] as? [String] ?? []
                    
                    // Parse Actions
                    var actions: [RecommendedAction] = []
                    if let acts = json["recommended_actions"] as? [[String: Any]] {
                        for a in acts {
                            if let t = a["title"] as? String,
                               let d = a["description"] as? String,
                               let rn = a["related_need"] as? String,
                               let sf = a["suggested_frequency"] as? String,
                               let p = a["priority"] as? String {
                                actions.append(RecommendedAction(title: t, description: d, relatedNeed: rn, suggestedFrequency: sf, priority: p))
                            }
                        }
                    }
                    
                    self.assessmentResult = AssessmentResult(
                        title: message,
                        summary: assessmentSummary,
                        planExplanation: planExplanation,
                        focusArea: "Mental Wellness",
                        dailyCheckins: dailyCheckins,
                        sleepHours: sleepHours,
                        mindfulnessMinutes: mindfulnessMinutes,
                        emotionalResilience: emotionalResilience,
                        healthScore: healthScore,
                        keyInsights: keyInsights,
                        identifiedNeeds: identifiedNeeds,
                        recommendedActions: actions
                    )
                    
                    // Parse Recommendations
                    var parsedSupports: [SupportPlanItem] = []
                    if let recs = json["recommendations"] as? [[String: Any]] {
                        for r in recs {
                            if let title = r["title"] as? String,
                               let icon = r["icon"] as? String {
                                let desc = r["description"] as? String
                                let related = r["related_needs"] as? [String]
                                parsedSupports.append(SupportPlanItem(title: title, icon: icon, description: desc, relatedNeeds: related))
                            }
                        }
                    }
                    self.recommendedSupports = parsedSupports
                    self.stage = .result
                }
            }
        }
        
        // Simulate analysis steps for visual feedback
        let steps = [
            (0.2, "Analyzing emotional profile..."),
            (0.4, "Evaluating sleep needs..."),
            (0.6, "Assessing stress factors..."),
            (0.8, "Structuring support plan..."),
            (1.0, "Finalizing wellness companion...")
        ]
        
        var delay: Double = 0
        for step in steps {
            delay += 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    // Only update if we are still in analyzing stage
                    if self.stage == .analyzing {
                        self.loadingProgress = step.0
                        self.loadingStageText = step.1
                    }
                }
            }
        }
    }
    
    // MARK: - Result View

    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                
                if let res = assessmentResult {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.alyaiGradient)
                        
                        Text(res.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.textPrimary)
                        
                        Text(res.summary)
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.surfacePrimary))
                    }
                    .padding(.top, 60) // Safety for dynamic island/notch
                    
                    VStack(alignment: .leading, spacing: 10) {
                    Text("Daily Wellness Plan")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(res.planExplanation)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        resultCard(title: "Daily Check-ins", value: "\(res.dailyCheckins)", icon: "checkmark.circle.fill", color: .alyaiMental)
                        resultCard(title: "Mindfulness", value: "\(res.mindfulnessMinutes)m", icon: "brain.head.profile", color: .alyaiMental)
                        resultCard(title: "Sleep Goals", value: "\(res.sleepHours)h", icon: "moon.fill", color: .indigo)
                        resultCard(title: "Resilience", value: "\(res.emotionalResilience)%", icon: "shield.fill", color: .alyaiPhysical)
                    }
                }
                .padding(.horizontal)
                
                // Key Insights
                if !res.keyInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Insights")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                        
                        ForEach(res.keyInsights, id: \.self) { insight in
                            HStack(alignment: .top) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color.accentPrimary)
                                Text(insight)
                                    .font(.subheadline)
                                    .foregroundColor(Color.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Recommendations Preview
                if !recommendedSupports.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                         Text("Recommended for You")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal)
                         
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack(spacing: 16) {
                                 ForEach(recommendedSupports) { item in
                                     VStack(alignment: .leading, spacing: 8) {
                                         HStack {
                                             Image(systemName: item.icon)
                                                 .font(.title2)
                                                 .foregroundColor(Color.accentPrimary)
                                             Spacer()
                                         }
                                         
                                         Text(item.title)
                                             .font(.headline)
                                             .foregroundColor(Color.textPrimary)
                                             .lineLimit(1)
                                         
                                         if let desc = item.description {
                                             Text(desc)
                                                 .font(.caption)
                                                 .foregroundColor(Color.textSecondary)
                                                 .lineLimit(3)
                                                 .multilineTextAlignment(.leading)
                                         }
                                         
                                         Spacer()
                                         
                                         if let needs = item.relatedNeeds, !needs.isEmpty {
                                             HStack {
                                                 ForEach(needs.prefix(1), id: \.self) { n in
                                                     Text(n)
                                                         .font(.caption2)
                                                         .padding(.horizontal, 6)
                                                         .padding(.vertical, 2)
                                                         .background(Color.surfacePrimary.opacity(0.2))
                                                         .cornerRadius(4)
                                                         .lineLimit(1)
                                                 }
                                                 if needs.count > 1 {
                                                     Text("+\(needs.count - 1)")
                                                         .font(.caption2)
                                                         .foregroundColor(.textSecondary)
                                                 }
                                             }
                                         }
                                     }
                                     .padding()
                                     .frame(width: 200, height: 160)
                                     .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfacePrimary).shadow(color: Color.shadow, radius: 4, x: 0, y: 2))
                                 }
                             }
                             .padding(.horizontal)
                             .padding(.bottom, 10)
                         }
                    }
                }
                
                // Health Score
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(.alyaiEmotional)
                    Text("Wellness Score")
                    Spacer()
                    Text("\(res.healthScore)/10").fontWeight(.bold)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfacePrimary.opacity(0.2)))
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    // Start Permission Flow
                    withAnimation { stage = .requestHealth }
                } label: {
                    Text("Continue")
                }
                .buttonStyle(AlyPrimaryButtonStyle())
                .padding()
                }
            }
        }
    }
    
    private func resultCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            Spacer()

            ZStack {
                 Circle()
                    .stroke(color.opacity(0.3), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: 0.75) // Example trim
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
            }
            .frame(width: 70, height: 70)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .frame(height: 150)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.surfacePrimary))
        .shadow(color: Color.shadow.opacity(0.12), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Create Account (Final Step 17)
    
    private var createAccountView: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Create an account")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Save your personalized plan")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Apple Button
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                    let nonce = AuthManager.shared.randomNonceString()
                    request.nonce = AuthManager.shared.sha256(nonce)
                    AuthManager.shared.currentNonce = nonce
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        AuthManager.shared.signInWithApple(authorization: authorization) { success in
                            if success {
                                if let result = assessmentResult {
                                    onComplete(answers, result, recommendedSupports)
                                }
                            }
                        }
                    case .failure(let error):
                        print("❌ [Onboarding] Apple Sign In Error: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 55)
            .cornerRadius(30)
            
            // Google Button
            Button {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    AuthManager.shared.signInWithGoogle(rootViewController: rootViewController) { success in
                        if success {
                            if let result = assessmentResult {
                                onComplete(answers, result, recommendedSupports)
                            }
                        } else {
                            // If sign in fails, maybe show an alert? 
                            // For now we just log it (AuthManager logs it).
                            // Optionally fallback or do nothing.
                        }
                    }
                }
            } label: {
                HStack {
                    Text("G")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.backgroundPrimary)
                    Text("Sign in with Google")
                }
                .font(.headline)
                .foregroundColor(.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 30).fill(Color.accentPrimary))
            }
            
            Spacer()
            
            Text("By continuing, you agree to our Terms & Privacy Policy")
                .font(.caption2)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }

    private func moveToCreateAccount() {
        stage = .createAccount
        // recommendedSupports are already populated from the analysis step
    }
    
    private func handleAssessmentError(message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

// MARK: - Custom Components

fileprivate struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...10
    var step: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let percent = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            
            ZStack(alignment: .leading) {
                // Track Background
                Capsule()
                    .fill(Color.surfacePrimary)
                    .frame(height: 8)
                
                // Active Track
                Capsule()
                    .fill(Color.accentPrimary)
                    .frame(width: max(0, width * percent), height: 8)
                
                // Knob
                Circle()
                    .fill(Color.backgroundPrimary)
                    .shadow(color: Color.shadow, radius: 4, x: 0, y: 2)
                    .frame(width: 32, height: 32)
                    .offset(x: width * percent - 16) // Center knob
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let locationX = gesture.location.x
                        let percentage = max(0, min(1, locationX / width))
                        let rawValue = range.lowerBound + Double(percentage) * (range.upperBound - range.lowerBound)
                        let steppedValue = round(rawValue / step) * step
                        self.value = steppedValue
                    }
            )
        }
        .frame(height: 32)
    }
}
