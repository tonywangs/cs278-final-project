import SwiftUI

struct LandingView: View {
    var onStart: () -> Void
    @State private var rotation: Double = 0
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Text("hourglass")
                    .font(.custom("Georgia-Bold", size: 40))
                    .foregroundColor(Theme.logoColor)
                    .padding(.bottom, 20)
                Image(systemName: "hourglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))
                    .foregroundColor(Theme.logoColor)
                    .onAppear {
                        animateHourglass()
                    }
                Spacer()
                if showButton {
                    Button(action: onStart) {
                        Text("Start")
                            .font(.custom("Georgia-Bold", size: 22))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Theme.darkAccentColor)
                            .cornerRadius(12)
                    }
                }
                Spacer()
            }
        }
    }
    
    private func animateHourglass() {
        Task {
            for _ in 0..<2 {
                withAnimation(.easeInOut(duration: 0.7)) {
                    rotation += 180
                }
                try? await Task.sleep(nanoseconds: 900_000_000) // 0.9s pause
            }
            showButton = true
        }
    }
} 
