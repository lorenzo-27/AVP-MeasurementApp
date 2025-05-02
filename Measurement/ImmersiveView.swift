import SwiftUI
import RealityKit
import Combine

struct ImmersiveView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var subscriptions = Set<AnyCancellable>()
    @State private var contentEntity = Entity()
    @State private var draggedKeypoint: KeyPoint? = nil
    @State private var dragStartPosition: SIMD3<Float>? = nil
    @State private var hitTestTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // RealityView per la visualizzazione AR
            RealityView { content in
                content.add(contentEntity)
                
                // Configurazione iniziale dello spazio AR
                setupARSession()

            } update: { content in
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
            .onTapGesture { location in
                handleSingleTap(at: location)
            }
        }
    }
    
    private func setupARSession() {
    }
    
    private func handleSingleTap(at location: CGPoint) {
        // TODO: mplementare l'hitTest con ARKit per posizionare i punti sulle superfici reali
        if appModel.keypoints.isEmpty {
            addNewKeypoint()
        }
    }
    
    private func addNewKeypoint() {
        // Posizione di default davanti all'utente, ad altezza degli occhi
        let defaultPosition = SIMD3<Float>(
            Float.random(in: -0.3...0.3),       // Leggera variazione sull'asse X
            1.5,                                // Altezza approssimativa degli occhi
            0 + Float.random(in: -0.2...0.2)    // Distanza confortevole con leggera variazione
        )
        appModel.createKeypoint(at: defaultPosition)
    }
    
    private func handleDrag(value: DragGesture.Value) {
        // Se non abbiamo ancora un keypoint da trascinare, facciamo un hit test
        if draggedKeypoint == nil && !appModel.isDragging {
            let nearestKeypoint = findNearestKeypoint(to: value.location)
            
            if let keypoint = nearestKeypoint {
                draggedKeypoint = keypoint
                dragStartPosition = keypoint.position
                appModel.selectedKeypoint = keypoint
                appModel.isDragging = true
            }
        }
        
        // Se stiamo trascinando un keypoint, aggiorna la sua posizione
        if let keypoint = draggedKeypoint, appModel.isDragging {
            // Miglioriamo il movimento in 3D basato sul drag 2D
            let dragDelta = SIMD3<Float>(
                Float(value.translation.width) * 0.005,
                Float(-value.translation.height) * 0.005,
                0 // Manteniamo la stessa profondità per semplicità
            )
            
            if let startPosition = dragStartPosition {
                let newPosition = startPosition + dragDelta
                appModel.updateKeypointPosition(keypoint, to: newPosition)
            }
        }
    }
    
    private func handleDoubleTap(at location: CGPoint) {
        // Implementa un hit test per trovare cosa è stato toccato
        // Simulo un hit test trovando l'entità più vicina
        if let tappedKeypoint = findNearestKeypoint(to: location) {
            // Elimina il keypoint
            appModel.removeKeypoint(tappedKeypoint)
        } else if let tappedMeasurement = findNearestMeasurement(to: location) {
            // Elimina la misurazione
            appModel.removeMeasurement(tappedMeasurement)
        }
    }
    
    private func findNearestKeypoint(to location: CGPoint) -> KeyPoint? {
        if !appModel.keypoints.isEmpty {
            return appModel.keypoints.randomElement()
        }
        return nil
    }
    
    private func findNearestMeasurement(to location: CGPoint) -> Measurement? {
        if !appModel.measurements.isEmpty {
            return appModel.measurements.randomElement()
        }
        return nil
    }
    
    private func createKeypointEntity(for keypoint: KeyPoint) -> ModelEntity {
            let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.015),
                materials: [SimpleMaterial(color: .blue, isMetallic: true)]
            )
            sphere.name = "keypoint_\(keypoint.id.uuidString)"
            sphere.position = keypoint.position
            
            let ring = ModelEntity(
                mesh: .generateSphere(radius: 2),
                materials: [SimpleMaterial(color: .white, isMetallic: false)]
            )
            ring.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
            sphere.addChild(ring)
            
            // Aggiungi un componente di collisione per l'interazione
            sphere.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.03)])
            
            return sphere
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
        let _ = appModel.selectedMeasurementUnit.formatDistance(
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
            let _ = appModel.selectedMeasurementUnit.formatDistance(
                appModel.selectedMeasurementUnit.convert(distanceInMeters: distance)
            )
        }
    }
}
