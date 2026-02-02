import SceneKit
import UIKit

class USAMapController: ObservableObject {
    let scene: SCNScene
    private var usa: USA?
    private var stateNodes: [String: SCNNode] = [:]
    
    // Map dimensions (normalized coordinates will be scaled to this)
    private let mapWidth: Float = 40.0
    private let mapHeight: Float = 25.0
    
    // Colors
    private let ideaColor = UIColor(red: 0.3, green: 0.7, blue: 0.5, alpha: 1.0)
    private let counterColor = UIColor(red: 0.75, green: 0.35, blue: 0.4, alpha: 1.0)
    private let neutralColor = UIColor(red: 0.6, green: 0.62, blue: 0.65, alpha: 1.0)
    private let contestedColor = UIColor(red: 0.7, green: 0.6, blue: 0.4, alpha: 1.0)
    private let waterColor = UIColor(red: 0.25, green: 0.4, blue: 0.6, alpha: 1.0)
    
    init() {
        scene = SCNScene()
        setupScene()
    }
    
    private func setupScene() {
        // Ambient light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.5, alpha: 1.0)
        ambient.light?.intensity = 600
        scene.rootNode.addChildNode(ambient)
        
        // Main directional light
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
        sun.light?.intensity = 900
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowRadius = 3
        sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sun.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        scene.rootNode.addChildNode(sun)
        
        // Sky blue background
        scene.background.contents = UIColor(red: 0.6, green: 0.75, blue: 0.88, alpha: 1.0)
    }
    
    func generateMap(from usa: USA) {
        self.usa = usa
        clearMap()
        
        // Create water/ocean backdrop
        createOceanBackdrop()
        
        // Create each state
        for state in usa.allStates {
            let node = createStateNode(state)
            scene.rootNode.addChildNode(node)
            stateNodes[state.id] = node
        }
        
        // Add state labels for major states
        addStateLabels()
        
        // Add decorative elements
        addMapDecorations()
    }
    
    private func clearMap() {
        stateNodes.values.forEach { $0.removeFromParentNode() }
        stateNodes.removeAll()
        scene.rootNode.childNodes.filter {
            $0.name == "ocean" || $0.name == "label" || $0.name == "decoration"
        }.forEach { $0.removeFromParentNode() }
    }
    
    private func createOceanBackdrop() {
        let oceanGeo = SCNPlane(width: CGFloat(mapWidth * 1.5), height: CGFloat(mapHeight * 1.5))
        let oceanMat = SCNMaterial()
        oceanMat.diffuse.contents = waterColor
        oceanMat.roughness.contents = 0.4
        oceanGeo.firstMaterial = oceanMat
        
        let ocean = SCNNode(geometry: oceanGeo)
        ocean.name = "ocean"
        ocean.eulerAngles.x = -.pi / 2
        ocean.position.y = -0.1
        scene.rootNode.addChildNode(ocean)
    }
    
    private func createStateNode(_ state: StateRegion) -> SCNNode {
        let node = SCNNode()
        node.name = "state_\(state.id)"
        
        // Convert normalized coordinates to world position
        let x = (state.stateData.centerX - 0.5) * mapWidth
        let z = (0.5 - state.stateData.centerY) * mapHeight  // Flip Y for SceneKit
        node.position = SCNVector3(x, 0, z)
        
        // State size based on population (with limits)
        let baseSize = sqrt(Float(state.stateData.population) / 5000000.0)
        let size = max(0.8, min(3.0, baseSize))
        
        // Create state shape (rounded hexagon-ish)
        let stateShape = createStateShape(size: size, type: state.stateData.type)
        stateShape.name = "shape"
        node.addChildNode(stateShape)
        
        // Add capitol/city indicator for urban states
        if state.stateData.type == .urban || state.stateData.population > 10000000 {
            let capitol = createCapitolIndicator()
            capitol.position.y = 0.3
            node.addChildNode(capitol)
        }
        
        return node
    }
    
    private func createStateShape(size: Float, type: USState.StateType) -> SCNNode {
        let node = SCNNode()
        
        // Main body - slightly extruded rounded shape
        let height: Float = 0.25
        
        // Use different shapes for visual variety
        let bodyGeo: SCNGeometry
        switch type {
        case .urban:
            // Circular for urban
            bodyGeo = SCNCylinder(radius: CGFloat(size * 0.5), height: CGFloat(height))
        case .rural:
            // Square-ish for rural
            bodyGeo = SCNBox(width: CGFloat(size * 0.9), height: CGFloat(height), length: CGFloat(size * 0.9), chamferRadius: CGFloat(size * 0.1))
        case .suburban:
            // Rounded rectangle
            bodyGeo = SCNBox(width: CGFloat(size * 0.95), height: CGFloat(height), length: CGFloat(size * 0.8), chamferRadius: CGFloat(size * 0.15))
        case .swing:
            // Hexagonal-ish (approximated with high-segment cylinder)
            let cylinder = SCNCylinder(radius: CGFloat(size * 0.5), height: CGFloat(height))
            cylinder.radialSegmentCount = 6
            bodyGeo = cylinder
        }
        
        let bodyMat = SCNMaterial()
        bodyMat.diffuse.contents = neutralColor
        bodyMat.roughness.contents = 0.7
        bodyGeo.firstMaterial = bodyMat
        
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = height / 2
        node.addChildNode(body)
        
        // Border ring
        let borderGeo = SCNTorus(ringRadius: CGFloat(size * 0.5), pipeRadius: 0.03)
        let borderMat = SCNMaterial()
        borderMat.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
        borderGeo.firstMaterial = borderMat
        
        let border = SCNNode(geometry: borderGeo)
        border.position.y = height + 0.02
        border.name = "border"
        node.addChildNode(border)
        
        return node
    }
    
