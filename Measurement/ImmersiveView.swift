import SwiftUI
import RealityKit
import Combine

struct ImmersiveView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var contentEntity = Entity()
    @State private var draggedKeypoint: KeyPoint? = nil
    @State private var dragStartPosition: SIMD3<Float>? = nil
    
    var body: some View {
        ZStack {
            // Vista principale AR
            RealityView { content in
                print("Setting up RealityView content")
                content.add(contentEntity)
            } update: { content in
                // Debug print per vedere quando viene aggiornata la vista
                print("Updating RealityView content - keypoints: \(appModel.keypoints.count), measurements: \(appModel.measurements.count)")
                
                // Aggiorna i keypoints
                updateKeypointEntities()
                
                // Aggiorna le misurazioni
                updateMeasurementEntities()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDrag(value: value)
                    }
                    .onEnded { _ in
                        appModel.isDragging = false
                        draggedKeypoint = nil
                        dragStartPosition = nil
                    }
            )
            .onTapGesture(count: 2) { location in
                handleDoubleTap(at: location)
            }
            
            // Control Panel 2D - diverso approccio per il posizionamento
            ControlPanel()
        }
        .onChange(of: appModel.showControlPanel) { newValue in
            print("showControlPanel changed to: \(newValue)")
        }
    }
    
    // Struttura separata per il pannello di controllo
    struct ControlPanel: View {
        @EnvironmentObject var appModel: AppModel
        
        var body: some View {
            VStack {
                Spacer()
                
                if appModel.showControlPanel {
                    Button(action: {
                        print("Add Keypoint button tapped")
                        addNewKeypoint()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Aggiungi punto")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom))
                    .id("controlPanel-\(appModel.showControlPanel)")
                    .onAppear {
                        print("Control panel appeared")
                    }
                }
            }
        }
        
        func addNewKeypoint() {
            // Posizione di default davanti all'utente
            let defaultPosition = SIMD3<Float>(0, 0, -0.5)
            appModel.createKeypoint(at: defaultPosition)
        }
    }
    
    private func addNewKeypoint() {
        // Posizione di default davanti all'utente
        let defaultPosition = SIMD3<Float>(0, 0, -0.5)
        appModel.createKeypoint(at: defaultPosition)
    }
    
    private func handleDrag(value: DragGesture.Value) {
        // Se non abbiamo ancora un keypoint da trascinare, facciamo un hit test
        if draggedKeypoint == nil && !appModel.isDragging {
            print("Inizio drag, cercando keypoint vicino")
            // Implementa qui la logica di hit test con ARKit o RealityKit
            // Per ora simulo un hit test trovando il keypoint più vicino
            let nearestKeypoint = findNearestKeypoint(to: value.location)
            
            if let keypoint = nearestKeypoint {
                print("Keypoint trovato per drag: \(keypoint.id)")
                draggedKeypoint = keypoint
                dragStartPosition = keypoint.position
                appModel.selectedKeypoint = keypoint
                appModel.isDragging = true
            }
        }
        
        // Se stiamo trascinando un keypoint, aggiorna la sua posizione
        if let keypoint = draggedKeypoint, appModel.isDragging {
            // Calcoliamo il movimento in 3D basato sul drag 2D
            let dragDelta = SIMD3<Float>(
                Float(value.translation.width) * 0.01,
                Float(-value.translation.height) * 0.01,
                0 // Manteniamo la stessa profondità per semplicità
            )
            
            if let startPosition = dragStartPosition {
                let newPosition = startPosition + dragDelta
                appModel.updateKeypointPosition(keypoint, to: newPosition)
            }
        }
    }
    
    private func handleDoubleTap(at location: CGPoint) {
        print("Double tap rilevato a \(location)")
        // Implementa un hit test per trovare cosa è stato toccato
        // Simulo un hit test trovando l'entità più vicina
        if let tappedKeypoint = findNearestKeypoint(to: location) {
            print("Doppio tap su keypoint: \(tappedKeypoint.id)")
            // Elimina il keypoint
            appModel.removeKeypoint(tappedKeypoint)
        } else if let tappedMeasurement = findNearestMeasurement(to: location) {
            print("Doppio tap su measurement: \(tappedMeasurement.id)")
            // Elimina la misurazione
            appModel.removeMeasurement(tappedMeasurement)
        }
    }
    
    private func findNearestKeypoint(to location: CGPoint) -> KeyPoint? {
        // In una implementazione reale, dovresti usare un vero hit test con ARKit o RealityKit
        if !appModel.keypoints.isEmpty {
            return appModel.keypoints.randomElement()
        }
        return nil
    }
    
    private func findNearestMeasurement(to location: CGPoint) -> Measurement? {
        // In una implementazione reale, dovresti usare un vero hit test con ARKit o RealityKit
        if !appModel.measurements.isEmpty {
            return appModel.measurements.randomElement()
        }
        return nil
    }
    
    private func updateKeypointEntities() {
        // Rimuovi entità obsolete
        for entity in contentEntity.children where entity.name.hasPrefix("keypoint_") {
            let keypointID = String(entity.name.dropFirst("keypoint_".count))
            if !appModel.keypoints.contains(where: { $0.id.uuidString == keypointID }) {
                entity.removeFromParent()
            }
        }
        
        // Aggiorna o crea nuove entità per i keypoints
        for keypoint in appModel.keypoints {
            if let entity = contentEntity.findEntity(named: "keypoint_\(keypoint.id.uuidString)") {
                // Aggiorna la posizione
                entity.position = keypoint.position
                
                // Aggiorna l'aspetto in base allo stato di selezione o drag
                if let modelEntity = entity as? ModelEntity {
                    var material = PhysicallyBasedMaterial()
                    if appModel.isDragging && appModel.selectedKeypoint?.id == keypoint.id {
                        material.baseColor = .init(tint: .red, texture: nil)
                    } else {
                        material.baseColor = .init(tint: .blue, texture: nil)
                    }
                    modelEntity.model?.materials = [material]
                }
            } else {
                print("Creazione nuova entità per keypoint \(keypoint.id)")
                // Crea una nuova entità per il keypoint
                let sphere = ModelEntity(
                    mesh: .generateSphere(radius: 0.02),
                    materials: [SimpleMaterial(color: .blue, isMetallic: false)]
                )
                sphere.name = "keypoint_\(keypoint.id.uuidString)"
                sphere.position = keypoint.position
                contentEntity.addChild(sphere)
                keypoint.entity = sphere
                
                // Aggiungi un componente di collisione per l'interazione
                sphere.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.03)])
            }
        }
    }
    
    private func updateMeasurementEntities() {
        // Rimuovi entità obsolete
        for entity in contentEntity.children where entity.name.hasPrefix("measurement_") {
            let measurementID = String(entity.name.dropFirst("measurement_".count))
            if !appModel.measurements.contains(where: { $0.id.uuidString == measurementID }) {
                entity.removeFromParent()
            }
        }
        
        // Aggiorna o crea nuove entità per le misurazioni
        for measurement in appModel.measurements {
            let measurementID = "measurement_\(measurement.id.uuidString)"
            
            if let entity = contentEntity.findEntity(named: measurementID) {
                // Aggiorna la linea e l'etichetta
                updateMeasurementLine(entity, for: measurement)
            } else {
                print("Creazione nuova entità per misurazione \(measurement.id)")
                // Crea una nuova entità per la misurazione
                let measurementEntity = Entity()
                measurementEntity.name = measurementID
                contentEntity.addChild(measurementEntity)
                
                // Aggiungi la linea
                let lineEntity = createLineEntity(for: measurement)
                measurementEntity.addChild(lineEntity)
                measurement.lineEntity = lineEntity
                
                // Aggiungi l'etichetta con la misura
                let labelEntity = createLabelEntity(for: measurement)
                measurementEntity.addChild(labelEntity)
                measurement.labelEntity = labelEntity
            }
        }
    }
    
    private func createLineEntity(for measurement: Measurement) -> Entity {
        // Crea una linea tra i due keypoints
        let start = measurement.keypoint1.position
        let end = measurement.keypoint2.position
        
        // Calcola la lunghezza e l'orientamento della linea
        let distance = length(end - start)
        
        // Crea una semplice linea utilizzando un cilindro sottile
        let lineEntity = ModelEntity(
            mesh: .generateCylinder(height: distance, radius: 0.003),
            materials: [SimpleMaterial(color: .gray, isMetallic: false)]
        )
        
        // Posiziona e orienta la linea
        lineEntity.position = (start + end) / 2
        lineEntity.look(at: end, from: start, upVector: [0, 1, 0], relativeTo: nil)
        
        // Aggiungi componente di collisione per l'interazione
        lineEntity.collision = CollisionComponent(shapes: [.generateBox(size: [0.01, 0.01, distance])])
        
        return lineEntity
    }
    
    private func createLabelEntity(for measurement: Measurement) -> Entity {
        // Crea un'etichetta per mostrare la misura
        let distance = measurement.calculateDistance()
        let formattedDistance = appModel.selectedMeasurementUnit.formatDistance(
            appModel.selectedMeasurementUnit.convert(distanceInMeters: distance)
        )
        
        // Creazione di un'entità box come placeholder per l'etichetta di testo
        let labelEntity = ModelEntity(
            mesh: .generateBox(size: [0.1, 0.05, 0.01]),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        
        labelEntity.position = (measurement.keypoint1.position + measurement.keypoint2.position) / 2
        labelEntity.position.y += 0.05 // Posiziona l'etichetta sopra la linea
        
        return labelEntity
    }
    
    private func updateMeasurementLine(_ entity: Entity, for measurement: Measurement) {
        // Cerca la linea tra i figli dell'entità di misurazione
        let lineEntities = entity.children.filter { $0 is ModelEntity }
        
        if let lineEntity = lineEntities.first {
            let start = measurement.keypoint1.position
            let end = measurement.keypoint2.position
            
            // Aggiorna la posizione
            lineEntity.position = (start + end) / 2
            lineEntity.look(at: end, from: start, upVector: [0, 1, 0], relativeTo: nil)
            
            // Aggiorna le dimensioni
            let distance = length(end - start)
            if let modelEntity = lineEntity as? ModelEntity {
                modelEntity.model?.mesh = .generateCylinder(height: distance, radius: 0.003)
                
                // Aggiorna il componente di collisione
                modelEntity.collision = CollisionComponent(shapes: [.generateBox(size: [0.01, 0.01, distance])])
            }
        }
        
        // Aggiorna la posizione e il testo dell'etichetta
        let labelEntities = entity.children.filter { $0 != lineEntities.first }
        if let labelEntity = labelEntities.first {
            labelEntity.position = (measurement.keypoint1.position + measurement.keypoint2.position) / 2
            labelEntity.position.y += 0.05 // Posiziona l'etichetta sopra la linea
            
            // Aggiorna il testo mostrato (in un'implementazione reale, useresti un TextEntity di RealityKit)
            let distance = measurement.calculateDistance()
            let formattedDistance = appModel.selectedMeasurementUnit.formatDistance(
                appModel.selectedMeasurementUnit.convert(distanceInMeters: distance)
            )
        }
    }
}
