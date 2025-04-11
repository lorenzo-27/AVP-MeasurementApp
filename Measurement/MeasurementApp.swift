import SwiftUI

@main
struct MeasurementApp: App {
    @StateObject private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environmentObject(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        
        WindowGroup(id: "ControlPanel") {
            ControlPanelView()
                .environmentObject(appModel)
        }
        .defaultSize(width: 300, height: 100)
    }
}
