# AR Measurement Tool for Apple Vision Pro

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Key Components](#key-components)
    * [Models](#models)
    * [Measurement System](#measurement-system)
    * [Immersive Experience](#immersive-experience)
    * [UI Components](#ui-components)
5. [Implementation Details](#implementation-details)
    * [RealityKit Integration](#realitykit-integration)
    * [3D Interaction](#3d-interaction)
    * [Measurement Visualization](#measurement-visualization)
6. [Challenges and Limitations](#challenges-and-limitations)
7. [License](#license)

## <a name="overview"></a>1. Overview

This project is an Augmented Reality (AR) measurement tool developed for Apple Vision Pro using SwiftUI and RealityKit. It allows users to place keypoints in 3D space and measure distances between them in various units (meters, centimeters, inches, feet). The application features an immersive mixed reality experience where users can interact with the measurement points and visualize measurements in real-time.

## <a name="features"></a>2. Features

- Create and manipulate measurement points in 3D space
- Visualize distances between points with lines and labels
- Switch between multiple measurement units (m, cm, in, ft)
- Interactive control panel for adding points and managing measurements
- Intuitive gesture controls (drag to move points, double-tap to delete)
- Immersive mixed reality experience

## <a name="architecture"></a>3. Architecture

The application follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: `KeyPoint` and `Measurement` classes define the core data structures
- **ViewModels**: `AppModel` and `AVPlayerViewModel` manage the application state and business logic
- **Views**: Various SwiftUI views handle UI rendering and user interaction

The app is structured around three main window groups:
1. Main window with settings and controls
2. Immersive space for AR interactions
3. Floating control panel window for quick actions during immersion

## <a name="key-components"></a>4. Key Components

### <a name="models"></a>4.1 Models

The `KeyPoint` class represents a 3D point in space:
```swift
class KeyPoint: Identifiable, ObservableObject {
    let id = UUID()
    @Published var position: SIMD3<Float>
    @Published var isSelected: Bool = false
    var entity: Entity? = nil
    
    init(position: SIMD3<Float>) {
        self.position = position
    }
}
```

The `Measurement` class connects two keypoints and calculates the distance between them:
```swift
class Measurement: Identifiable, ObservableObject {
    let id = UUID()
    var keypoint1: KeyPoint
    var keypoint2: KeyPoint
    var lineEntity: Entity? = nil
    var labelEntity: Entity? = nil
    
    func calculateDistance() -> Float {
        return length(keypoint2.position - keypoint1.position)
    }
}
```

### <a name="measurment-system"></a>4.2 Measurement System

The application supports multiple measurement units through an enum-based system:

```swift
enum MeasurementUnit: String, Identifiable, CaseIterable {
    case meters = "m"
    case centimeters = "cm"
    case inches = "in"
    case feet = "ft"
    
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
        // Formatting logic...
    }
}
```

### <a name="immersive-experience"></a>4.3 Immersive Experience

The immersive experience is managed through the `ImmersiveView`, which:
- Creates and updates 3D entities in the RealityKit scene
- Handles gesture recognition for interaction
- Renders measurement lines and labels in 3D space

### <a name="ui-components"></a>4.4 UI Components

The app features several custom UI components:
- `ToggleImmersiveSpaceButton`: Manages transitions between normal and immersive modes
- `ControlPanelView`: Provides in-immersion controls
- `RadioButton`: Custom control for unit selection

## <a name="implementation-details"></a>5. Implementation Details

### <a name="realitykit-integration"></a>5.1 RealityKit Integration

The project extensively uses RealityKit to create an interactive 3D environment. Key points are represented as sphere entities with collision components, while measurements are visualized as cylinder entities connecting the points:

```swift
private func createKeypointEntity(for keypoint: KeyPoint) -> ModelEntity {
    let sphere = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .blue, isMetallic: true)]
    )
    sphere.name = "keypoint_\(keypoint.id.uuidString)"
    sphere.position = keypoint.position
    
    // Add collision component for interaction
    sphere.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.03)])
    
    return sphere
}
```

### <a name="3d-interaction"></a>5.2 3D Interaction

The application implements a custom drag handling system to manipulate points in 3D space:

```swift
private func handleDrag(value: DragGesture.Value) {
    // Find nearest keypoint if not already dragging
    if draggedKeypoint == nil && !appModel.isDragging {
        let nearestKeypoint = findNearestKeypoint(to: value.location)
        
        if let keypoint = nearestKeypoint {
            draggedKeypoint = keypoint
            dragStartPosition = keypoint.position
            appModel.selectedKeypoint = keypoint
            appModel.isDragging = true
        }
    }
    
    // Update position during drag
    if let keypoint = draggedKeypoint, appModel.isDragging {
        let dragDelta = SIMD3<Float>(
            Float(value.translation.width) * 0.005,
            Float(-value.translation.height) * 0.005,
            0
        )
        
        if let startPosition = dragStartPosition {
            let newPosition = startPosition + dragDelta
            appModel.updateKeypointPosition(keypoint, to: newPosition)
        }
    }
}
```

### <a name="measurment-visualization"></a>5.3 Measurement Visualization

Measurements are visualized as lines (cylinders) between points with labels showing the distance:

```swift
private func createLineEntity(for measurement: Measurement) -> Entity {
    let start = measurement.keypoint1.position
    let end = measurement.keypoint2.position
    
    let distance = length(end - start)
    
    let lineEntity = ModelEntity(
        mesh: .generateCylinder(height: distance, radius: 0.003),
        materials: [SimpleMaterial(color: .gray, isMetallic: false)]
    )
    
    lineEntity.position = (start + end) / 2
    lineEntity.look(at: end, from: start, upVector: [0, 1, 0], relativeTo: nil)
    
    return lineEntity
}
```

## <a name="challenges-and-limitations"></a>6. Challenges and Limitations

Several significant limitations were encountered during development, primarily due to restrictions with the Apple Vision Pro platform:

1. **Eye Tracking Restrictions**: The project intended to use eye tracking to position keypoints exactly where the user is looking, but this wasn't possible due to no access to the eye tracking APIs in visionOS.

2. **Spatial Mapping Challenges**: The current implementation lacks proper spatial mapping capabilities, making it difficult to place points accurately on real-world surfaces.

4. **Hit Testing Accuracy**: The current implementation uses simplified hit testing rather than proper ray casting against real-world geometry.

## License
This project is licensed under the <a href="https://github.com/lorenzo-27/AVP-MeasurementApp/blob/master/LICENSE" target="_blank">MIT</a> License.
