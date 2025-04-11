import SwiftUI
import RealityKit
import Combine

@MainActor
class AppModel: ObservableObject {
    @Published var immersionState: ImmersionState = .none
    @Published var keypoints: [KeyPoint] = []
    @Published var measurements: [Measurement] = []
    @Published var selectedMeasurementUnit: MeasurementUnit = .centimeters
    @Published var showControlPanel: Bool = false
    
    // Proprietà per la gestione del drag
    @Published var isDragging: Bool = false
    @Published var selectedKeypoint: KeyPoint? = nil
    
    // Proprietà per la gestione della finestra di controllo
    @Published var controlPanalePresented: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Carica l'ultima unità di misura utilizzata
        if let savedUnitString = UserDefaults.standard.string(forKey: "LastUsedMeasurementUnit"),
           let savedUnit = MeasurementUnit(rawValue: savedUnitString) {
            selectedMeasurementUnit = savedUnit
        }
    }
    
    enum ImmersionState {
        case none
        case immersed
    }
    
    func toggleImmersion() {
        switch immersionState {
        case .none:
            immersionState = .immersed
            showControlPanel = true
        case .immersed:
            immersionState = .none
            showControlPanel = false
        }
    }
    
    func addNewKeypoint() {
        let defaultPosition = SIMD3<Float>(0, 1.5, -0.7) // Ad altezza degli occhi e a distanza adeguata
        createKeypoint(at: defaultPosition)
    }
    
    func createKeypoint(at position: SIMD3<Float>) {
        let keypoint = KeyPoint(position: position)
        keypoints.append(keypoint)
        
        // Se ci sono almeno due keypoint, crea una misurazione tra gli ultimi due
        if keypoints.count >= 2 {
            let lastIndex = keypoints.count - 1
            createMeasurement(between: keypoints[lastIndex - 1], and: keypoints[lastIndex])
        }
    }
    
    func removeKeypoint(_ keypoint: KeyPoint) {
        // Rimuovi prima tutte le misurazioni associate
        measurements.removeAll { measurement in
            return measurement.keypoint1.id == keypoint.id || measurement.keypoint2.id == keypoint.id
        }
        
        // Poi rimuovi il keypoint
        keypoints.removeAll { $0.id == keypoint.id }
    }
    
    func createMeasurement(between keypoint1: KeyPoint, and keypoint2: KeyPoint) {
        // Verifica che non esista già una misurazione tra questi due keypoints
        let exists = measurements.contains { measurement in
            (measurement.keypoint1.id == keypoint1.id && measurement.keypoint2.id == keypoint2.id) ||
            (measurement.keypoint1.id == keypoint2.id && measurement.keypoint2.id == keypoint1.id)
        }
        
        if !exists {
            let measurement = Measurement(keypoint1: keypoint1, keypoint2: keypoint2)
            measurements.append(measurement)
        }
    }
    
    func removeMeasurement(_ measurement: Measurement) {
        measurements.removeAll { $0.id == measurement.id }
    }
    
    func clearAllKeypoints() {
        measurements.removeAll()
        keypoints.removeAll()
    }
    
    func saveMeasurementUnitPreference() {
        UserDefaults.standard.set(selectedMeasurementUnit.rawValue, forKey: "LastUsedMeasurementUnit")
    }
    
    func updateKeypointPosition(_ keypoint: KeyPoint, to newPosition: SIMD3<Float>) {
        if let index = keypoints.firstIndex(where: { $0.id == keypoint.id }) {
            keypoints[index].position = newPosition
        }
    }
}
