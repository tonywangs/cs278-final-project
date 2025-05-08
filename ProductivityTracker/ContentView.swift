import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProductivityGridView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
            SocialFeedView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
        }
    }
} 

struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
          ContentView()
              .previewDevice("iPhone 16")
      }
  }
