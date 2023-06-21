//
//  ContentView.swift
//  ARSwiftUI
//
//  Created by 唐东强 on 2021/12/9.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import Vision

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

var fireBallEntity :ModelEntity! // 白球
var planeAnchor :AnchorEntity!
var originAnchor:ARPlaneAnchor!
var planeEntity :ModelEntity!
var subscribes: [Cancellable] = []
var score = 0
var button:UIButton!
var scoreLabel = UILabel.init(frame: .init(x: UIScreen.main.bounds.width/2 - 100, y: 100, width: 200, height: 70))
var switchView = UISwitch.init(frame: .init(x: UIScreen.main.bounds.size.width/2-50, y: UIScreen.main.bounds.size.height - 240, width: 100, height: 40))
var clueLabel: UILabel = .init(frame: .init(x: UIScreen.main.bounds.size.width/2-50, y: UIScreen.main.bounds.size.height - 240, width: 100, height: 40))
var recentIndexFingerPoint:CGPoint!
var request: VNDetectHumanHandPoseRequest!

// 发射模式
enum FireMode: Int {
    case tap = 1 // 点击屏幕发射
    case hand = 2 // vision手势发射
}
var firemode = FireMode.tap
let coachingOverlay = ARCoachingOverlayView()
let arView = ARView(frame: .zero)

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        recentIndexFingerPoint = .zero
        /*Vision 三要素
        Request：定义请求特征来请求框架检测什么东西
        Handler：请求完成执行或处理请求之后执行一种方法
        Observation：获得潜在的结果或观察结果,这些观察基于请求的VNObservation的实例
         */
        request = VNDetectHumanHandPoseRequest(completionHandler: handDetectionCompletionHandler)
        request.maximumHandCount = 1
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        // 启用环境纹理贴图和人形遮挡
        config.environmentTexturing = .automatic
//        config.frameSemantics = [.personSegmentation]
        arView.session.delegate = arView
        // 平面识别引导-这里实际没有使用检测的平面
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.frame = arView.frame
        arView.session.run(config, options: [])
        arView.addSubview(coachingOverlay)
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    // 手势检测handles
    func handDetectionCompletionHandler(request: VNRequest?, error: Error?) {
        guard let observation = request?.results?.first as? VNHumanHandPoseObservation else { return }
        /* TIP：指尖。
         DIP：指间远端关节或指尖后的第一个关节。
         PIP：指间近关节或中间关节。
         MIP：掌指关节位于手指底部，与手掌相连。
         .thumb 拇指
         .indexFinger 食指
         .middleFinger 中指
         .ringFinger 无名指
         .littleFinger 小指
         */
        guard let indexFingerTip = try? observation.recognizedPoints(.all)[.indexTip],
              indexFingerTip.confidence > 0.3 else {return}
        let normalizedIndexPoint = VNImagePointForNormalizedPoint(CGPoint(x: indexFingerTip.location.y, y: indexFingerTip.location.x), Int(UIScreen.main.bounds.width),  Int(UIScreen.main.bounds.height))
        if let entity = arView.entity(at: normalizedIndexPoint) as? ModelEntity, entity == fireBallEntity {
            DispatchQueue.main.async {
                arView.fire()
                print("KAKA==手势发射")
            }
        }
        recentIndexFingerPoint = normalizedIndexPoint
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
