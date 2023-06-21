//
//  ARView.Delegate.swift
//  ARSwiftUI
//
//  Created by 唐东强 on 2023/6/21.
//

import Foundation
import RealityKit
import ARKit

extension ARView: ARSessionDelegate{
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        setUpViews()
        // 添加平面
        guard let anchor = anchors.first as? ARPlaneAnchor else{return}
        originAnchor = anchor
        print(anchor)
        addAnchorEntitys()
    }
    
    // 添加平面、墙、球Entity
    func addAnchorEntitys() {
        resetPlaneEntity()
        resetWalls()
        resetBallAndBoxes()
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if request == nil {
            return
        }
        let pixelBuffer = frame.capturedImage
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(cvPixelBuffer:pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([(request)!])
            } catch let error {
                print(error)
            }
        }
    }
    
    func setUpViews() {
        coachingOverlay.removeFromSuperview()
        switchView.center = .init(x: self.center.x, y: switchView.center.y)
        switchView.addTarget(self, action: #selector(changeFireMode), for: .valueChanged)
        setupClueLabel()
        addSubview(clueLabel)
        addSubview(switchView)
    }
    
    private func setupClueLabel() {
        clueLabel.center = .init(x: self.center.x, y: switchView.center.y + 30)
        clueLabel.textAlignment = .center
        clueLabel.textColor = .red
        clueLabel.font = .systemFont(ofSize: 12)
        clueLabel.text = "手势发射"
    }
    
    // 重置平面Entity
    func resetPlaneEntity() {
        self.scene.findEntity(named: "plane")?.removeFromParent()
        planeAnchor = AnchorEntity.init(plane: .horizontal)
        let plane :MeshResource = .generatePlane(width: 100, depth: 100)
        let planeCollider : ShapeResource = .generateBox(width: 100, height: 0.01, depth: 100)
        var planeMaterial = SimpleMaterial(color:.black,isMetallic: false)
        //vision
        if firemode == .hand {
            planeMaterial = SimpleMaterial(color:UIColor.init(white: 1, alpha: 0.1),isMetallic: false)
        }
        //ModelEntity同时挂载了Model Component、Collision Component、Physics Body Component、Physics Motion Component组件，以下使用ModelEntity常见小球，都拥有物理模拟和碰撞的能力
        planeEntity = ModelEntity(mesh: plane, materials: [planeMaterial], collisionShape: planeCollider, mass: 0.01)
        planeEntity.physicsBody?.mode = .static
        planeEntity.physicsBody?.material = .generate(friction: 0.001, restitution: 0.1)
        planeEntity.position = planeAnchor.position
        planeEntity.name = "plane"
        planeAnchor.addChild(planeEntity)
        self.scene.addAnchor(planeAnchor)
    }
    
    // UIswitch改变firemode
    @objc
    func changeFireMode(){
        firemode = switchView.isOn ? .hand : .tap
        self.scene.anchors.removeAll()
        addAnchorEntitys()
    }
    // 重置墙Entity
    func resetWalls() {
        while planeAnchor.findEntity(named: "wall") != nil {
            planeAnchor.findEntity(named: "wall")?.removeFromParent()
        }
        /// 前方背景墙
        let shap : ShapeResource = .generateBox(width: 2, height: 1.2, depth: 1)
        // 网格资源：提供了资源化的几何表示
        let meshSphere: MeshResource = .generateBox(width: 2, height: 1.2, depth: 1)
        // 与SimpleMaterial相比，UnlitMaterial不支持PBR，也不受环境光影响，例如灯光调暗，电视机SimpleMaterial变暗，屏幕使用UnlitMaterial保持亮度
        let material = SimpleMaterial(color:.green,isMetallic: false)
        // 贴图方式
//        material.color = .init(tint: .green, texture: .init(.init(.load(named: "", in: <#T##Bundle?#>))))
        let wallEntity = ModelEntity(mesh: meshSphere, materials: [material], collisionShape: shap, mass: 0.04)
        wallEntity.physicsBody?.mode = .static
//        wallEntity.position = SIMD3<Float>(0, planeEntity.transform.translation.y, -1.2)
        wallEntity.physicsBody?.material = .generate(friction: 1, restitution: 0.01)
        wallEntity.position = SIMD3<Float>(planeEntity.transform.translation.x,planeEntity.transform.translation.y+0.5, -2)
        wallEntity.name = "wall"
        planeAnchor.addChild(wallEntity)
        /// 左边背景墙
        let shap2 : ShapeResource = .generateBox(width: 0.1, height: 1.2, depth: 3)
        let meshSphere2: MeshResource = .generateBox(width: 0.1, height: 1.2, depth: 3)
        let material2 = SimpleMaterial(color:.red,isMetallic: false)
        let wallEntity2 = ModelEntity(mesh: meshSphere2, materials: [material2], collisionShape: shap2, mass: 0.04)
        wallEntity2.physicsBody?.mode = .static
//        wallEntity2.position = SIMD3<Float>(0, planeEntity.transform.translation.y, -1.2)
        wallEntity2.physicsBody?.material = .generate(friction: 1, restitution: 0.01)
        wallEntity2.transform.translation = [planeEntity.transform.translation.x-0.5,planeEntity.transform.translation.y+0.5, 0]
        wallEntity2.name = "wall"
        planeAnchor.addChild(wallEntity2)
        /// 右边背景墙
        let shap3 : ShapeResource = .generateBox(width: 0.1, height: 1.2, depth: 3)
        let meshSphere3: MeshResource = .generateBox(width: 0.1, height: 1.2, depth: 3)
        let material3 = SimpleMaterial(color:.blue,isMetallic: false)
        let wallEntity3 = ModelEntity(mesh: meshSphere3, materials: [material3], collisionShape: shap3, mass: 0.04)
        wallEntity3.physicsBody?.mode = .static
//        wallEntity3.position = SIMD3<Float>(0, planeEntity.transform.translation.y, -1.2)
        wallEntity3.physicsBody?.material = .generate(friction: 1, restitution: 0.01)
        wallEntity3.transform.translation = [planeEntity.transform.translation.x+0.5,planeEntity.transform.translation.y+0.5, 0]
        wallEntity3.name = "wall"
        planeAnchor.addChild(wallEntity3)
        
        // 得分Label
        scoreLabel.text = "得分: 0"
        scoreLabel.font = .boldSystemFont(ofSize: 50)
        scoreLabel.textColor = .green
        scoreLabel.textAlignment = .center
        self.addSubview(scoreLabel)
    }
    
    // 重新开始游戏重置彩球
    func addBalls() {
        // 彩球
        score = 0
        scoreLabel.text = "得分: \(score)"
        let count = 3
        for i in 0...count {
            for j in 0...count {
                // 随机颜色球
                let r: CGFloat = CGFloat(arc4random() % 255) / 256.0
                let g: CGFloat = CGFloat(arc4random() % 255) / 256.0
                let b: CGFloat = CGFloat(arc4random() % 255) / 256.0
                let sphereCollider : ShapeResource = .generateSphere(radius: 0.05)
                let sphere: MeshResource = .generateSphere(radius: 0.05)
                let sphereMaterial = SimpleMaterial(color:UIColor.init(red: r, green: g, blue: b, alpha: 1),isMetallic: false)
                
                let sphereEntity = ModelEntity(mesh: sphere, materials: [sphereMaterial], collisionShape: sphereCollider, mass: 0.04)
                sphereEntity.physicsBody?.mode = .dynamic
//                sphereEntity.position = SIMD3<Float>(-0.202 + 0.101 * Float(j), planeEntity.transform.translation.y + 0.101 * Float(i), -1.2)
                sphereEntity.physicsBody?.material = .generate(friction: 1, restitution: 0.01)
                sphereEntity.transform.translation = [-0.20 + 0.10 * Float(j),planeEntity.transform.translation.y + 0.10 * Float(i)+0.05, -1]
                // 碰撞检测使用name匹配Entity
                sphereEntity.name = "box"
                planeAnchor.addChild(sphereEntity)
            }
        }
        
        // 触发域实体
        let triggerShape :ShapeResource = .generateBox(size: [0.2,0.2,0.2])
        let triggerVolume = TriggerVolume(shape: triggerShape)
        triggerVolume.position = SIMD3<Float>(-planeEntity.transform.translation.x,-planeEntity.transform.translation.y+0.2,-planeEntity.transform.translation.z-0.2)
        
        let sphereCollider : ShapeResource = .generateSphere(radius: 0.05)
        let sphere: MeshResource = .generateSphere(radius: 0.05)
        let sphereMaterial = SimpleMaterial(color:.white,isMetallic: false)
        // 发射球
        fireBallEntity = ModelEntity(mesh: sphere, materials: [sphereMaterial], collisionShape: sphereCollider, mass: 0.1)
        fireBallEntity.physicsBody?.mode = .dynamic
        fireBallEntity.name = "ball"
        fireBallEntity.physicsBody?.material = .generate(friction: 0, restitution: 0)
//        sphereEntity.position = SIMD3<Float>(0,0,-0.2)
        fireBallEntity.transform.translation = [-planeEntity.transform.translation.x,-planeEntity.transform.translation.y+0.2,-planeEntity.transform.translation.z-0.2]
        fireBallEntity.transform.translation = [-0.05,0.1,-0.15]
        planeAnchor.addChild(fireBallEntity)
        planeAnchor.addChild(triggerVolume)
        // 订阅碰撞事件 Combine框架，响应式编程
        subscribes.append(scene.subscribe(to: CollisionEvents.Began.self, on: fireBallEntity) { event in
            guard let A = event.entityA as? ModelEntity else {
                            return
                        }
            guard let B = event.entityB as? ModelEntity else {
                            return
                        }
            if (A.name == "box" && B.name == "ball") ||
                (B.name == "box" && A.name == "ball")
            {
                if A.name == "box" {
                    A.name = "score"
                    A.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
                    score = score + 1
                    scoreLabel.text = "\(score)"
                }
                if B.name == "box" {
                    B.name = "score"
                    B.model?.materials  = [SimpleMaterial(color: .black, isMetallic: false)]
                    score = score + 1
                    scoreLabel.text = "\(score)"
                }
            }
        })
        
        // tap发射
        self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.handleTranslation(_:))))
    }
    
    @objc
    func handleTranslation(_ recognizer: EntityTranslationGestureRecognizer) {
        print("KAKA==点击发射")
        fire()
    }
    
    // 施加力
    @objc
    func fire() {
        fireBallEntity.addForce([0,8,-40], relativeTo: planeEntity)
        if button == nil {
            button = UIButton.init(frame: .init(x: UIScreen.main.bounds.size.width/2-50, y: UIScreen.main.bounds.size.height - 180, width: 100, height: 80))
            button.setTitle("Restart", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: #selector(self.resetBallAndBoxes), for: .touchUpInside)
            self.addSubview(button)
        }
    }
    
    // 重新添加球
    @objc
    func resetBallAndBoxes(){
        while planeAnchor.findEntity(named: "box") != nil ||
                planeAnchor.findEntity(named: "ball") != nil ||
                planeAnchor.findEntity(named: "score") != nil {
            planeAnchor.findEntity(named: "box")?.removeFromParent()
            planeAnchor.findEntity(named: "ball")?.removeFromParent()
            planeAnchor.findEntity(named: "score")?.removeFromParent()
        }
        addBalls()
    }
}
