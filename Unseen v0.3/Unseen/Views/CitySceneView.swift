import SwiftUI
import SceneKit

struct CitySceneView: UIViewRepresentable {
    @ObservedObject var mapController: USAMapController
    let onStateTapped: (StateRegion?) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = mapController.scene
        scnView.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)

        let cameraNode = SCNNode()
        cameraNode.name = "mainCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 50
        cameraNode.camera?.zNear = 1
        cameraNode.camera?.zFar = 150
        cameraNode.camera?.usesOrthographicProjection = false

        // Position camera to see USA map
        cameraNode.position = SCNVector3(0, 35, 18)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 3.2, 0, 0)

        scnView.pointOfView = cameraNode
        mapController.scene.rootNode.addChildNode(cameraNode)

        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isPlaying = true

        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        scnView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator,
                                                    action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)

        context.coordinator.cameraNode = cameraNode
        context.coordinator.scnView = scnView

        context.coordinator.startCameraLoop()

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: CitySceneView
        var cameraNode: SCNNode?
        weak var scnView: SCNView?

        // Camera state
        private var cameraX: Float = 0
        private var cameraZ: Float = 0
        private var currentZoom: Float = 35

        // Targets
        private var targetX: Float = 0
        private var targetZ: Float = 0
        private var targetZoom: Float = 35

        // Limits - adjusted for USA map
        private let minZoom: Float = 18
        private let maxZoom: Float = 55

        private let maxOffsetX: Float = 18
        private let maxOffsetZUp: Float = 8
        private let maxOffsetZDown: Float = 15

        // Gesture tracking
        private var lastPanLocation: CGPoint = .zero
        private var pinchAnchorWorld = SCNVector3Zero

        // DisplayLink
        private var displayLink: CADisplayLink?
        private var lastFrameTime: CFTimeInterval = 0

        init(_ parent: CitySceneView) {
            self.parent = parent
            super.init()
        }

        deinit {
            stopCameraLoop()
        }

        func startCameraLoop() {
            guard displayLink == nil else { return }

            targetX = cameraX
            targetZ = cameraZ
            targetZoom = currentZoom

            lastFrameTime = CACurrentMediaTime()
            let link = CADisplayLink(target: self, selector: #selector(stepCamera))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        func stopCameraLoop() {
            displayLink?.invalidate()
            displayLink = nil
        }

        @objc private func stepCamera() {
            guard let cameraNode = cameraNode else { return }

            let now = CACurrentMediaTime()
            let dt = Float(now - lastFrameTime)
            lastFrameTime = now

            let follow: Float = 12.0
            let a = 1.0 - exp(-follow * dt)

            cameraX += (targetX - cameraX) * a
            cameraZ += (targetZ - cameraZ) * a
            currentZoom += (targetZoom - currentZoom) * a

            clampCurrent()

            cameraNode.position.x = cameraX
            cameraNode.position.z = 18 + cameraZ
            cameraNode.position.y = currentZoom
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let state = parent.mapController.stateAt(point: location, in: scnView)
            parent.onStateTapped(state)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView = scnView else { return }

            switch gesture.state {
            case .began:
                lastPanLocation = gesture.location(in: scnView)
                targetX = cameraX
                targetZ = cameraZ
                targetZoom = currentZoom

            case .changed:
                let currentLocation = gesture.location(in: scnView)
                let deltaX = Float(currentLocation.x - lastPanLocation.x)
                let deltaY = Float(currentLocation.y - lastPanLocation.y)

                let panScale = currentZoom / 600.0

                let v = gesture.velocity(in: scnView)
                let speed = min(2500.0, sqrt(v.x * v.x + v.y * v.y))
                let aggression = Float(1.0 + (speed / 2500.0) * 0.8)

                targetX -= deltaX * panScale * aggression
                targetZ -= deltaY * panScale * aggression

                clampTargets()

                lastPanLocation = currentLocation

            default:
                break
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let scnView = scnView else { return }

            switch gesture.state {
            case .began:
                targetX = cameraX
                targetZ = cameraZ
                targetZoom = currentZoom

                let pinchCenter = gesture.location(in: scnView)
                pinchAnchorWorld = screenToWorld(pinchCenter, in: scnView)

                lastPanLocation = pinchCenter

            case .changed:
                let deltaScale = Float(gesture.scale)
                let desiredZoom = max(minZoom, min(maxZoom, targetZoom / deltaScale))
                targetZoom = desiredZoom

                let pinchCenterNow = gesture.location(in: scnView)
                let worldNow = screenToWorld(pinchCenterNow, in: scnView)

                let dx = pinchAnchorWorld.x - worldNow.x
                let dz = pinchAnchorWorld.z - worldNow.z

                targetX += dx
                targetZ += dz

                clampTargets()

                gesture.scale = 1.0

            default:
                break
            }
        }

        private func clampTargets() {
            targetX = max(-maxOffsetX, min(maxOffsetX, targetX))

            if targetZ >= 0 {
                targetZ = min(targetZ, maxOffsetZDown)
            } else {
                targetZ = max(targetZ, -maxOffsetZUp)
            }

            targetZoom = max(minZoom, min(maxZoom, targetZoom))
        }

        private func clampCurrent() {
            cameraX = max(-maxOffsetX, min(maxOffsetX, cameraX))

            if cameraZ >= 0 {
                cameraZ = min(cameraZ, maxOffsetZDown)
            } else {
                cameraZ = max(cameraZ, -maxOffsetZUp)
            }

            currentZoom = max(minZoom, min(maxZoom, currentZoom))
        }

        private func screenToWorld(_ screenPoint: CGPoint, in scnView: SCNView) -> SCNVector3 {
            let origin = scnView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 0))
            let far = scnView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 1))

            let dir = SCNVector3(far.x - origin.x, far.y - origin.y, far.z - origin.z)

            if dir.y != 0 {
                let t = -origin.y / dir.y
                return SCNVector3(origin.x + dir.x * t, 0, origin.z + dir.z * t)
            }

            return SCNVector3(cameraX, 0, 18 + cameraZ)
        }
    }
}