    private func createCapitolIndicator() -> SCNNode {
        let node = SCNNode()
        
        // Small building shape
        let buildingGeo = SCNBox(width: 0.15, height: 0.25, length: 0.15, chamferRadius: 0.02)
        let buildingMat = SCNMaterial()
        buildingMat.diffuse.contents = UIColor(white: 0.85, alpha: 1.0)
        buildingGeo.firstMaterial = buildingMat
        
        let building = SCNNode(geometry: buildingGeo)
        building.position.y = 0.125
        node.addChildNode(building)
        
        // Dome
        let domeGeo = SCNSphere(radius: 0.08)
        domeGeo.firstMaterial = buildingMat
        let dome = SCNNode(geometry: domeGeo)
        dome.position.y = 0.28
        dome.scale = SCNVector3(1, 0.6, 1)
        node.addChildNode(dome)
        
        return node
    }
    
    private func addStateLabels() {
        // Only label the biggest/most important states
        let labeledStates = ["CA", "TX", "FL", "NY", "PA", "OH", "IL", "GA", "MI", "WA"]
        
        for stateId in labeledStates {
            guard let stateNode = stateNodes[stateId],
                  let _ = usa?.getState(stateId) else { continue }
            
            let textGeo = SCNText(string: stateId, extrusionDepth: 0.02)
            textGeo.font = UIFont.systemFont(ofSize: 0.3, weight: .medium)
            textGeo.flatness = 0.1
            
            let textMat = SCNMaterial()
            textMat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
            textGeo.firstMaterial = textMat
            
            let textNode = SCNNode(geometry: textGeo)
            textNode.name = "label"
            
            // Center the text
            let (min, max) = textNode.boundingBox
            let dx = (max.x - min.x) / 2
            textNode.position = SCNVector3(-dx, 0.35, 0)
            textNode.eulerAngles.x = -.pi / 2
            
            stateNode.addChildNode(textNode)
        }
    }
    
    private func addMapDecorations() {
        // Add some "waves" in the ocean areas
        let wavePositions: [(Float, Float)] = [
            (-18, -8), (-18, 5), (18, -5), (18, 8),
            (-15, -12), (15, -12), (0, -13)
        ]
        
        for (x, z) in wavePositions {
            let wave = createWaveDecoration()
            wave.position = SCNVector3(x, -0.05, z)
            wave.name = "decoration"
            scene.rootNode.addChildNode(wave)
        }
    }
    
