import SceneKit
import UIKit

class USAMapController: ObservableObject {
    let scene: SCNScene
    private var usa: USA?
    private var regionNodes: [String: SCNNode] = [:]
    private var selectedRegionId: String?
    
    // Colors
    private let ideaColor = UIColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1.0)
    private let counterColor = UIColor(red: 0.9, green: 0.35, blue: 0.4, alpha: 1.0)
    private let neutralColorUSA = UIColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1.0)
    private let neutralColorCanada = UIColor(red: 0.28, green: 0.32, blue: 0.38, alpha: 1.0)
    private let neutralColorMexico = UIColor(red: 0.32, green: 0.35, blue: 0.40, alpha: 1.0)
    private let contestedColor = UIColor(red: 0.8, green: 0.65, blue: 0.3, alpha: 1.0)
    private let highlightColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
    private let oceanColor = UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0)
    private let borderColor = UIColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 1.0)
    
    init() {
        scene = SCNScene()
        setupScene()
    }
    
    private func setupScene() {
        // Ambient light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.4, alpha: 1.0)
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)
        
        // Main directional light
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
        sun.light?.intensity = 800
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowRadius = 3
        sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sun.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        scene.rootNode.addChildNode(sun)
        
        // Dark background
        scene.background.contents = UIColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0)
    }
    
    func generateMap(from usa: USA) {
        self.usa = usa
        clearMap()
        
        // Create ocean
        createOcean()
        
        // Create Canadian provinces (background - not playable but visible)
        for province in NorthAmericaMapData.canadianProvinces {
            let node = createRegionNode(
                id: province.id,
                polygons: province.polygon,
                color: neutralColorCanada,
                height: 0.06,
                isPlayable: false
            )
            scene.rootNode.addChildNode(node)
            regionNodes[province.id] = node
        }
        
        // Create Mexican states (background - not playable but visible)
        for state in NorthAmericaMapData.mexicanStates {
            let node = createRegionNode(
                id: state.id,
                polygons: state.polygon,
                color: neutralColorMexico,
                height: 0.06,
                isPlayable: false
            )
            scene.rootNode.addChildNode(node)
            regionNodes[state.id] = node
        }
        
        // Create US states (playable)
        for stateData in NorthAmericaMapData.allUSStates {
            let node = createRegionNode(
                id: stateData.id,
                polygons: stateData.polygon,
                color: neutralColorUSA,
                height: 0.12,
                isPlayable: true
            )
            scene.rootNode.addChildNode(node)
            regionNodes[stateData.id] = node
        }
        
        // Add state labels for major states
        addStateLabels()
    }
    
    private func clearMap() {
        regionNodes.values.forEach { $0.removeFromParentNode() }
        regionNodes.removeAll()
        selectedRegionId = nil
        
        scene.rootNode.childNodes.filter {
            $0.name == "ocean" || $0.name == "label" || $0.name == "highlight"
        }.forEach { $0.removeFromParentNode() }
    }
    
    private func createOcean() {
        let oceanGeo = SCNPlane(width: 200, height: 150)
        let oceanMat = SCNMaterial()
        oceanMat.diffuse.contents = oceanColor
        oceanMat.roughness.contents = 0.9
        oceanGeo.firstMaterial = oceanMat
        
        let ocean = SCNNode(geometry: oceanGeo)
        ocean.name = "ocean"
        ocean.eulerAngles.x = -.pi / 2
        ocean.position.y = -0.02
        scene.rootNode.addChildNode(ocean)
    }
    
    private func createRegionNode(id: String, polygons: [[CGPoint]], color: UIColor, height: CGFloat, isPlayable: Bool) -> SCNNode {
        let regionNode = SCNNode()
        regionNode.name = "region_\(id)"
        
        for (index, polygon) in polygons.enumerated() {
            guard polygon.count >= 3 else { continue }
            
            // Create the filled shape
            if let shapeNode = createFilledPolygon(points: polygon, color: color, height: height) {
                shapeNode.name = "shape_\(index)"
                regionNode.addChildNode(shapeNode)
            }
            
            // Create border
            let borderNode = createPolygonBorder(points: polygon)
            borderNode.name = "border_\(index)"
            regionNode.addChildNode(borderNode)
        }
        
        return regionNode
    }
    
    private func createFilledPolygon(points: [CGPoint], color: UIColor, height: CGFloat) -> SCNNode? {
        guard points.count >= 3 else { return nil }
        
        // Create a UIBezierPath from points
        let path = UIBezierPath()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.close()
        
        // Create SCNShape from path
        let shape = SCNShape(path: path, extrusionDepth: height)
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.roughness.contents = 0.7
        material.metalness.contents = 0.1
        shape.firstMaterial = material
        
        let shapeNode = SCNNode(geometry: shape)
        shapeNode.eulerAngles.x = -.pi / 2
        shapeNode.position.y = Float(height / 2)
        
        return shapeNode
    }
    
    private func createPolygonBorder(points: [CGPoint]) -> SCNNode {
        let borderNode = SCNNode()
        
        guard points.count > 1 else { return borderNode }
        
        for i in 0..<points.count {
            let p1 = points[i]
            let p2 = points[(i + 1) % points.count]
            
            let dx = Float(p2.x - p1.x)
            let dy = Float(p2.y - p1.y)
            let length = sqrt(dx * dx + dy * dy)
            
            guard length > 0.05 else { continue }
            
            let lineGeo = SCNCylinder(radius: 0.03, height: CGFloat(length))
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = borderColor
            lineGeo.firstMaterial = lineMat
            
            let line = SCNNode(geometry: lineGeo)
            
            // Position at midpoint
            let midX = Float(p1.x + p2.x) / 2
            let midY = Float(p1.y + p2.y) / 2
            line.position = SCNVector3(midX, 0.14, -midY)
            
            // Rotate to align with edge
            let angle = atan2(dy, dx)
            line.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            line.eulerAngles.y = -angle
            
            borderNode.addChildNode(line)
        }
        
        return borderNode
    }
    
    private func addStateLabels() {
        let labeledStates = ["CA", "TX", "FL", "NY", "PA", "OH", "IL", "GA", "MI", "WA",
                            "AZ", "CO", "NC", "VA", "ON", "QC", "BC", "AB"]
        
        for stateId in labeledStates {
            guard let regionNode = regionNodes[stateId] else { continue }
            
            // Find center of region
            let center = findRegionCenter(stateId)
            
            let textGeo = SCNText(string: stateId, extrusionDepth: 0.01)
            textGeo.font = UIFont.systemFont(ofSize: 0.5, weight: .bold)
            textGeo.flatness = 0.1
            
            let textMat = SCNMaterial()
            textMat.diffuse.contents = UIColor.white.withAlphaComponent(0.6)
            textGeo.firstMaterial = textMat
            
            let textNode = SCNNode(geometry: textGeo)
            textNode.name = "label"
            
            // Center the text
            let (min, max) = textNode.boundingBox
            let textWidth = max.x - min.x
            
            textNode.position = SCNVector3(
                Float(center.x) - textWidth / 2,
                0.2,
                -Float(center.y)
            )
            textNode.eulerAngles.x = -.pi / 2
            
            scene.rootNode.addChildNode(textNode)
        }
    }
    
    private func findRegionCenter(_ regionId: String) -> CGPoint {
        if let stateData = NorthAmericaMapData.allUSStates.first(where: { $0.id == regionId }) {
            return calculatePolygonCenter(stateData.polygon)
        }
        if let provinceData = NorthAmericaMapData.canadianProvinces.first(where: { $0.id == regionId }) {
            return calculatePolygonCenter(provinceData.polygon)
        }
        if let mexicoData = NorthAmericaMapData.mexicanStates.first(where: { $0.id == regionId }) {
            return calculatePolygonCenter(mexicoData.polygon)
        }
        return CGPoint.zero
    }
    
    private func calculatePolygonCenter(_ polygons: [[CGPoint]]) -> CGPoint {
        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        var totalPoints = 0
        
        for polygon in polygons {
            for point in polygon {
                totalX += point.x
                totalY += point.y
                totalPoints += 1
            }
        }
        
        guard totalPoints > 0 else { return CGPoint.zero }
        return CGPoint(x: totalX / CGFloat(totalPoints), y: totalY / CGFloat(totalPoints))
    }
    
    // MARK: - Visual Updates
    
    func updateStateVisuals() {
        guard let usa = usa else { return }
        
        for state in usa.allStates {
            guard let node = regionNodes[state.id] else { continue }
            
            let shapeNodes = node.childNodes.filter { $0.name?.starts(with: "shape") ?? false }
            let color = colorForState(state)
            
            for shapeNode in shapeNodes {
                shapeNode.geometry?.firstMaterial?.diffuse.contents = color
                
                // Glow effect for high adoption
                if state.ideaAdoptionRate > 0.3 {
                    let intensity = CGFloat(state.ideaAdoptionRate * 0.4)
                    shapeNode.geometry?.firstMaterial?.emission.contents = ideaColor.withAlphaComponent(intensity)
                } else if state.counterAdoptionRate > 0.3 {
                    let intensity = CGFloat(state.counterAdoptionRate * 0.4)
                    shapeNode.geometry?.firstMaterial?.emission.contents = counterColor.withAlphaComponent(intensity)
                } else {
                    shapeNode.geometry?.firstMaterial?.emission.contents = UIColor.black
                }
            }
            
            // Echo chamber indicator
            if state.echoChambered && node.childNode(withName: "echo", recursively: false) == nil {
                let echoNode = createEchoIndicator(for: state.id)
                echoNode.name = "echo"
                node.addChildNode(echoNode)
            }
        }
    }
    
    private func colorForState(_ state: StateRegion) -> UIColor {
        let ideaRate = CGFloat(state.ideaAdoptionRate)
        let counterRate = CGFloat(state.counterAdoptionRate)
        
        if ideaRate < 0.05 && counterRate < 0.05 {
            return neutralColorUSA
        }
        
        if ideaRate > counterRate {
            return blendColors(neutralColorUSA, ideaColor, ratio: min(0.95, ideaRate * 1.3))
        } else if counterRate > ideaRate {
            return blendColors(neutralColorUSA, counterColor, ratio: min(0.95, counterRate * 1.3))
        } else {
            let contestLevel = min(ideaRate, counterRate)
            return blendColors(neutralColorUSA, contestedColor, ratio: min(0.9, contestLevel * 2))
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
    
    private func createEchoIndicator(for regionId: String) -> SCNNode {
        let center = findRegionCenter(regionId)
        
        let ringGeo = SCNTorus(ringRadius: 0.8, pipeRadius: 0.03)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = UIColor(red: 0.5, green: 0.4, blue: 0.9, alpha: 0.7)
        ringMat.emission.contents = UIColor(red: 0.5, green: 0.4, blue: 0.9, alpha: 0.4)
        ringGeo.firstMaterial = ringMat
        
        let ring = SCNNode(geometry: ringGeo)
        ring.position = SCNVector3(Float(center.x), 0.25, -Float(center.y))
        
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3)
        ring.runAction(SCNAction.repeatForever(rotate))
        
        return ring
    }
    
    // MARK: - Selection
    
    func highlightState(_ state: StateRegion?) {
        // Remove previous highlight
        if let previousId = selectedRegionId, let previousNode = regionNodes[previousId] {
            previousNode.childNodes.filter { $0.name == "highlight" }.forEach { $0.removeFromParentNode() }
            
            // Reset border brightness
            let borderNodes = previousNode.childNodes.filter { $0.name?.starts(with: "border") ?? false }
            for borderNode in borderNodes {
                borderNode.childNodes.forEach { line in
                    line.geometry?.firstMaterial?.diffuse.contents = borderColor
                    line.geometry?.firstMaterial?.emission.contents = UIColor.black
                }
            }
        }
        
        selectedRegionId = state?.id
        
        guard let state = state, let node = regionNodes[state.id] else { return }
        
        // Create highlight ring
        let center = findRegionCenter(state.id)
        
        let ringGeo = SCNTorus(ringRadius: 1.5, pipeRadius: 0.06)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = highlightColor
        ringMat.emission.contents = highlightColor.withAlphaComponent(0.6)
        ringGeo.firstMaterial = ringMat
        
        let highlight = SCNNode(geometry: ringGeo)
        highlight.name = "highlight"
        highlight.position = SCNVector3(Float(center.x), 0.18, -Float(center.y))
        
        // Pulse animation
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 0.4),
            SCNAction.scale(to: 1.0, duration: 0.4)
        ])
        highlight.runAction(SCNAction.repeatForever(pulse))
        
        // Rotation
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4)
        highlight.runAction(SCNAction.repeatForever(rotate))
        
        node.addChildNode(highlight)
        
        // Brighten borders
        let borderNodes = node.childNodes.filter { $0.name?.starts(with: "border") ?? false }
        for borderNode in borderNodes {
            borderNode.childNodes.forEach { line in
                line.geometry?.firstMaterial?.diffuse.contents = highlightColor
                line.geometry?.firstMaterial?.emission.contents = highlightColor.withAlphaComponent(0.4)
            }
        }
    }
    
    func stateAt(point: CGPoint, in view: SCNView) -> StateRegion? {
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        
        for hit in hits {
            var node: SCNNode? = hit.node
            while node != nil {
                if let name = node?.name, name.starts(with: "region_") {
                    let regionId = String(name.dropFirst("region_".count))
                    // Only return US states (playable)
                    if NorthAmericaMapData.allUSStates.contains(where: { $0.id == regionId }) {
                        return usa?.getState(regionId)
                    }
                }
                node = node?.parent
            }
        }
        return nil
    }
}
