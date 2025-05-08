import SwiftUI

struct ContentView: View {
    @State private var showLanding = true
    
    var body: some View {
        if showLanding {
            LandingView(onStart: { withAnimation { showLanding = false } })
        } else {
            TabView {
                SocialFeedView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2")
                    }
                ProductivityGridView()
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }
            }
            .background(Theme.parchment.ignoresSafeArea())
            .environment(\.font, .custom("Georgia", size: 18))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
          ContentView()
              .previewDevice("iPhone 16")
      }
  }
 