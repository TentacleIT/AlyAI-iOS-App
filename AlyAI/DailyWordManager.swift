import Foundation

struct DailyWordManager {
    static let shared = DailyWordManager()
    
    private let templates = [
        "Remember, {name}, every small step you take today is a victory. Trust in your resilience.",
        "You are stronger than you know, {name}. Keep moving forward.",
        "Take a deep breath, {name}. You are exactly where you need to be.",
        "{name}, your potential is limitless. Embrace the journey.",
        "Kindness to yourself is a strength, {name}. Practice it today.",
        "Focus on the present moment, {name}. It is the only one that matters.",
        "You have the power to create change, {name}. Start small.",
        "Believe in yourself, {name}. You are doing great.",
        "Every day is a fresh start, {name}. Make it count.",
        "Your well-being matters, {name}. Prioritize yourself today.",
        "{name}, you are worthy of love and happiness.",
        "Stay patient and trust the process, {name}.",
        "Your courage inspires those around you, {name}.",
        "Happiness is found in the little things, {name}. Look for them today.",
        "Let go of what you can't control, {name}. Focus on what you can.",
        "You are enough, just as you are, {name}.",
        "Embrace your uniqueness, {name}. It is your superpower.",
        "Today is a gift, {name}. Open it with gratitude.",
        "Challenges are opportunities for growth, {name}. Face them with confidence.",
        "Your peace of mind is a priority, {name}. Protect it.",
        "Smile, {name}. You radiate positive energy.",
        "Be proud of how far you've come, {name}.",
        "Listening to your inner voice leads to wisdom, {name}.",
        "Balance is key, {name}. Find time for rest and play.",
        "You are not alone, {name}. Support is always available.",
        "Celebrate your wins, no matter how small, {name}.",
        "Clarity comes with calmness, {name}. Breathe.",
        "Trust your intuition, {name}. It guides you well.",
        "Your authentic self is your best self, {name}.",
        "Hope is a powerful force, {name}. Hold onto it."
    ]
    
    func getQuote(for date: Date = Date(), userName: String) -> String {
        let nameToUse = userName.isEmpty ? "Friend" : userName
        
        // Create a stable hash based on the date
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        
        // Simple consistent pseudo-random index
        // Use a multiplier to make it jump around more if desired, but sequential is fine.
        // Let's mix it up a bit so it's not just the next one in the list every day (though that's also fine).
        let index = (day * 31 + year) % templates.count
        
        let template = templates[index]
        return template.replacingOccurrences(of: "{name}", with: nameToUse)
    }
}
