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

        // ✅ Give coordinator references
        context.coordinator.cameraNode = cameraNode
        context.coordinator.scnView = scnView

        // ✅ Start progressive camera loop (C)
        context.coordinator.startCameraLoop()

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: CitySceneView
        var cameraNode: SCNNode?
        weak var scnView: SCNView?

        // MARK: - Camera state
        private var cameraX: Float = 0
        private var cameraZ: Float = 0
        private var currentZoom: Float = 50

        // MARK: - Targets (progressive movement)
        private var targetX: Float = 0
        private var targetZ: Float = 0
        private var targetZoom: Float = 50

        // MARK: - Limits
        private let minZoom: Float = 20
        private let maxZoom: Float = 90

        private let maxOffsetX: Float = 85
        private let maxOffsetZUp: Float = 25     // horizon direction (you said swap earlier)
        private let maxOffsetZDown: Float = 85

        // MARK: - Gesture tracking
        private var lastPanLocation: CGPoint = .zero
        private var pinchAnchorWorld = SCNVector3Zero

        // MARK: - DisplayLink (C)
        private var displayLink: CADisplayLink?
        private var lastFrameTime: CFTimeInterval = 0

        init(_ parent: CitySceneView) {
            self.parent = parent
            super.init()
        }

        deinit {
            stopCameraLoop()
        }

        // ✅ C: start / stop
        func startCameraLoop() {
            guard displayLink == nil else { return }

            // Sync targets to current camera state so it won't snap on start
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

        // ✅ C: progressive camera update tick
        @objc private func stepCamera() {
            guard let cameraNode = cameraNode else { return }

            let now = CACurrentMediaTime()
            let dt = Float(now - lastFrameTime)
            lastFrameTime = now

            // Tune this: higher = snappier, lower = floatier
            let follow: Float = 12.0
            let a = 1.0 - exp(-follow * dt)

            cameraX += (targetX - cameraX) * a
            cameraZ += (targetZ - cameraZ) * a
            currentZoom += (targetZoom - currentZoom) * a

            clampCurrent()

            cameraNode.position.x = cameraX
            cameraNode.position.z = 35 + cameraZ
            cameraNode.position.y = currentZoom
        }

        // MARK: - Gestures

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let district = parent.sceneController.districtAt(point: location, in: scnView)
            parent.onDistrictTapped(district)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView = scnView else { return }

            switch gesture.state {
            case .began:
                lastPanLocation = gesture.location(in: scnView)

                // Sync targets so pan doesn't fight smoothing
                targetX = cameraX
                targetZ = cameraZ
                targetZoom = currentZoom

            case .changed:
                let currentLocation = gesture.location(in: scnView)
                let deltaX = Float(currentLocation.x - lastPanLocation.x)
                let deltaY = Float(currentLocation.y - lastPanLocation.y)

                let panScale = currentZoom / 800.0

                // Optional aggression from speed
                let v = gesture.velocity(in: scnView)
                let speed = min(2500.0, sqrt(v.x * v.x + v.y * v.y))
                let aggression = Float(1.0 + (speed / 2500.0) * 0.8) // 1.0 → 1.8

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
                // Sync targets so pinch doesn't snap
                targetX = cameraX
                targetZ = cameraZ
                targetZoom = currentZoom

                let pinchCenter = gesture.location(in: scnView)
                pinchAnchorWorld = screenToWorld(pinchCenter, in: scnView)

                // Helps avoid weird transition if you pan right after pinch
                lastPanLocation = pinchCenter

            case .changed:
                // Incremental zoom so it doesn't "spring"
                let deltaScale = Float(gesture.scale)
                let desiredZoom = max(minZoom, min(maxZoom, targetZoom / deltaScale))
                targetZoom = desiredZoom

                // Keep anchor under fingers
                let pinchCenterNow = gesture.location(in: scnView)
                let worldNow = screenToWorld(pinchCenterNow, in: scnView)

                let dx = pinchAnchorWorld.x - worldNow.x
                let dz = pinchAnchorWorld.z - worldNow.z

                targetX += dx
                targetZ += dz

                clampTargets()

                // reset scale for incremental updates
                gesture.scale = 1.0

            default:
                break
            }
        }

        // MARK: - Clamping

        private func clampTargets() {
            targetX = max(-maxOffsetX, min(maxOffsetX, targetX))

            // If you said "swap", keep this swapped logic:
            if targetZ >= 0 {
                targetZ = min(targetZ, maxOffsetZDown)
            } else {
                targetZ = max(targetZ, -maxOffsetZUp)
            }

            targetZoom = max(minZoom, min(maxZoom, targetZoom))
        }

        private func clampCurrent() {
            cameraX = max(-maxOffsetX, min(maxOffsetX, cameraX))

            // same swap logic on current values
            if cameraZ >= 0 {
                cameraZ = min(cameraZ, maxOffsetZDown)
            } else {
                cameraZ = max(cameraZ, -maxOffsetZUp)
            }

            currentZoom = max(minZoom, min(maxZoom, currentZoom))
        }

        // MARK: - Screen -> World

        private func screenToWorld(_ screenPoint: CGPoint, in scnView: SCNView) -> SCNVector3 {
            let origin = scnView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 0))
            let far = scnView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 1))

            let dir = SCNVector3(far.x - origin.x, far.y - origin.y, far.z - origin.z)

            if dir.y != 0 {
                let t = -origin.y / dir.y
                return SCNVector3(origin.x + dir.x * t, 0, origin.z + dir.z * t)
            }

            return SCNVector3(cameraX, 0, 35 + cameraZ)
        }
    }
}
