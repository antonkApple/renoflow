import SwiftUI

struct ContentView: View {
    @StateObject private var store = RenoFlowStore()

    var body: some View {
        NavigationStack {
            HomeView()
                .environmentObject(store)
        }
    }
}

#Preview {
    ContentView()
}
