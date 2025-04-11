import Foundation
import RealityKit

class KeyPoint: Identifiable, ObservableObject {
    let id = UUID()
    @Published var position: SIMD3<Float>
    @Published var isSelected: Bool = false
    
    // Riferimento all'entità RealityKit
    var entity: Entity? = nil
    
    init(position: SIMD3<Float>) {
        self.position = position
    }
}

class Measurement: Identifiable, ObservableObject {
    let id = UUID()
    var keypoint1: KeyPoint
    var keypoint2: KeyPoint
    
    // Riferimenti alle entità RealityKit
    var lineEntity: Entity? = nil
    var labelEntity: Entity? = nil
    
    init(keypoint1: KeyPoint, keypoint2: KeyPoint) {
        self.keypoint1 = keypoint1
        self.keypoint2 = keypoint2
    }
    
    func calculateDistance() -> Float {
        return length(keypoint2.position - keypoint1.position)
    }
}

enum MeasurementUnit: String, Identifiable, CaseIterable {
    case meters = "m"
    case centimeters = "cm"
    case inches = "in"
    case feet = "ft"
    
    var id: String { self.rawValue }
    
    func convert(distanceInMeters: Float) -> Float {
        switch self {
        case .meters:
            return distanceInMeters
        case .centimeters:
            return distanceInMeters * 100
        case .inches:
            return distanceInMeters * 39.37
        case .feet:
            return distanceInMeters * 3.281
        }
    }
    
    func formatDistance(_ distance: Float) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        let formattedValue = formatter.string(from: NSNumber(value: distance)) ?? "\(distance)"
        
        switch self {
        case .meters:
            return "\(formattedValue) m"
        case .centimeters:
            return "\(formattedValue) cm"
        case .inches:
            return "\(formattedValue) in"
        case .feet:
            return "\(formattedValue) ft"
        }
    }
}
