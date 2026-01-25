import SceneKit
import Combine

class CitySceneController: ObservableObject {
    let scene: SCNScene
    private var city: City?
    private var cancellables = Set<AnyCancellable>()
    
    private var districtNodes: [UUID: SCNNode] = [:]
    private var personNodes: [SCNNode] = []
    private var vehicleNodes: [SCNNode] = []
    private var roadNodes: [SCNNode] = []
    private var borderNodes: [SCNNode] = []
    
    private let tileSize: Float = 12.0
    private let roadWidth: Float = 1.5
    private let maxPeoplePerDistrict = 8
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    
    private var roadSegments: [(start: SCNVector3, end: SCNVector3)] = []
    
    private var materialCache: [String: SCNMaterial] = [:]
    
    enum EmergencyType {
        case police, ambulance, fire
    }
    
    init() {
        scene = SCNScene()
        setupMaterials()
        setupScene()
    }
    
    private func setupMaterials() {
        let stoneLight = SCNMaterial()
        stoneLight.diffuse.contents = UIColor(red: 0.78, green: 0.75, blue: 0.70, alpha: 1.0)
        stoneLight.roughness.contents = 0.9
        materialCache["stoneLight"] = stoneLight
        
        let stoneMed = SCNMaterial()
        stoneMed.diffuse.contents = UIColor(red: 0.62, green: 0.60, blue: 0.57, alpha: 1.0)
        stoneMed.roughness.contents = 0.85
        materialCache["stoneMed"] = stoneMed
        
        let stoneDark = SCNMaterial()
        stoneDark.diffuse.contents = UIColor(red: 0.42, green: 0.40, blue: 0.38, alpha: 1.0)
        stoneDark.roughness.contents = 0.9
        materialCache["stoneDark"] = stoneDark
        
        let brick = SCNMaterial()
        brick.diffuse.contents = UIColor(red: 0.65, green: 0.38, blue: 0.32, alpha: 1.0)
        brick.roughness.contents = 0.8
        materialCache["brick"] = brick
        
        let brickDark = SCNMaterial()
        brickDark.diffuse.contents = UIColor(red: 0.5, green: 0.28, blue: 0.22, alpha: 1.0)
        brickDark.roughness.contents = 0.85
        materialCache["brickDark"] = brickDark
        
        let wood = SCNMaterial()
        wood.diffuse.contents = UIColor(red: 0.52, green: 0.40, blue: 0.30, alpha: 1.0)
        wood.roughness.contents = 0.7
        materialCache["wood"] = wood
        
        let woodDark = SCNMaterial()
        woodDark.diffuse.contents = UIColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0)
        woodDark.roughness.contents = 0.75
        materialCache["woodDark"] = woodDark
        
        let roofTile = SCNMaterial()
        roofTile.diffuse.contents = UIColor(red: 0.6, green: 0.32, blue: 0.25, alpha: 1.0)
        roofTile.roughness.contents = 0.75
        materialCache["roofTile"] = roofTile
        
