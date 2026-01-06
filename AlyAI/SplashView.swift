import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 1.0
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.alyBackground, Color.alyCard],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            // Zoom out animation
            withAnimation(.easeOut(duration: 1.0)) {
                scale = 1.0
            }
            
            // Fade out and complete after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
