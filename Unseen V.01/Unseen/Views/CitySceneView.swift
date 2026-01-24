import SwiftUI
import SceneKit

struct CitySceneView: UIViewRepresentable {
    @ObservedObject var sceneController: CitySceneController
    let onDistrictTapped: (District?) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneController.scene
        scnView.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
        
        let cameraNode = SCNNode()
        cameraNode.name = "mainCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.camera?.zNear = 1
        cameraNode.camera?.zFar = 200
        cameraNode.camera?.usesOrthographicProjection = false
        
        cameraNode.position = SCNVector3(0, 50, 35)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 3.5, 0, 0)
        
        scnView.pointOfView = cameraNode
        sceneController.scene.rootNode.addChildNode(cameraNode)
        
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isPlaying = true
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        scnView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        context.coordinator.cameraNode = cameraNode
        context.coordinator.scnView = scnView
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CitySceneView
        var cameraNode: SCNNode?
        weak var scnView: SCNView?
        
        // Camera state
        private var cameraX: Float = 0
        private var cameraZ: Float = 0
        private var currentZoom: Float = 50
        
        // Pan tracking
        private var lastPanLocation: CGPoint = .zero
        
        // Pinch tracking
        private var pinchStartZoom: Float = 50
        private var pinchStartCameraX: Float = 0
        private var pinchStartCameraZ: Float = 0
        private var pinchStartScreenPoint: CGPoint = .zero
        private var pinchStartWorldPoint: CGPoint = .zero
        
        private let minZoom: Float = 20
        private let maxZoom: Float = 90
        private let maxOffset: Float = 50
        
        init(_ parent: CitySceneView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let district = parent.sceneController.districtAt(point: location, in: scnView)
            parent.onDistrictTapped(district)
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let cameraNode = cameraNode else { return }
            
            switch gesture.state {
            case .began:
                lastPanLocation = gesture.location(in: gesture.view)
                
            case .changed:
                let currentLocation = gesture.location(in: gesture.view)
                let deltaX = Float(currentLocation.x - lastPanLocation.x)
                let deltaY = Float(currentLocation.y - lastPanLocation.y)
                
                // Scale pan speed based on zoom
                let panScale = currentZoom / 800.0
                
                cameraX -= deltaX * panScale
                cameraZ -= deltaY * panScale
                
                cameraX = max(-maxOffset, min(maxOffset, cameraX))
                cameraZ = max(-maxOffset, min(maxOffset, cameraZ))
                
                cameraNode.position.x = cameraX
                cameraNode.position.z = 35 + cameraZ
                
                lastPanLocation = currentLocation
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let cameraNode = cameraNode, let scnView = scnView else { return }
            
            switch gesture.state {
            case .began:
                pinchStartZoom = currentZoom
                pinchStartCameraX = cameraX
                pinchStartCameraZ = cameraZ
                
                // Get pinch center in screen coordinates
                pinchStartScreenPoint = gesture.location(in: scnView)
                
                // Convert to world XZ coordinates on ground plane
                let worldPoint = screenToWorld(pinchStartScreenPoint, in: scnView)
                pinchStartWorldPoint = CGPoint(x: CGFloat(worldPoint.x), y: CGFloat(worldPoint.z))
                
            case .changed:
                let scale = Float(gesture.scale)
                let newZoom = max(minZoom, min(maxZoom, pinchStartZoom / scale))
                currentZoom = newZoom
                
                // Update camera height
                cameraNode.position.y = currentZoom
                
                // Now figure out where the original world point would appear on screen
                // and adjust camera to keep it under the pinch center
                let currentPinchScreen = gesture.location(in: scnView)
                
                // How much the zoom changed
                let zoomRatio = newZoom / pinchStartZoom
                
                // The world point we want to keep stationary
                let targetWorldX = Float(pinchStartWorldPoint.x)
                let targetWorldZ = Float(pinchStartWorldPoint.y)
                
                // Calculate new camera position to keep target under finger
                // As we zoom in (zoomRatio < 1), camera moves toward target
                // As we zoom out (zoomRatio > 1), camera moves away from target
                cameraX = targetWorldX + (pinchStartCameraX - targetWorldX) * zoomRatio
                cameraZ = targetWorldZ + (pinchStartCameraZ - targetWorldZ) * zoomRatio
                
                // Also account for finger movement during pinch
                let screenDeltaX = Float(currentPinchScreen.x - pinchStartScreenPoint.x)
                let screenDeltaY = Float(currentPinchScreen.y - pinchStartScreenPoint.y)
                let panScale = currentZoom / 800.0
                cameraX -= screenDeltaX * panScale * 0.5
                cameraZ -= screenDeltaY * panScale * 0.5
                
                cameraX = max(-maxOffset, min(maxOffset, cameraX))
                cameraZ = max(-maxOffset, min(maxOffset, cameraZ))
                
                cameraNode.position.x = cameraX
                cameraNode.position.z = 35 + cameraZ
                
            default:
                break
            }
        }
        
        private func screenToWorld(_ screenPoint: CGPoint, in scnView: SCNView) -> SCNVector3 {
            // Cast ray from screen point to ground plane (y=0)
            let projectedOrigin = scnView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 0))
            let projectedFar = scnView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 1))
            
            let direction = SCNVector3(
                projectedFar.x - projectedOrigin.x,
                projectedFar.y - projectedOrigin.y,
                projectedFar.z - projectedOrigin.z
            )
            
            // Find intersection with y=0 plane
            if direction.y != 0 {
                let t = -projectedOrigin.y / direction.y
                return SCNVector3(
                    projectedOrigin.x + direction.x * t,
                    0,
                    projectedOrigin.z + direction.z * t
                )
            }
            
            return SCNVector3(cameraX, 0, cameraZ)
        }
    }
}
