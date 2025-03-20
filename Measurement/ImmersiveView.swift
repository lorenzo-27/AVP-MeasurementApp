import SwiftUI
import RealityKit
import Combine

struct ImmersiveView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var subscriptions = Set<AnyCancellable>()
    @State private var contentEntity = Entity()
    @State private var focusedKeypoint: KeyPoint? = nil
    @State private var focusedMeasurement: Measurement? = nil
    
    var body: some View {
        RealityView { content in
            content.add(contentEntity)
            
        } update: { content in
            // Aggiorna i keypoints
            updateKeypointEntities()
            
            // Aggiorna le misurazioni
            updateMeasurementEntities()
        }
        .onTapGesture {
            // Simula la creazione di un keypoint con un tap
            let randomOffset = Float.random(in: -0.3...0.3)
            let position = SIMD3<Float>(randomOffset, randomOffset, -0.5)
            appModel.createKeypoint(at: position)
            
            // Se abbiamo almeno due keypoint, creiamo una misurazione
            if appModel.keypoints.count >= 2 {
                let lastIndex = appModel.keypoints.count - 1
                appModel.createMeasurement(between: appModel.keypoints[lastIndex - 1],
                                          and: appModel.keypoints[lastIndex])
            }
        }
    }
    
    private func handleTap(at position: SIMD3<Float>) {
        // Implementa la logica per gestire i tap sulle entità
        let randomOffset = Float.random(in: -0.3...0.3)
        let newPosition = SIMD3<Float>(randomOffset, randomOffset, -0.5)
        appModel.createKeypoint(at: newPosition)
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
                
                // Aggiorna l'aspetto in base allo stato di selezione
                if let modelEntity = entity as? ModelEntity {
                    var material = PhysicallyBasedMaterial()
                    material.baseColor = keypoint.isSelected ?
                        .init(tint: .red, texture: nil) :
                        .init(tint: .blue, texture: nil)
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
        let direction = normalize(end - start)
        
        // Crea una semplice linea utilizzando un cilindro sottile
        let lineEntity = ModelEntity(
            mesh: .generateCylinder(height: distance, radius: 0.003),
            materials: [SimpleMaterial(color: .gray, isMetallic: false)]
        )
        
        // Posiziona e orienta la linea
        lineEntity.position = (start + end) / 2
        lineEntity.look(at: end, from: start, upVector: [0, 1, 0], relativeTo: nil)
        
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
            }
        }
        
        // Aggiorna la posizione dell'etichetta
        let labelEntities = entity.children.filter { $0.name.isEmpty && $0 is ModelEntity }
        if let labelEntity = labelEntities.last {
            labelEntity.position = (measurement.keypoint1.position + measurement.keypoint2.position) / 2
        }
    }
}
