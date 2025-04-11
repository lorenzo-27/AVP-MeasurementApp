import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    @Binding var state: AppModel.ImmersionState
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Button {
            switch state {
            case .none:
                Task {
                    state = .immersed
                    appModel.showControlPanel = true
                    await openImmersiveSpace(id: "ImmersiveSpace")
                    openWindow(id: "ControlPanel")
                    appModel.controlPanalePresented = true
                }
            case .immersed:
                Task {
                    state = .none
                    appModel.showControlPanel = false
                    await dismissImmersiveSpace()
                    if appModel.controlPanalePresented {
                        dismissWindow(id: "ControlPanel")
                        appModel.controlPanalePresented = false
                    }
                }
            }
        } label: {
            Label(
                state == .none ? "Avvia misurazione" : "Chiudi misurazione",
                systemImage: state == .none ? "ruler" : "xmark.circle"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(state == .none ? .blue : .red)
    }
}
