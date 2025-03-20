import SwiftUI
import RealityKit

// Enum per le unità di misura
enum MeasurementUnit: String, CaseIterable, Identifiable {
    case centimeters = "cm"
    case inches = "in"
    case feet = "ft"
    case meters = "m"
    
    var id: String { rawValue }
    
    func convert(distanceInMeters: Float) -> Float {
        switch self {
        case .centimeters:
            return distanceInMeters * 100
        case .inches:
            return distanceInMeters * 39.37
        case .feet:
            return distanceInMeters * 3.281
        case .meters:
            return distanceInMeters
        }
    }
    
    func formatDistance(_ distance: Float) -> String {
        let formattedValue = String(format: "%.2f", distance)
        return "\(formattedValue) \(self.rawValue)"
    }
}

// Classe che rappresenta un keypoint
class KeyPoint: Identifiable, ObservableObject {
    let id = UUID()
    @Published var position: SIMD3<Float>
    @Published var isSelected: Bool = false
    @Published var entity: Entity? = nil
    
    init(position: SIMD3<Float>) {
        self.position = position
    }
}

// Classe che rappresenta una misurazione tra due keypoints
class Measurement: Identifiable, ObservableObject {
    let id = UUID()
    let keypoint1: KeyPoint
    let keypoint2: KeyPoint
    @Published var lineEntity: Entity? = nil
    @Published var labelEntity: Entity? = nil
    
    init(keypoint1: KeyPoint, keypoint2: KeyPoint) {
        self.keypoint1 = keypoint1
        self.keypoint2 = keypoint2
    }
    
    func calculateDistance() -> Float {
        let dx = keypoint1.position.x - keypoint2.position.x
        let dy = keypoint1.position.y - keypoint2.position.y
        let dz = keypoint1.position.z - keypoint2.position.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}
