import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Pannello di Controllo")
                .font(.headline)
                .padding(.top)
            
            Button(action: {
                appModel.addNewKeypoint()
            }) {
                Label("Aggiungi punto", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
            
        }
    }
}
