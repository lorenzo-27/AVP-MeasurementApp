import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    @Binding var state: AppModel.ImmersionState
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Button {
            Task {
                switch state {
                case .none:
                    print("Opening immersive space")
                    await openImmersiveSpace(id: "ImmersiveSpace")
                    print("Immersive space opened")
                    state = .immersed
                    
                    // Impostiamo showControlPanel dopo un breve ritardo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("Attivazione control panel")
                        appModel.setShowControlPanel(true)
                    }
                case .immersed:
                    print("Disattivazione control panel")
                    appModel.setShowControlPanel(false)
                    
                    // Dismissiamo lo spazio immersivo dopo un breve ritardo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        Task {
                            print("Closing immersive space")
                            await dismissImmersiveSpace()
                            print("Immersive space closed")
                            state = .none
                        }
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
