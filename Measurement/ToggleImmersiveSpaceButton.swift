import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    @Binding var state: AppModel.ImmersionState
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Button {
            switch state {
            case .none:
                Task {
                    state = .immersed
                    appModel.showControlPanel = true
                    await openImmersiveSpace(id: "ImmersiveSpace")
                }
            case .immersed:
                Task {
                    state = .none
                    appModel.showControlPanel = false
                    await dismissImmersiveSpace()
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