    private func createWaveDecoration() -> SCNNode {
        let node = SCNNode()
        
        for i in 0..<3 {
            let waveGeo = SCNTorus(ringRadius: CGFloat(0.8 + Float(i) * 0.3), pipeRadius: 0.02)
            let waveMat = SCNMaterial()
            waveMat.diffuse.contents = UIColor(red: 0.35, green: 0.5, blue: 0.7, alpha: 0.5)
            waveGeo.firstMaterial = waveMat
            
            let wave = SCNNode(geometry: waveGeo)
            wave.eulerAngles.x = .pi / 2
            wave.scale = SCNVector3(1, 0.5, 1)
            node.addChildNode(wave)
        }
        
        // Gentle animation
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 2.0),
            SCNAction.scale(to: 1.0, duration: 2.0)
        ])
        node.runAction(SCNAction.repeatForever(pulse))
        
        return node
    }
    
    // MARK: - Visual Updates
    
    func updateStateVisuals() {
        guard let usa = usa else { return }
        
        for state in usa.allStates {
            guard let node = stateNodes[state.id],
                  let shapeNode = node.childNode(withName: "shape", recursively: false) else { continue }
            
            // Get the main body (first child of shape)
            guard let body = shapeNode.childNodes.first else { continue }
            
            // Calculate color based on adoption
            let color = colorForState(state)
            body.geometry?.firstMaterial?.diffuse.contents = color
            
            // Pulse effect for high adoption states
            if state.ideaAdoptionRate > 0.5 || state.counterAdoptionRate > 0.5 {
                if shapeNode.action(forKey: "pulse") == nil {
                    let pulse = SCNAction.sequence([
                        SCNAction.scale(to: 1.08, duration: 0.5),
                        SCNAction.scale(to: 1.0, duration: 0.5)
                    ])
                    shapeNode.runAction(SCNAction.repeatForever(pulse), forKey: "pulse")
                }
            } else {
                shapeNode.removeAction(forKey: "pulse")
                shapeNode.scale = SCNVector3(1, 1, 1)
            }
            
            // Glow for high unrest
            if state.socialUnrest > 0.5 {
                body.geometry?.firstMaterial?.emission.contents = UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: CGFloat(state.socialUnrest * 0.4))
            } else {
                body.geometry?.firstMaterial?.emission.contents = UIColor.black
            }
            
            // Echo chamber indicator
            if state.echoChambered {
                if node.childNode(withName: "echo", recursively: false) == nil {
                    let echoRing = createEchoIndicator(size: sqrt(Float(state.stateData.population) / 5000000.0))
                    echoRing.name = "echo"
                    node.addChildNode(echoRing)
                }
            }
            
            // Update border color based on state
            if let border = shapeNode.childNode(withName: "border", recursively: false) {
                let borderColor: UIColor
                if state.ideaAdoptionRate > 0.6 {
                    borderColor = ideaColor
                } else if state.counterAdoptionRate > 0.6 {
                    borderColor = counterColor
                } else if state.ideaAdoptionRate > 0.2 && state.counterAdoptionRate > 0.2 {
                    borderColor = contestedColor
                } else {
                    borderColor = UIColor(white: 0.3, alpha: 1.0)
                }
                border.geometry?.firstMaterial?.diffuse.contents = borderColor
            }
        }
    }
    
    private func colorForState(_ state: StateRegion) -> UIColor {
        let ideaRate = CGFloat(state.ideaAdoptionRate)
        let counterRate = CGFloat(state.counterAdoptionRate)
        
        if ideaRate < 0.05 && counterRate < 0.05 {
            return neutralColor
        }
        
        if ideaRate > counterRate {
            return blendColors(neutralColor, ideaColor, ratio: min(0.9, ideaRate * 1.2))
        } else if counterRate > ideaRate {
            return blendColors(neutralColor, counterColor, ratio: min(0.9, counterRate * 1.2))
        } else {
            // Contested - blend toward yellow/orange
            let contestLevel = min(ideaRate, counterRate)
            return blendColors(neutralColor, contestedColor, ratio: min(0.8, contestLevel * 2))
        }
    }
    
    private func blendColors(_ c1: UIColor, _ c2: UIColor, ratio: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 * (1 - ratio) + r2 * ratio,
            green: g1 * (1 - ratio) + g2 * ratio,
            blue: b1 * (1 - ratio) + b2 * ratio,
            alpha: 1.0
        )
    }
    
    private func createEchoIndicator(size: Float) -> SCNNode {
        let ringGeo = SCNTorus(ringRadius: CGFloat(size * 0.6), pipeRadius: 0.025)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = UIColor(red: 0.5, green: 0.4, blue: 0.8, alpha: 0.7)
        ringMat.emission.contents = UIColor(red: 0.5, green: 0.4, blue: 0.8, alpha: 0.3)
        ringGeo.firstMaterial = ringMat
        
        let ring = SCNNode(geometry: ringGeo)
        ring.position.y = 0.35
        
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3)
        ring.runAction(SCNAction.repeatForever(rotate))
        
        return ring
    }
    
    // MARK: - Selection
    
    func highlightState(_ state: StateRegion?) {
        // Remove existing highlights
        for (_, node) in stateNodes {
            node.childNodes.filter { $0.name == "highlight" }.forEach { $0.removeFromParentNode() }
        }
        
        guard let state = state, let node = stateNodes[state.id] else { return }
        
        let size = sqrt(Float(state.stateData.population) / 5000000.0)
        let ringGeo = SCNTorus(ringRadius: CGFloat(max(0.8, min(3.0, size)) * 0.55), pipeRadius: 0.05)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        ringMat.emission.contents = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.5)
        ringGeo.firstMaterial = ringMat
        
        let ring = SCNNode(geometry: ringGeo)
        ring.name = "highlight"
        ring.position.y = 0.3
        
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 0.3),
            SCNAction.scale(to: 1.0, duration: 0.3)
        ])
        ring.runAction(SCNAction.repeatForever(pulse))
        
        node.addChildNode(ring)
    }
    
    func stateAt(point: CGPoint, in view: SCNView) -> StateRegion? {
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        
        for hit in hits {
            var node: SCNNode? = hit.node
            while node != nil {
                if let name = node?.name, name.starts(with: "state_") {
                    let stateId = String(name.dropFirst("state_".count))
                    return usa?.getState(stateId)
                }
                node = node?.parent
            }
        }
        return nil
    }
}
