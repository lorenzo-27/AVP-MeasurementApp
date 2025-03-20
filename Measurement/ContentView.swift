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
            .padding()
            
            // Istruzioni
            VStack(alignment: .leading, spacing: 10) {
                Text("Istruzioni:")
                    .font(.headline)
                
                Text("• Usa il pinch per inserire un keypoint")
                Text("• Guarda un keypoint per visualizzare il menu")
                Text("• Pinch sul segmento per rimuovere una misurazione")
                Text("• Seleziona l'icona di spostamento per riposizionare un punto")
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
