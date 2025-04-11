import SwiftUI
import RealityKit

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        VStack {
            Text("Strumento di Misurazione AR")
                .font(.largeTitle)
                .padding(.top)
            
            // Unità di misura
            VStack(alignment: .leading) {
                Text("Unità di misura:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(MeasurementUnit.allCases) { unit in
                    RadioButton(
                        title: unit.rawValue,
                        isSelected: appModel.selectedMeasurementUnit == unit,
                        action: {
                            appModel.selectedMeasurementUnit = unit
                            appModel.saveMeasurementUnitPreference()
                        }
                    )
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
            
            // Pulsante per cancellare tutti i keypoints
            Button(action: {
                appModel.clearAllKeypoints()
            }) {
                Label("Elimina tutti i punti", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding()
            
            // Istruzioni
            VStack(alignment: .leading, spacing: 10) {
                Text("Istruzioni:")
                    .font(.headline)
                
                Text("• Premi 'Avvia misurazione' per entrare nella modalità immersiva")
                Text("• Usa il pulsante 'Aggiungi punto' per creare nuovi punti")
                Text("• Doppio tap su un punto per eliminarlo")
                Text("• Trascina un punto per spostarlo")
                Text("• Doppio tap sulla linea per eliminarla")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
            
            Spacer()
            
            // Pulsante per attivare la modalità immersiva
            ToggleImmersiveSpaceButton(state: $appModel.immersionState)
                .padding()
        }
    }
}

struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .foregroundColor(.primary)
            }
        }
    }
}