        let roofSlate = SCNMaterial()
        roofSlate.diffuse.contents = UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1.0)
        roofSlate.roughness.contents = 0.8
        materialCache["roofSlate"] = roofSlate
        
        let roofCopper = SCNMaterial()
        roofCopper.diffuse.contents = UIColor(red: 0.4, green: 0.55, blue: 0.5, alpha: 1.0)
        roofCopper.metalness.contents = 0.3
        roofCopper.roughness.contents = 0.6
        materialCache["roofCopper"] = roofCopper
        
        let glass = SCNMaterial()
        glass.diffuse.contents = UIColor(red: 0.5, green: 0.6, blue: 0.75, alpha: 0.8)
        glass.transparency = 0.4
        glass.roughness.contents = 0.05
        glass.metalness.contents = 0.1
        materialCache["glass"] = glass
        
        let glassLit = SCNMaterial()
        glassLit.diffuse.contents = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.9)
        glassLit.emission.contents = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.3)
        materialCache["glassLit"] = glassLit
        
        let metal = SCNMaterial()
        metal.diffuse.contents = UIColor(red: 0.5, green: 0.52, blue: 0.55, alpha: 1.0)
        metal.metalness.contents = 0.6
        metal.roughness.contents = 0.4
        materialCache["metal"] = metal
        
        let metalRust = SCNMaterial()
        metalRust.diffuse.contents = UIColor(red: 0.55, green: 0.4, blue: 0.35, alpha: 1.0)
        metalRust.metalness.contents = 0.4
        metalRust.roughness.contents = 0.7
        materialCache["metalRust"] = metalRust
        
        let concrete = SCNMaterial()
        concrete.diffuse.contents = UIColor(red: 0.6, green: 0.6, blue: 0.58, alpha: 1.0)
        concrete.roughness.contents = 0.95
        materialCache["concrete"] = concrete
        
        let grass = SCNMaterial()
        grass.diffuse.contents = UIColor(red: 0.32, green: 0.52, blue: 0.32, alpha: 1.0)
        grass.roughness.contents = 0.9
        materialCache["grass"] = grass
        
        let grassDark = SCNMaterial()
        grassDark.diffuse.contents = UIColor(red: 0.22, green: 0.4, blue: 0.25, alpha: 1.0)
        grassDark.roughness.contents = 0.9
        materialCache["grassDark"] = grassDark
        
        let road = SCNMaterial()
        road.diffuse.contents = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
        road.roughness.contents = 0.95
        materialCache["road"] = road
        
        let trim = SCNMaterial()
        trim.diffuse.contents = UIColor(red: 0.9, green: 0.88, blue: 0.85, alpha: 1.0)
        trim.roughness.contents = 0.6
        materialCache["trim"] = trim
    }
    
    private func setupScene() {
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1.0)
        ambientLight.light?.intensity = 400
        scene.rootNode.addChildNode(ambientLight)
        
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        sunLight.light?.intensity = 1100
        sunLight.light?.castsShadow = true
        sunLight.light?.shadowMode = .deferred
        sunLight.light?.shadowColor = UIColor(white: 0, alpha: 0.5)
        sunLight.light?.shadowRadius = 3
        sunLight.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunLight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(sunLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.color = UIColor(red: 0.55, green: 0.6, blue: 0.75, alpha: 1.0)
        fillLight.light?.intensity = 350
        fillLight.eulerAngles = SCNVector3(-Float.pi / 4, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)
        
        scene.background.contents = UIColor(red: 0.55, green: 0.68, blue: 0.85, alpha: 1.0)
        scene.fogStartDistance = 0
        scene.fogEndDistance = 0
        scene.fogDensityExponent = 0
    }
    
    func generateCity(from city: City) {
        self.city = city
        clearCity()
        
        let offset = Float(city.gridSize) * tileSize / 2.0
        let citySize = Float(city.gridSize) * tileSize
        
        createGround(citySize: citySize, offset: offset)
        generateRoadNetwork(city: city, offset: offset)
        
        for district in city.allDistricts {
            let districtNode = createDistrictNode(district, offset: offset)
            scene.rootNode.addChildNode(districtNode)
            districtNodes[district.id] = districtNode
        }
        
        generateDistrictBorders(city: city, offset: offset)
        createBoundaryTrees(citySize: citySize, offset: offset)
        spawnInitialAgents()
        startAnimationLoop()
        subscribeToDistricts()
    }
    
    private func clearCity() {
        districtNodes.values.forEach { $0.removeFromParentNode() }
        districtNodes.removeAll()
        personNodes.forEach { $0.removeFromParentNode() }
        personNodes.removeAll()
        vehicleNodes.forEach { $0.removeFromParentNode() }
        vehicleNodes.removeAll()
        roadNodes.forEach { $0.removeFromParentNode() }
        roadNodes.removeAll()
        borderNodes.forEach { $0.removeFromParentNode() }
        borderNodes.removeAll()
        roadSegments.removeAll()
        scene.rootNode.childNodes.filter {
            $0.name == "ground" || $0.name == "borderFog" || $0.name == "groundFog" ||
            $0.name == "boundaryTree" || $0.name == "boundaryHill"
        }.forEach { $0.removeFromParentNode() }
    }
    
    private func createGround(citySize: Float, offset: Float) {
        let groundSize = citySize + 80.0
        let groundGeo = SCNPlane(width: CGFloat(groundSize), height: CGFloat(groundSize))
        groundGeo.firstMaterial = materialCache["grass"]
        let groundNode = SCNNode(geometry: groundGeo)
        groundNode.name = "ground"
        groundNode.eulerAngles.x = -.pi / 2
        groundNode.position.y = -0.02
        scene.rootNode.addChildNode(groundNode)
        
        addBorderFog(citySize: citySize, offset: offset)
    }

    private func addBorderFog(citySize: Float, offset: Float) {
        let fogColor = UIColor(red: 0.6, green: 0.7, blue: 0.85, alpha: 1.0)
        let fogWidth: Float = 30.0
        let fogHeight: Float = 15.0
        let cityHalf = citySize / 2 + 15.0  // Push fog walls further out
        
        let fogMaterial = SCNMaterial()
        fogMaterial.diffuse.contents = fogColor
        fogMaterial.transparent.contents = createFogGradientImage()
        fogMaterial.transparencyMode = .rgbZero
        fogMaterial.isDoubleSided = true
        fogMaterial.writesToDepthBuffer = false
        
        let sides: [(position: SCNVector3, rotation: Float)] = [
            (SCNVector3(0, fogHeight/2, -cityHalf - fogWidth/2), 0),
            (SCNVector3(0, fogHeight/2, cityHalf + fogWidth/2), Float.pi),
            (SCNVector3(-cityHalf - fogWidth/2, fogHeight/2, 0), Float.pi/2),
            (SCNVector3(cityHalf + fogWidth/2, fogHeight/2, 0), -Float.pi/2)
        ]
        
        for (position, rotation) in sides {
            let fogGeo = SCNPlane(width: CGFloat(citySize + fogWidth * 3), height: CGFloat(fogHeight))
            fogGeo.firstMaterial = fogMaterial
            
            let fogNode = SCNNode(geometry: fogGeo)
            fogNode.position = position
            fogNode.eulerAngles.y = rotation
            fogNode.renderingOrder = 100
            fogNode.name = "borderFog"
            scene.rootNode.addChildNode(fogNode)
        }
        
        // NO ground fog - removed entirely to prevent city coverage
    }
    
    private func createFogGradientImage() -> UIImage {
            let size = CGSize(width: 256, height: 256)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                return UIImage()
            }
            
            // Gradient: transparent at bottom (near city), opaque at top (far from city)
            let colors = [
                UIColor.black.cgColor,      // Near city: transparent
                UIColor.white.cgColor       // Far from city: opaque fog
            ]
            let locations: [CGFloat] = [0.0, 1.0]
            
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else {
                UIGraphicsEndImageContext()
                return UIImage()
            }
            
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
            
            let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()
            return image
        }
        
        private func createRadialFogGradientImage(clearRadius: CGFloat = 0.65) -> UIImage {
            let size = CGSize(width: 512, height: 512)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                return UIImage()
            }
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2
            
            // Clear in center, foggy at edges - adjustable clear radius
            let colors = [
                UIColor.black.cgColor,                          // Center: fully transparent
                UIColor.black.cgColor,                          // Keep clear for most of city
                UIColor(white: 0.3, alpha: 1.0).cgColor,        // Start fading
                UIColor(white: 0.7, alpha: 1.0).cgColor,        // More fog
                UIColor.white.cgColor                           // Edge: fully opaque fog
            ]
            let locations: [CGFloat] = [0.0, clearRadius, clearRadius + 0.15, clearRadius + 0.25, 1.0]
            
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else {
                UIGraphicsEndImageContext()
                return UIImage()
            }
            
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
            
            let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()
            return image
        }
    
    private func createBoundaryTrees(citySize: Float, offset: Float) {
        let boundaryStart = citySize / 2 + 4.0
        let treeSpacing: Float = 3.5

        let baseRows = 8

        for side in 0..<4 {
            let isHorizontal = side == 0 || side == 2
            let sign: Float = (side == 0 || side == 3) ? 1.0 : -1.0

            // ✅ DOUBLE ONLY TOP EDGE (side == 0)
            let rows = (side == 2) ? (baseRows * 2) : baseRows

            for row in 0..<rows {
                let rowOffset = boundaryStart + Float(row) * treeSpacing
                let treeCount = Int((citySize + 40) / treeSpacing)

                for i in 0..<treeCount {
                    let posAlongEdge = -citySize/2 - 20
                        + Float(i) * treeSpacing
                        + Float.random(in: -1.5...1.5)

                    let x: Float
                    let z: Float

                    if isHorizontal {
                        x = posAlongEdge
                        z = sign * (rowOffset + Float.random(in: -1.0...1.0))
                    } else {
                        x = sign * (rowOffset + Float.random(in: -1.0...1.0))
                        z = posAlongEdge
                    }

                    let tree = createBoundaryTree()
                    tree.position = SCNVector3(x, 0, z)
                    tree.name = "boundaryTree"
                    scene.rootNode.addChildNode(tree)

                    if Float.random(in: 0...1) < 0.15 {
                        let hill = createHillMound()
                        hill.position = SCNVector3(x + Float.random(in: -2...2), 0, z + Float.random(in: -2...2))
                        hill.name = "boundaryHill"
                        scene.rootNode.addChildNode(hill)
                    }
                }
            }
        }
    }


    
    private func createBoundaryTree() -> SCNNode {
        let node = SCNNode()
        
        let scale = Float.random(in: 0.8...1.5)
        let trunkHeight = Float.random(in: 0.8...1.4) * scale
        let trunkRadius: Float = 0.08 * scale
        
        let trunkGeo = SCNCylinder(radius: CGFloat(trunkRadius), height: CGFloat(trunkHeight))
        trunkGeo.firstMaterial = materialCache["wood"]
        let trunk = SCNNode(geometry: trunkGeo)
        trunk.position.y = trunkHeight / 2
        node.addChildNode(trunk)
        
        let treeType = Int.random(in: 0...2)
        
        switch treeType {
        case 0:
            for i in 0..<4 {
                let coneRadius = (0.5 - Float(i) * 0.1) * scale
                let coneHeight: Float = 0.5 * scale
                let coneGeo = SCNCone(topRadius: 0, bottomRadius: CGFloat(coneRadius), height: CGFloat(coneHeight))
                coneGeo.firstMaterial = materialCache["grassDark"]
                let cone = SCNNode(geometry: coneGeo)
                cone.position.y = trunkHeight + Float(i) * 0.35 * scale
                node.addChildNode(cone)
            }
        case 1:
            let foliageGeo = SCNSphere(radius: CGFloat(0.6 * scale))
            foliageGeo.segmentCount = 10
            foliageGeo.firstMaterial = materialCache["grass"]
            let foliage = SCNNode(geometry: foliageGeo)
            foliage.position.y = trunkHeight + 0.4 * scale
            foliage.scale = SCNVector3(1, 0.8, 1)
            node.addChildNode(foliage)
        default:
            for _ in 0..<3 {
                let radius = Float.random(in: 0.3...0.5) * scale
                let foliageGeo = SCNSphere(radius: CGFloat(radius))
                foliageGeo.segmentCount = 8
                foliageGeo.firstMaterial = [materialCache["grass"], materialCache["grassDark"]].randomElement()!
                let foliage = SCNNode(geometry: foliageGeo)
                foliage.position = SCNVector3(
                    Float.random(in: -0.2...0.2) * scale,
                    trunkHeight + Float.random(in: 0.2...0.5) * scale,
                    Float.random(in: -0.2...0.2) * scale
                )
                node.addChildNode(foliage)
            }
        }
        
        return node
    }
    
    private func createHillMound() -> SCNNode {
        let node = SCNNode()
        
        let radius = Float.random(in: 1.5...3.0)
        let height = Float.random(in: 0.3...0.8)
        
        let hillGeo = SCNSphere(radius: CGFloat(radius))
        hillGeo.segmentCount = 12
        hillGeo.firstMaterial = materialCache["grass"]
        
        let hill = SCNNode(geometry: hillGeo)
        hill.scale = SCNVector3(1, height / radius, 1)
        hill.position.y = -radius * (height / radius) * 0.3
        node.addChildNode(hill)
        
        return node
    }
    
    private func generateRoadNetwork(city: City, offset: Float) {
        for y in 0...city.gridSize {
            for x in 0...city.gridSize {
                let worldX = Float(x) * tileSize - offset
                let worldZ = Float(y) * tileSize - offset
                
                if x < city.gridSize {
                    let startPos = SCNVector3(worldX, 0.01, worldZ)
                    let endPos = SCNVector3(worldX + tileSize, 0.01, worldZ)
                    let roadNode = createRoadSegment(from: startPos, to: endPos)
                    scene.rootNode.addChildNode(roadNode)
                    roadNodes.append(roadNode)
                    roadSegments.append((start: startPos, end: endPos))
                }
                
                if y < city.gridSize {
                    let startPos = SCNVector3(worldX, 0.01, worldZ)
                    let endPos = SCNVector3(worldX, 0.01, worldZ + tileSize)
                    let roadNode = createRoadSegment(from: startPos, to: endPos)
                    scene.rootNode.addChildNode(roadNode)
                    roadNodes.append(roadNode)
                    roadSegments.append((start: startPos, end: endPos))
                }
                
                let intersection = createIntersection(at: SCNVector3(worldX, 0.02, worldZ))
                scene.rootNode.addChildNode(intersection)
                roadNodes.append(intersection)
            }
        }
    }
    
    private func createRoadSegment(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let dx = end.x - start.x
        let dz = end.z - start.z
        let length = sqrt(dx * dx + dz * dz)
        
        let roadGeo = SCNBox(width: CGFloat(length), height: 0.04, length: CGFloat(roadWidth), chamferRadius: 0)
        roadGeo.firstMaterial = materialCache["road"]
        
        let node = SCNNode(geometry: roadGeo)
        node.position = SCNVector3((start.x + end.x) / 2, 0.02, (start.z + end.z) / 2)
        
        let angle = atan2(dz, dx)
        node.eulerAngles.y = angle
        
        let dashCount = Int(length / 1.0)
        for i in 0..<dashCount {
            if i % 2 == 0 {
                let dashGeo = SCNBox(width: 0.6, height: 0.05, length: 0.06, chamferRadius: 0)
                let dashMat = SCNMaterial()
                dashMat.diffuse.contents = UIColor(red: 0.6, green: 0.6, blue: 0.5, alpha: 1.0)
                dashGeo.firstMaterial = dashMat
                let dash = SCNNode(geometry: dashGeo)
                dash.position.x = Float(i) - length/2 + 0.5
                node.addChildNode(dash)
            }
        }
        
        return node
    }
    
    private func createIntersection(at position: SCNVector3) -> SCNNode {
        let node = SCNNode()
        node.position = position
        
        let size = roadWidth + 0.3
        let baseGeo = SCNBox(width: CGFloat(size), height: 0.04, length: CGFloat(size), chamferRadius: 0)
        baseGeo.firstMaterial = materialCache["road"]
        let base = SCNNode(geometry: baseGeo)
        node.addChildNode(base)
        
        return node
    }
    private func createDetailedCivicBuilding() -> SCNNode {
        let node = SCNNode()
        
        let width = Float.random(in: 2.0...2.8)
        let depth = Float.random(in: 1.6...2.4)
        let height = Float.random(in: 2.2...3.2)
        
        let base1Geo = SCNBox(width: CGFloat(width + 0.5), height: 0.15, length: CGFloat(depth + 0.5), chamferRadius: 0)
        base1Geo.firstMaterial = materialCache["stoneDark"]
        let base1 = SCNNode(geometry: base1Geo)
        base1.position.y = 0.075
        node.addChildNode(base1)
        
        let base2Geo = SCNBox(width: CGFloat(width + 0.3), height: 0.15, length: CGFloat(depth + 0.3), chamferRadius: 0)
        base2Geo.firstMaterial = materialCache["stoneDark"]
        let base2 = SCNNode(geometry: base2Geo)
        base2.position.y = 0.225
        node.addChildNode(base2)
        
        let bodyGeo = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(depth), chamferRadius: 0)
        bodyGeo.firstMaterial = materialCache["stoneLight"]
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = height / 2 + 0.3
        node.addChildNode(body)
        
        let columnCount = Int(width / 0.5)
        let columnRadius: Float = 0.07
        for i in 0..<columnCount {
            let x = (Float(i) - Float(columnCount - 1) / 2) * (width / Float(columnCount))
            
            let colGeo = SCNCylinder(radius: CGFloat(columnRadius), height: CGFloat(height - 0.4))
            colGeo.firstMaterial = materialCache["stoneLight"]
            let col = SCNNode(geometry: colGeo)
            col.position = SCNVector3(x, height/2 + 0.3, depth/2 + 0.12)
            node.addChildNode(col)
            
            let capGeo = SCNBox(width: CGFloat(columnRadius * 3), height: 0.1, length: CGFloat(columnRadius * 3), chamferRadius: 0.01)
            capGeo.firstMaterial = materialCache["trim"]
            let cap = SCNNode(geometry: capGeo)
            cap.position = SCNVector3(x, height + 0.1, depth/2 + 0.12)
            node.addChildNode(cap)
            
            let baseGeo = SCNBox(width: CGFloat(columnRadius * 2.5), height: 0.08, length: CGFloat(columnRadius * 2.5), chamferRadius: 0)
            baseGeo.firstMaterial = materialCache["stoneDark"]
            let colBase = SCNNode(geometry: baseGeo)
            colBase.position = SCNVector3(x, 0.34, depth/2 + 0.12)
            node.addChildNode(colBase)
        }
        
        let entGeo = SCNBox(width: CGFloat(width + 0.3), height: 0.18, length: 0.25, chamferRadius: 0)
        entGeo.firstMaterial = materialCache["trim"]
        let entablature = SCNNode(geometry: entGeo)
        entablature.position = SCNVector3(0, height + 0.2, depth/2 + 0.12)
        node.addChildNode(entablature)
        
        let pedimentNode = createDetailedPediment(width: width + 0.25, height: 0.6)
        pedimentNode.position = SCNVector3(0, height + 0.4, depth/2 + 0.12)
        node.addChildNode(pedimentNode)
        
        let floors = Int(height / 1.0)
        for floor in 0..<floors {
            let y = Float(floor) * 1.0 + 0.8 + 0.3
            addDetailedWindows(to: node, width: width, depth: depth, y: y, windowStyle: .civic)
        }
        
        let doorFrameGeo = SCNBox(width: 0.55, height: 0.9, length: 0.1, chamferRadius: 0)
        doorFrameGeo.firstMaterial = materialCache["trim"]
        let doorFrame = SCNNode(geometry: doorFrameGeo)
        doorFrame.position = SCNVector3(0, 0.45 + 0.3, depth/2 + 0.04)
        node.addChildNode(doorFrame)
        
        let doorGeo = SCNBox(width: 0.45, height: 0.8, length: 0.06, chamferRadius: 0)
        doorGeo.firstMaterial = materialCache["woodDark"]
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(0, 0.4 + 0.3, depth/2 + 0.08)
        node.addChildNode(door)
        
        if Bool.random() && width > 2.2 {
            let domeGeo = SCNSphere(radius: CGFloat(min(width, depth) * 0.22))
            domeGeo.segmentCount = 24
            domeGeo.firstMaterial = materialCache["roofCopper"]
            let dome = SCNNode(geometry: domeGeo)
            dome.position.y = height + 0.7
            dome.scale = SCNVector3(1, 0.6, 1)
            node.addChildNode(dome)
            
            let domeBaseGeo = SCNCylinder(radius: CGFloat(min(width, depth) * 0.25), height: 0.15)
            domeBaseGeo.firstMaterial = materialCache["stoneDark"]
            let domeBase = SCNNode(geometry: domeBaseGeo)
            domeBase.position.y = height + 0.4
            node.addChildNode(domeBase)
        }
        
        return node
    }
    
    private func createDetailedPediment(width: Float, height: Float) -> SCNNode {
        let node = SCNNode()
        
        let triGeo = SCNBox(width: CGFloat(width), height: CGFloat(height), length: 0.12, chamferRadius: 0)
        triGeo.firstMaterial = materialCache["stoneLight"]
        let tri = SCNNode(geometry: triGeo)
        tri.scale.y = 0.7
        node.addChildNode(tri)
        
        let capGeo = SCNBox(width: CGFloat(width * 0.15), height: 0.12, length: 0.15, chamferRadius: 0.02)
        capGeo.firstMaterial = materialCache["trim"]
        let cap = SCNNode(geometry: capGeo)
        cap.position.y = height * 0.4
        node.addChildNode(cap)
        
        return node
    }
    
    enum WindowStyle {
        case residential, commercial, shopfront, civic
    }
    
    private func addDetailedWindows(to node: SCNNode, width: Float, depth: Float, y: Float, windowStyle: WindowStyle) {
        let (windowW, windowH, spacing): (Float, Float, Float)
        let windowMat: SCNMaterial?
        
        switch windowStyle {
        case .residential:
            windowW = 0.18; windowH = 0.28; spacing = 0.5
            windowMat = Bool.random() ? materialCache["glass"] : materialCache["glassLit"]
        case .commercial:
            windowW = 0.28; windowH = 0.38; spacing = 0.42
            windowMat = materialCache["glass"]
        case .shopfront:
            windowW = 0.55; windowH = 0.55; spacing = 0.65
            windowMat = materialCache["glass"]
        case .civic:
            windowW = 0.22; windowH = 0.45; spacing = 0.55
            windowMat = materialCache["glass"]
        }
        
        let windowCount = max(1, Int(width / spacing))
        
        for i in 0..<windowCount {
            let x = (Float(i) - Float(windowCount - 1) / 2) * spacing
            
            let frameGeo = SCNBox(width: CGFloat(windowW + 0.04), height: CGFloat(windowH + 0.04), length: 0.03, chamferRadius: 0)
            frameGeo.firstMaterial = materialCache["trim"]
            let frame = SCNNode(geometry: frameGeo)
            frame.position = SCNVector3(x, y, depth/2 + 0.01)
            node.addChildNode(frame)
            
            let windowGeo = SCNBox(width: CGFloat(windowW), height: CGFloat(windowH), length: 0.02, chamferRadius: 0)
            windowGeo.firstMaterial = windowMat
            let window = SCNNode(geometry: windowGeo)
            window.position = SCNVector3(x, y, depth/2 + 0.025)
            node.addChildNode(window)
            
            if windowStyle == .residential || windowStyle == .civic {
                let sillGeo = SCNBox(width: CGFloat(windowW + 0.08), height: 0.03, length: 0.06, chamferRadius: 0)
                sillGeo.firstMaterial = materialCache["stoneDark"]
                let sill = SCNNode(geometry: sillGeo)
                sill.position = SCNVector3(x, y - windowH/2 - 0.015, depth/2 + 0.04)
                node.addChildNode(sill)
            }
        }
    }
    
    private func addFoliage(to node: SCNNode, district: District, innerSize: Float) {
        let range = (innerSize / 2) - 1.2
        
        let treeCount: Int
        switch district.type {
        case .park: treeCount = Int.random(in: 8...14)
        case .residential: treeCount = Int.random(in: 3...6)
        case .civic: treeCount = Int.random(in: 1...3)
        case .commercial: treeCount = Int.random(in: 0...2)
        case .industrial: treeCount = 0
        }
        
        for _ in 0..<treeCount {
            let tree = createDetailedTree()
            tree.position = SCNVector3(Float.random(in: -range...range), 0, Float.random(in: -range...range))
            node.addChildNode(tree)
        }
        
        if district.type == .park || district.type == .residential || district.type == .civic {
            for _ in 0..<Int.random(in: 2...5) {
                let bush = createBush()
                bush.position = SCNVector3(Float.random(in: -range...range), 0, Float.random(in: -range...range))
                node.addChildNode(bush)
            }
        }
        
        if district.type != .park {
            for _ in 0..<Int.random(in: 1...2) {
                let lamp = createStreetLamp()
                let edge = Bool.random()
                lamp.position = SCNVector3(
                    edge ? Float.random(in: -range...range) : (Bool.random() ? range : -range),
                    0,
                    edge ? (Bool.random() ? range : -range) : Float.random(in: -range...range)
                )
                node.addChildNode(lamp)
            }
        }
        
        if district.type == .park {
            for _ in 0..<Int.random(in: 1...2) {
                let bench = createBench()
                bench.position = SCNVector3(Float.random(in: -range/2...range/2), 0, Float.random(in: -range/2...range/2))
                let rotations: [Float] = [0, Float.pi/2, Float.pi, Float.pi * 1.5]
                bench.eulerAngles.y = rotations.randomElement()!
                node.addChildNode(bench)
            }
        }
    }
    
    private func createDetailedTree() -> SCNNode {
        let node = SCNNode()
        
        let trunkHeight = Float.random(in: 0.5...0.9)
        let trunkRadius: Float = Float.random(in: 0.05...0.08)
        
        let trunkGeo = SCNCylinder(radius: CGFloat(trunkRadius), height: CGFloat(trunkHeight))
        trunkGeo.firstMaterial = materialCache["wood"]
        let trunk = SCNNode(geometry: trunkGeo)
        trunk.position.y = trunkHeight / 2
        node.addChildNode(trunk)
        
        let treeType = Int.random(in: 0...2)
        
        switch treeType {
        case 0:
            let foliageColors = [materialCache["grass"], materialCache["grassDark"]]
            for i in 0..<3 {
                let radius = Float.random(in: 0.35...0.55) - Float(i) * 0.1
                let foliageGeo = SCNSphere(radius: CGFloat(radius))
                foliageGeo.segmentCount = 12
                foliageGeo.firstMaterial = foliageColors.randomElement()!
                let foliage = SCNNode(geometry: foliageGeo)
                foliage.position = SCNVector3(
                    Float.random(in: -0.15...0.15),
                    trunkHeight + Float(i) * 0.25 + 0.2,
                    Float.random(in: -0.15...0.15)
                )
                node.addChildNode(foliage)
            }
        case 1:
            for i in 0..<4 {
                let coneRadius = 0.4 - Float(i) * 0.08
                let coneHeight: Float = 0.4
                let coneGeo = SCNCone(topRadius: 0, bottomRadius: CGFloat(coneRadius), height: CGFloat(coneHeight))
                coneGeo.firstMaterial = materialCache["grassDark"]
                let cone = SCNNode(geometry: coneGeo)
                cone.position.y = trunkHeight + Float(i) * 0.28 + 0.15
                node.addChildNode(cone)
            }
        default:
            let foliageGeo = SCNSphere(radius: CGFloat(Float.random(in: 0.4...0.6)))
            foliageGeo.segmentCount = 10
            foliageGeo.firstMaterial = materialCache["grass"]
            let foliage = SCNNode(geometry: foliageGeo)
            foliage.position.y = trunkHeight + 0.35
            foliage.scale = SCNVector3(1, 0.85, 1)
            node.addChildNode(foliage)
        }
        
        return node
    }
    
    private func createBush() -> SCNNode {
        let node = SCNNode()
        let size = Float.random(in: 0.2...0.4)
        
        for i in 0..<3 {
            let bushGeo = SCNSphere(radius: CGFloat(size - Float(i) * 0.05))
            bushGeo.segmentCount = 8
            bushGeo.firstMaterial = [materialCache["grass"], materialCache["grassDark"]].randomElement()!
            let bush = SCNNode(geometry: bushGeo)
            bush.position = SCNVector3(
                Float.random(in: -0.1...0.1),
                size * 0.6 + Float(i) * 0.08,
                Float.random(in: -0.1...0.1)
            )
            bush.scale = SCNVector3(1, 0.75, 1)
            node.addChildNode(bush)
        }
        
        return node
    }
    
    private func createStreetLamp() -> SCNNode {
        let node = SCNNode()
        
        let poleGeo = SCNCylinder(radius: 0.025, height: 1.3)
        poleGeo.firstMaterial = materialCache["metal"]
        let pole = SCNNode(geometry: poleGeo)
        pole.position.y = 0.65
        node.addChildNode(pole)
        
        let armGeo = SCNBox(width: 0.25, height: 0.03, length: 0.03, chamferRadius: 0)
        armGeo.firstMaterial = materialCache["metal"]
        let arm = SCNNode(geometry: armGeo)
        arm.position = SCNVector3(0.1, 1.25, 0)
        node.addChildNode(arm)
        
        let housingGeo = SCNBox(width: 0.12, height: 0.08, length: 0.08, chamferRadius: 0.01)
        housingGeo.firstMaterial = materialCache["metal"]
        let housing = SCNNode(geometry: housingGeo)
        housing.position = SCNVector3(0.22, 1.22, 0)
        node.addChildNode(housing)
        
        let bulbGeo = SCNSphere(radius: 0.045)
        let bulbMat = SCNMaterial()
        bulbMat.diffuse.contents = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        bulbMat.emission.contents = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 0.4)
        bulbGeo.firstMaterial = bulbMat
        let bulb = SCNNode(geometry: bulbGeo)
        bulb.position = SCNVector3(0.22, 1.16, 0)
        node.addChildNode(bulb)
        
        return node
    }
    
    private func createBench() -> SCNNode {
        let node = SCNNode()
        
        let seatGeo = SCNBox(width: 0.5, height: 0.04, length: 0.18, chamferRadius: 0.01)
        seatGeo.firstMaterial = materialCache["wood"]
        let seat = SCNNode(geometry: seatGeo)
        seat.position.y = 0.22
        node.addChildNode(seat)
        
        let backGeo = SCNBox(width: 0.5, height: 0.2, length: 0.03, chamferRadius: 0.01)
        backGeo.firstMaterial = materialCache["wood"]
        let back = SCNNode(geometry: backGeo)
        back.position = SCNVector3(0, 0.34, -0.08)
        back.eulerAngles.x = Float.pi * 0.08
        node.addChildNode(back)
        
        let legGeo = SCNBox(width: 0.04, height: 0.22, length: 0.15, chamferRadius: 0)
        legGeo.firstMaterial = materialCache["metal"]
        
        let leg1 = SCNNode(geometry: legGeo)
        leg1.position = SCNVector3(-0.2, 0.11, 0)
        node.addChildNode(leg1)
        
        let leg2 = SCNNode(geometry: legGeo)
        leg2.position = SCNVector3(0.2, 0.11, 0)
        node.addChildNode(leg2)
        
        return node
    }
    
    private func generateDistrictBorders(city: City, offset: Float) {
        for district in city.allDistricts {
            let centerX = Float(district.gridX) * tileSize - offset + tileSize / 2
            let centerZ = Float(district.gridY) * tileSize - offset + tileSize / 2
            let halfSize = (tileSize - roadWidth) / 2 - 0.4
            let borderColor = borderColorForType(district.type)
            
            let corners = [
                SCNVector3(centerX - halfSize, 0.03, centerZ - halfSize),
                SCNVector3(centerX + halfSize, 0.03, centerZ - halfSize),
                SCNVector3(centerX + halfSize, 0.03, centerZ + halfSize),
                SCNVector3(centerX - halfSize, 0.03, centerZ + halfSize)
            ]
            
            for i in 0..<4 {
                let border = createBorderLine(from: corners[i], to: corners[(i + 1) % 4], color: borderColor)
                border.name = "border_\(district.id)"
                scene.rootNode.addChildNode(border)
                borderNodes.append(border)
            }
        }
    }
    
    private func borderColorForType(_ type: DistrictType) -> UIColor {
        switch type {
        case .residential: return UIColor(red: 0.4, green: 0.65, blue: 0.45, alpha: 0.8)
        case .commercial: return UIColor(red: 0.5, green: 0.55, blue: 0.7, alpha: 0.8)
        case .industrial: return UIColor(red: 0.65, green: 0.5, blue: 0.4, alpha: 0.8)
        case .civic: return UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 0.8)
        case .park: return UIColor(red: 0.35, green: 0.6, blue: 0.4, alpha: 0.8)
        }
    }
    
    private func createBorderLine(from start: SCNVector3, to end: SCNVector3, color: UIColor) -> SCNNode {
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.z - start.z, 2))
        let lineGeo = SCNBox(width: CGFloat(distance), height: 0.06, length: 0.08, chamferRadius: 0)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = color.withAlphaComponent(0.25)
        lineGeo.firstMaterial = mat
        
        let node = SCNNode(geometry: lineGeo)
        node.position = SCNVector3((start.x + end.x) / 2, start.y, (start.z + end.z) / 2)
        node.eulerAngles.y = -atan2(end.z - start.z, end.x - start.x)
        return node
    }
    
    private func spawnInitialAgents() {
        guard let city = city else { return }
        for district in city.allDistricts {
            spawnPeople(count: Int(district.activityLevel * Float(maxPeoplePerDistrict)), in: district)
        }
        spawnCarsOnRoads(count: city.gridSize * 3)
    }
    
    private func spawnPeople(count: Int, in district: District) {
        guard let districtNode = districtNodes[district.id] else { return }
        let innerSize = tileSize - roadWidth - 0.6
        let range = (innerSize / 2) - 1.5
        
        for _ in 0..<count {
            let person = createPerson()
            person.position = SCNVector3(Float.random(in: -range...range), 0, Float.random(in: -range...range))
            person.name = "person_\(district.id)"
            districtNode.addChildNode(person)
            personNodes.append(person)
            startWalkingAnimation(for: person, in: district, range: range)
        }
    }
    
    private func createPerson() -> SCNNode {
        let node = SCNNode()
        let colors: [UIColor] = [
            UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0),
            UIColor(red: 0.6, green: 0.35, blue: 0.35, alpha: 1.0),
            UIColor(red: 0.35, green: 0.5, blue: 0.4, alpha: 1.0),
            UIColor(red: 0.5, green: 0.45, blue: 0.35, alpha: 1.0),
            UIColor(red: 0.55, green: 0.4, blue: 0.5, alpha: 1.0)
        ]
        
        let bodyGeo = SCNCapsule(capRadius: 0.04, height: 0.2)
        bodyGeo.firstMaterial?.diffuse.contents = colors.randomElement()!
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = 0.12
        node.addChildNode(body)
        
        let headGeo = SCNSphere(radius: 0.04)
        headGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1.0)
        let head = SCNNode(geometry: headGeo)
        head.position.y = 0.28
        node.addChildNode(head)
        
        return node
    }
    
    private func startWalkingAnimation(for person: SCNNode, in district: District, range: Float) {
        let targetX = Float.random(in: -range...range)
        let targetZ = Float.random(in: -range...range)
        let dx = targetX - person.position.x
        let dz = targetZ - person.position.z
        let distance = sqrt(dx * dx + dz * dz)
        let speed: Float = 0.4 * district.activityLevel + 0.15
        
        person.eulerAngles.y = atan2(dx, dz)
        
        let move = SCNAction.move(to: SCNVector3(targetX, 0, targetZ), duration: max(1, TimeInterval(distance / speed)))
        let pause = SCNAction.wait(duration: Double.random(in: 0.5...3.0))
        
        person.runAction(SCNAction.sequence([move, pause])) { [weak self, weak person] in
            guard let person = person else { return }
            self?.startWalkingAnimation(for: person, in: district, range: range)
        }
    }
    
    private func spawnCarsOnRoads(count: Int) {
        guard !roadSegments.isEmpty else { return }
        
        for _ in 0..<count {
            let car: SCNNode
            
            if Float.random(in: 0...1) < 0.12 {
                let types: [EmergencyType] = [.police, .ambulance, .fire]
                car = createEmergencyVehicle(type: types.randomElement()!)
                car.name = "emergency_road"
            } else {
                car = createCar()
                car.name = "car_road"
            }
            
            let segment = roadSegments.randomElement()!
            let t = Float.random(in: 0.1...0.9)
            car.position = SCNVector3(
                segment.start.x + (segment.end.x - segment.start.x) * t,
                0.06,
                segment.start.z + (segment.end.z - segment.start.z) * t
            )
            
            let dx = segment.end.x - segment.start.x
            let dz = segment.end.z - segment.start.z
            car.eulerAngles.y = atan2(dx, dz)
            
            scene.rootNode.addChildNode(car)
            vehicleNodes.append(car)
            startRoadDrivingAnimation(for: car)
        }
    }
    
    private func createCar() -> SCNNode {
        let node = SCNNode()
        let colors: [UIColor] = [
            UIColor(red: 0.65, green: 0.2, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.2, green: 0.3, blue: 0.55, alpha: 1.0),
            UIColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0),
            UIColor(red: 0.85, green: 0.85, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.2, green: 0.42, blue: 0.32, alpha: 1.0),
            UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0)
        ]
        
        let bodyGeo = SCNBox(width: 0.22, height: 0.1, length: 0.4, chamferRadius: 0.02)
        bodyGeo.firstMaterial?.diffuse.contents = colors.randomElement()!
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = 0.05
        node.addChildNode(body)
        
        let cabinGeo = SCNBox(width: 0.18, height: 0.08, length: 0.2, chamferRadius: 0.015)
        cabinGeo.firstMaterial = materialCache["glass"]
        let cabin = SCNNode(geometry: cabinGeo)
        cabin.position = SCNVector3(0, 0.13, -0.02)
        node.addChildNode(cabin)
        
        let wheelGeo = SCNCylinder(radius: 0.04, height: 0.03)
        wheelGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        
        let wheelPositions: [(Float, Float, Float)] = [
            (-0.12, 0.04, 0.12), (0.12, 0.04, 0.12),
            (-0.12, 0.04, -0.12), (0.12, 0.04, -0.12)
        ]
        
        for (wx, wy, wz) in wheelPositions {
            let wheel = SCNNode(geometry: wheelGeo)
            wheel.position = SCNVector3(wx, wy, wz)
            wheel.eulerAngles.z = Float.pi / 2
            node.addChildNode(wheel)
        }
        
        return node
    }
    
    private func createEmergencyVehicle(type: EmergencyType) -> SCNNode {
        let node = SCNNode()
        
        let bodyColor: UIColor
        let lightColor: UIColor
        
        switch type {
        case .police:
            bodyColor = UIColor(red: 0.15, green: 0.2, blue: 0.4, alpha: 1.0)
            lightColor = .blue
        case .ambulance:
            bodyColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            lightColor = .red
        case .fire:
            bodyColor = UIColor(red: 0.8, green: 0.15, blue: 0.1, alpha: 1.0)
            lightColor = .red
        }
        
        let bodyGeo = SCNBox(width: 0.24, height: 0.14, length: 0.5, chamferRadius: 0.02)
        bodyGeo.firstMaterial?.diffuse.contents = bodyColor
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = 0.07
        node.addChildNode(body)
        
        let lightGeo = SCNBox(width: 0.18, height: 0.05, length: 0.1, chamferRadius: 0.01)
        lightGeo.firstMaterial?.diffuse.contents = lightColor
        lightGeo.firstMaterial?.emission.contents = lightColor
        let lightBar = SCNNode(geometry: lightGeo)
        lightBar.position.y = 0.165
        lightBar.name = "lightBar"
        node.addChildNode(lightBar)
        
        let flash = SCNAction.sequence([
            SCNAction.customAction(duration: 0.2) { node, _ in
                node.geometry?.firstMaterial?.emission.contents = lightColor
            },
            SCNAction.customAction(duration: 0.2) { node, _ in
                node.geometry?.firstMaterial?.emission.contents = UIColor.black
            }
        ])
        lightBar.runAction(SCNAction.repeatForever(flash))
        
        return node
    }
    
    private func startRoadDrivingAnimation(for car: SCNNode) {
        guard !roadSegments.isEmpty else { return }
        
        let currentPos = car.position
        var possibleSegments: [(start: SCNVector3, end: SCNVector3)] = []
        
        for segment in roadSegments {
            let distToStart = sqrt(pow(currentPos.x - segment.start.x, 2) + pow(currentPos.z - segment.start.z, 2))
            let distToEnd = sqrt(pow(currentPos.x - segment.end.x, 2) + pow(currentPos.z - segment.end.z, 2))
            
            if distToStart < 2.5 || distToEnd < 2.5 {
                possibleSegments.append(segment)
            }
        }
        
        if possibleSegments.isEmpty {
            possibleSegments = [roadSegments.randomElement()!]
        }
        
        let nextSegment = possibleSegments.randomElement()!
        
        let distToStart = sqrt(pow(currentPos.x - nextSegment.start.x, 2) + pow(currentPos.z - nextSegment.start.z, 2))
        let distToEnd = sqrt(pow(currentPos.x - nextSegment.end.x, 2) + pow(currentPos.z - nextSegment.end.z, 2))
        
        let target = distToEnd > distToStart ? nextSegment.end : nextSegment.start
        
        let dx = target.x - currentPos.x
        let dz = target.z - currentPos.z
        let distance = sqrt(dx * dx + dz * dz)
        
        let targetAngle = atan2(dx, dz)
        let rotateAction = SCNAction.rotateTo(x: 0, y: CGFloat(targetAngle), z: 0, duration: 0.15, usesShortestUnitArc: true)
        
        let speed: Float = Float.random(in: 2.0...4.0)
        let driveAction = SCNAction.move(to: SCNVector3(target.x, 0.06, target.z), duration: TimeInterval(distance / speed))
        
        let pauseDuration = Bool.random() ? Double.random(in: 0.2...1.0) : 0
        let pauseAction = SCNAction.wait(duration: pauseDuration)
        
        car.runAction(SCNAction.sequence([rotateAction, driveAction, pauseAction])) { [weak self, weak car] in
            guard let car = car else { return }
            self?.startRoadDrivingAnimation(for: car)
        }
    }
    
    func updateEmergencyVehicles(suppressionLevel: Float) {
        let currentEmergency = vehicleNodes.filter { $0.name == "emergency_road" }.count
        let targetEmergency = Int(suppressionLevel * 10) + 1
        
        if currentEmergency < targetEmergency && !roadSegments.isEmpty {
            let types: [EmergencyType] = suppressionLevel > 0.5 ? [.police, .police, .police] : [.ambulance, .police, .fire]
            let vehicle = createEmergencyVehicle(type: types.randomElement()!)
            vehicle.name = "emergency_road"
            
            let segment = roadSegments.randomElement()!
            vehicle.position = SCNVector3(segment.start.x, 0.06, segment.start.z)
            
            let dx = segment.end.x - segment.start.x
            let dz = segment.end.z - segment.start.z
            vehicle.eulerAngles.y = atan2(dx, dz)
            
            scene.rootNode.addChildNode(vehicle)
            vehicleNodes.append(vehicle)
            startRoadDrivingAnimation(for: vehicle)
        }
    }
    
    private func startAnimationLoop() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopAnimationLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        guard let city = city else { return }
        if displayLink.timestamp - lastUpdateTime < 0.5 { return }
        lastUpdateTime = displayLink.timestamp
        
        for district in city.allDistricts {
            updateAgentCount(for: district)
            updateDistrictVisuals(for: district)
        }
        
        updateEmergencyVehicles(suppressionLevel: city.globalSuppression)
    }
    
    private func updateAgentCount(for district: District) {
        let targetPeople = Int(district.activityLevel * Float(maxPeoplePerDistrict))
        let currentPeople = personNodes.filter { $0.name == "person_\(district.id)" }.count
        
        if currentPeople < targetPeople {
            spawnPeople(count: 1, in: district)
        } else if currentPeople > targetPeople + 2 {
            removePerson(from: district)
        }
    }
    
    private func removePerson(from district: District) {
        if let person = personNodes.first(where: { $0.name == "person_\(district.id)" }) {
            person.runAction(SCNAction.sequence([
                SCNAction.fadeOut(duration: 0.6),
                SCNAction.removeFromParentNode()
            ]))
            personNodes.removeAll { $0 === person }
        }
    }
    
    private func updateDistrictVisuals(for district: District) {
        guard let districtNode = districtNodes[district.id] else { return }
        
        if let tile = districtNode.childNodes.first(where: { $0.name == "tile" }) {
            let base = groundColorForType(district.type)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            base.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            let inf = CGFloat(district.influence)
            let sup = CGFloat(district.suppressionLevel)
            r = max(0, min(1, r + inf * 0.15 - sup * 0.08))
            g = max(0, min(1, g - inf * 0.05 - sup * 0.08))
            b = max(0, min(1, b + inf * 0.1 - sup * 0.05))
            
            tile.geometry?.firstMaterial?.diffuse.contents = UIColor(red: r, green: g, blue: b, alpha: a)
        }
        
        for border in borderNodes.filter({ $0.name == "border_\(district.id)" }) {
            var color = borderColorForType(district.type)
            if district.influence > 0.2 {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                color = UIColor(
                    red: min(1, r + CGFloat(district.influence) * 0.3),
                    green: g,
                    blue: min(1, b + CGFloat(district.influence) * 0.2),
                    alpha: min(1, a + CGFloat(district.influence) * 0.2)
                )
            }
            border.geometry?.firstMaterial?.diffuse.contents = color
            border.geometry?.firstMaterial?.emission.contents = color.withAlphaComponent(CGFloat(district.influence) * 0.5)
        }
    }
    
    func highlightDistrict(_ district: District?) {
        for (_, node) in districtNodes {
            node.childNodes.filter { $0.name == "highlight" }.forEach { $0.removeFromParentNode() }
        }
        
        guard let district = district, let districtNode = districtNodes[district.id] else { return }
        
        let innerSize = tileSize - roadWidth - 0.6
        let ringGeo = SCNTorus(ringRadius: CGFloat(innerSize / 2 - 0.4), pipeRadius: 0.06)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.9)
        ringMat.emission.contents = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.5)
        ringGeo.firstMaterial = ringMat
        
        let highlight = SCNNode(geometry: ringGeo)
        highlight.name = "highlight"
        highlight.position.y = 0.08
        highlight.eulerAngles.x = .pi / 2
        highlight.runAction(SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.scale(to: 1.04, duration: 0.35),
            SCNAction.scale(to: 1.0, duration: 0.35)
        ])))
        
        districtNode.addChildNode(highlight)
    }
    
    private func subscribeToDistricts() {
        guard let city = city else { return }
        for district in city.allDistricts {
            district.$activityLevel.sink { [weak self] _ in
                self?.updateAgentCount(for: district)
            }.store(in: &cancellables)
            district.$influence.sink { [weak self] _ in
                self?.updateDistrictVisuals(for: district)
            }.store(in: &cancellables)
        }
    }
    
    func districtAt(point: CGPoint, in view: SCNView) -> District? {
        let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        for hit in hits {
            var node: SCNNode? = hit.node
            while node != nil {
                if let name = node?.name, name.starts(with: "district_"),
                   let uuid = UUID(uuidString: String(name.dropFirst("district_".count))) {
                    return city?.allDistricts.first { $0.id == uuid }
                }
                node = node?.parent
            }
        }
        return nil
    }
    
    private func createDistrictNode(_ district: District, offset: Float) -> SCNNode {
        let node = SCNNode()
        node.name = "district_\(district.id)"
        
        let centerX = Float(district.gridX) * tileSize - offset + tileSize / 2
        let centerZ = Float(district.gridY) * tileSize - offset + tileSize / 2
        node.position = SCNVector3(centerX, 0, centerZ)
        
        let innerSize = tileSize - roadWidth - 0.6
        
        let tileGeo = SCNPlane(width: CGFloat(innerSize), height: CGFloat(innerSize))
        tileGeo.firstMaterial?.diffuse.contents = groundColorForType(district.type)
        let tileNode = SCNNode(geometry: tileGeo)
        tileNode.eulerAngles.x = -.pi / 2
        tileNode.position.y = 0.01
        tileNode.name = "tile"
        node.addChildNode(tileNode)
        
        let buildingCount = Int(district.density * 5) + 2
        addProceduralBuildings(to: node, district: district, count: buildingCount, innerSize: innerSize)
        addFoliage(to: node, district: district, innerSize: innerSize)
        
        return node
    }
    
    private func groundColorForType(_ type: DistrictType) -> UIColor {
        switch type {
        case .residential: return UIColor(red: 0.38, green: 0.48, blue: 0.38, alpha: 1.0)
        case .commercial: return UIColor(red: 0.42, green: 0.42, blue: 0.45, alpha: 1.0)
        case .industrial: return UIColor(red: 0.4, green: 0.38, blue: 0.35, alpha: 1.0)
        case .civic: return UIColor(red: 0.42, green: 0.44, blue: 0.48, alpha: 1.0)
        case .park: return UIColor(red: 0.3, green: 0.52, blue: 0.35, alpha: 1.0)
        }
    }
    
    private func addProceduralBuildings(to node: SCNNode, district: District, count: Int, innerSize: Float) {
        let positions = generateBuildingPositions(count: count, innerSize: innerSize)
        
        for pos in positions {
            let building: SCNNode
            
            switch district.type {
            case .residential:
                building = createDetailedResidentialBuilding()
            case .commercial:
                building = createDetailedCommercialBuilding()
            case .industrial:
                building = createDetailedIndustrialBuilding()
            case .civic:
                building = createDetailedCivicBuilding()
            case .park:
                building = createDetailedTree()
            }
            
            building.position = SCNVector3(pos.x, 0, pos.y)
            let rotations: [Float] = [0, Float.pi/2, Float.pi, Float.pi * 1.5]
            building.eulerAngles.y = rotations.randomElement()!
            node.addChildNode(building)
        }
    }
    
    private func generateBuildingPositions(count: Int, innerSize: Float) -> [(x: Float, y: Float)] {
        var positions: [(x: Float, y: Float)] = []
        let margin: Float = 1.2
        let range = (innerSize / 2) - margin
        
        for _ in 0..<count {
            var attempts = 0
            while attempts < 25 {
                let x = Float.random(in: -range...range)
                let y = Float.random(in: -range...range)
                
                let minDist: Float = 1.8
                let tooClose = positions.contains { sqrt(pow($0.x - x, 2) + pow($0.y - y, 2)) < minDist }
                
                if !tooClose {
                    positions.append((x, y))
                    break
                }
                attempts += 1
            }
        }
        return positions
    }
    
    private func createDetailedResidentialBuilding() -> SCNNode {
        let node = SCNNode()
        
        let width = Float.random(in: 0.9...1.5)
        let depth = Float.random(in: 0.9...1.5)
        let height = Float.random(in: 1.2...2.2)
        let stories = Int(height / 0.9)
        
        let wallMaterials: [SCNMaterial?] = [materialCache["stoneLight"], materialCache["stoneMed"], materialCache["brick"]]
        let wallMat = wallMaterials.randomElement()!!
        
        let foundationGeo = SCNBox(width: CGFloat(width + 0.1), height: 0.15, length: CGFloat(depth + 0.1), chamferRadius: 0)
        foundationGeo.firstMaterial = materialCache["stoneDark"]
        let foundation = SCNNode(geometry: foundationGeo)
        foundation.position.y = 0.075
        node.addChildNode(foundation)
        
        let bodyGeo = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(depth), chamferRadius: 0)
        bodyGeo.firstMaterial = wallMat
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = height / 2 + 0.15
        node.addChildNode(body)
        
        let trimHeight = height
        let trimGeo = SCNBox(width: 0.06, height: CGFloat(trimHeight), length: 0.06, chamferRadius: 0)
        trimGeo.firstMaterial = materialCache["trim"]
        
        let corners: [(Float, Float)] = [
            (-width/2, -depth/2), (width/2, -depth/2),
            (-width/2, depth/2), (width/2, depth/2)
        ]
        for (cx, cz) in corners {
            let trim = SCNNode(geometry: trimGeo)
            trim.position = SCNVector3(cx, trimHeight/2 + 0.15, cz)
            node.addChildNode(trim)
        }
        
        for story in 0..<stories {
            let y = Float(story) * 0.9 + 0.6 + 0.15
            addDetailedWindows(to: node, width: width, depth: depth, y: y, windowStyle: .residential)
        }
        
        let doorFrameGeo = SCNBox(width: 0.35, height: 0.55, length: 0.08, chamferRadius: 0)
        doorFrameGeo.firstMaterial = materialCache["trim"]
        let doorFrame = SCNNode(geometry: doorFrameGeo)
        doorFrame.position = SCNVector3(0, 0.275 + 0.15, depth/2 + 0.03)
        node.addChildNode(doorFrame)
        
        let doorGeo = SCNBox(width: 0.28, height: 0.5, length: 0.05, chamferRadius: 0)
        doorGeo.firstMaterial = materialCache["woodDark"]
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(0, 0.25 + 0.15, depth/2 + 0.05)
        node.addChildNode(door)
        
        let roofNode = createDetailedPitchedRoof(width: width, depth: depth)
        roofNode.position.y = height + 0.15
        node.addChildNode(roofNode)
        
        if Bool.random() {
            let chimneyGeo = SCNBox(width: 0.18, height: 0.5, length: 0.18, chamferRadius: 0)
            chimneyGeo.firstMaterial = materialCache["brick"]
            let chimney = SCNNode(geometry: chimneyGeo)
            chimney.position = SCNVector3(width/3, height + 0.4, -depth/4)
            node.addChildNode(chimney)
            
            let capGeo = SCNBox(width: 0.22, height: 0.05, length: 0.22, chamferRadius: 0)
            capGeo.firstMaterial = materialCache["stoneDark"]
            let cap = SCNNode(geometry: capGeo)
            cap.position = SCNVector3(width/3, height + 0.65, -depth/4)
            node.addChildNode(cap)
        }
        
        return node
    }
    
    private func createDetailedPitchedRoof(width: Float, depth: Float) -> SCNNode {
        let node = SCNNode()
        let roofHeight: Float = 0.5
        
        let eaveGeo = SCNBox(width: CGFloat(width + 0.25), height: 0.08, length: CGFloat(depth + 0.25), chamferRadius: 0)
        eaveGeo.firstMaterial = materialCache["wood"]
        let eave = SCNNode(geometry: eaveGeo)
        eave.position.y = 0.04
        node.addChildNode(eave)
        
        let roofMat = [materialCache["roofTile"], materialCache["roofSlate"]].randomElement()!!
        
        let slopeGeo = SCNBox(width: CGFloat(width + 0.2), height: CGFloat(roofHeight * 1.2), length: CGFloat(depth/2 + 0.15), chamferRadius: 0)
        slopeGeo.firstMaterial = roofMat
        
        let frontSlope = SCNNode(geometry: slopeGeo)
        frontSlope.position = SCNVector3(0, roofHeight/2 + 0.08, depth/4)
        frontSlope.eulerAngles.x = -Float.pi * 0.15
        node.addChildNode(frontSlope)
        
        let backSlope = SCNNode(geometry: slopeGeo)
        backSlope.position = SCNVector3(0, roofHeight/2 + 0.08, -depth/4)
        backSlope.eulerAngles.x = Float.pi * 0.15
        node.addChildNode(backSlope)
        
        let ridgeGeo = SCNBox(width: CGFloat(width + 0.25), height: 0.1, length: 0.15, chamferRadius: 0.02)
        ridgeGeo.firstMaterial = materialCache["stoneDark"]
        let ridge = SCNNode(geometry: ridgeGeo)
        ridge.position.y = roofHeight + 0.05
        node.addChildNode(ridge)
        
        return node
    }
    
    private func createDetailedCommercialBuilding() -> SCNNode {
        let node = SCNNode()
        
        let width = Float.random(in: 1.3...2.2)
        let depth = Float.random(in: 1.1...1.9)
        let floors = Int.random(in: 2...5)
        let floorHeight: Float = 0.85
        let totalHeight = Float(floors) * floorHeight
        
        let foundationGeo = SCNBox(width: CGFloat(width + 0.15), height: 0.2, length: CGFloat(depth + 0.15), chamferRadius: 0)
        foundationGeo.firstMaterial = materialCache["stoneDark"]
        let foundation = SCNNode(geometry: foundationGeo)
        foundation.position.y = 0.1
        node.addChildNode(foundation)
        
        let bodyGeo = SCNBox(width: CGFloat(width), height: CGFloat(totalHeight), length: CGFloat(depth), chamferRadius: 0)
        bodyGeo.firstMaterial = materialCache["stoneMed"]
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = totalHeight / 2 + 0.2
        node.addChildNode(body)
        
        for floor in 1..<floors {
            let y = Float(floor) * floorHeight + 0.2
            let lineGeo = SCNBox(width: CGFloat(width + 0.02), height: 0.06, length: CGFloat(depth + 0.02), chamferRadius: 0)
            lineGeo.firstMaterial = materialCache["trim"]
            let line = SCNNode(geometry: lineGeo)
            line.position.y = y
            node.addChildNode(line)
        }
        
        for floor in 0..<floors {
            let y = Float(floor) * floorHeight + floorHeight * 0.5 + 0.2
            let style: WindowStyle = floor == 0 ? .shopfront : .commercial
            addDetailedWindows(to: node, width: width, depth: depth, y: y, windowStyle: style)
        }
        
        let awningGeo = SCNBox(width: CGFloat(width * 0.85), height: 0.04, length: 0.45, chamferRadius: 0)
        let awningColors: [UIColor] = [
            UIColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.2, green: 0.35, blue: 0.5, alpha: 1.0),
            UIColor(red: 0.2, green: 0.45, blue: 0.3, alpha: 1.0)
        ]
        let awningMat = SCNMaterial()
        awningMat.diffuse.contents = awningColors.randomElement()!
        awningGeo.firstMaterial = awningMat
        let awning = SCNNode(geometry: awningGeo)
        awning.position = SCNVector3(0, floorHeight * 0.85 + 0.2, depth/2 + 0.22)
        awning.eulerAngles.x = Float.pi * 0.08
        node.addChildNode(awning)
        
        let corniceGeo = SCNBox(width: CGFloat(width + 0.2), height: 0.15, length: CGFloat(depth + 0.2), chamferRadius: 0)
        corniceGeo.firstMaterial = materialCache["trim"]
        let cornice = SCNNode(geometry: corniceGeo)
        cornice.position.y = totalHeight + 0.2 + 0.075
        node.addChildNode(cornice)
        
        let parapetGeo = SCNBox(width: CGFloat(width + 0.15), height: 0.25, length: CGFloat(depth + 0.15), chamferRadius: 0)
        parapetGeo.firstMaterial = materialCache["stoneMed"]
        let parapet = SCNNode(geometry: parapetGeo)
        parapet.position.y = totalHeight + 0.2 + 0.15 + 0.125
        node.addChildNode(parapet)
        
        if Bool.random() {
            let ventGeo = SCNBox(width: 0.3, height: 0.35, length: 0.3, chamferRadius: 0)
            ventGeo.firstMaterial = materialCache["metal"]
            let vent = SCNNode(geometry: ventGeo)
            vent.position = SCNVector3(Float.random(in: -width/3...width/3), totalHeight + 0.5 + 0.175, Float.random(in: -depth/3...depth/3))
            node.addChildNode(vent)
        }
        
        return node
    }
    
    private func createDetailedIndustrialBuilding() -> SCNNode {
        let node = SCNNode()
        
        let width = Float.random(in: 1.8...2.8)
        let depth = Float.random(in: 1.8...2.8)
        let height = Float.random(in: 1.4...2.2)
        
        let slabGeo = SCNBox(width: CGFloat(width + 0.3), height: 0.12, length: CGFloat(depth + 0.3), chamferRadius: 0)
        slabGeo.firstMaterial = materialCache["concrete"]
        let slab = SCNNode(geometry: slabGeo)
        slab.position.y = 0.06
        node.addChildNode(slab)
        
        let bodyGeo = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(depth), chamferRadius: 0)
        bodyGeo.firstMaterial = [materialCache["metal"], materialCache["metalRust"]].randomElement()!
        let body = SCNNode(geometry: bodyGeo)
        body.position.y = height / 2 + 0.12
        node.addChildNode(body)
        
        let lineCount = Int(height / 0.25)
        for i in 0..<lineCount {
            let y = Float(i) * 0.25 + 0.25 + 0.12
            let lineGeo = SCNBox(width: CGFloat(width + 0.01), height: 0.02, length: CGFloat(depth + 0.01), chamferRadius: 0)
            lineGeo.firstMaterial = materialCache["stoneDark"]
            let line = SCNNode(geometry: lineGeo)
            line.position.y = y
            node.addChildNode(line)
        }
        
        let doorW = width * 0.45
        let doorH = height * 0.65
        let doorFrameGeo = SCNBox(width: CGFloat(doorW + 0.1), height: CGFloat(doorH + 0.1), length: 0.08, chamferRadius: 0)
        doorFrameGeo.firstMaterial = materialCache["stoneDark"]
        let doorFrame = SCNNode(geometry: doorFrameGeo)
        doorFrame.position = SCNVector3(0, doorH/2 + 0.12, depth/2 + 0.03)
        node.addChildNode(doorFrame)
        
        let doorGeo = SCNBox(width: CGFloat(doorW), height: CGFloat(doorH), length: 0.05, chamferRadius: 0)
        doorGeo.firstMaterial = materialCache["metal"]
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(0, doorH/2 + 0.12, depth/2 + 0.06)
        node.addChildNode(door)
        
        let roofGeo = SCNBox(width: CGFloat(width + 0.25), height: 0.12, length: CGFloat(depth + 0.25), chamferRadius: 0)
        roofGeo.firstMaterial = materialCache["roofSlate"]
        let roof = SCNNode(geometry: roofGeo)
        roof.position.y = height + 0.12 + 0.06
        node.addChildNode(roof)
        
        let chimneyCount = Int.random(in: 1...2)
        for i in 0..<chimneyCount {
            let chimneyH = Float.random(in: 1.0...1.8)
            let chimneyGeo = SCNCylinder(radius: CGFloat(Float.random(in: 0.12...0.2)), height: CGFloat(chimneyH))
            chimneyGeo.firstMaterial = materialCache["metalRust"]
            let chimney = SCNNode(geometry: chimneyGeo)
            chimney.position = SCNVector3(
                Float(i) * width/2 - width/4 + Float.random(in: -0.2...0.2),
                height + chimneyH/2 + 0.18,
                Float.random(in: -depth/3...depth/3)
            )
            node.addChildNode(chimney)
            
            let capGeo = SCNTorus(ringRadius: CGFloat(Float.random(in: 0.14...0.22)), pipeRadius: 0.03)
            capGeo.firstMaterial = materialCache["stoneDark"]
            let cap = SCNNode(geometry: capGeo)
            cap.position = SCNVector3(chimney.position.x, height + chimneyH + 0.18, chimney.position.z)
            node.addChildNode(cap)
        }
        
        if Bool.random() {
            let tankGeo = SCNCylinder(radius: 0.35, height: 0.7)
            tankGeo.firstMaterial = materialCache["metal"]
            let tank = SCNNode(geometry: tankGeo)
            tank.position = SCNVector3(-width/2 - 0.5, 0.35 + 0.12, 0)
            node.addChildNode(tank)
        }
        
        return node
    }
    
}
