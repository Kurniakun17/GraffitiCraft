import ARKit
import AVFoundation
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate, AVAudioPlayerDelegate {
    private var paintingManager = ARPaintingManager()
    private var soundModel = SoundService()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var colorWheel: UIColorWell!
    @IBOutlet var radiusSlider: UISlider!
    @IBOutlet var labelTemp: UILabel!
    @IBOutlet var overlayView: UIView!
    
    private var timer: Timer?
    private var isDrawing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        radiusSlider.minimumValue = 0.005
        radiusSlider.maximumValue = 0.1
        radiusSlider.value = radiusSlider.maximumValue / 2
        radiusSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        
        labelTemp.isHidden = true
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        
        sceneView.session.run(configuration)
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let url = Bundle.main.url(forResource: "kocok", withExtension: "mp3")!
        
        paintingManager.sprayAmount = 500
        
        soundModel.audioAssign(url)?.play()
        
        overlayView.isHidden = paintingManager.isSprayAvailable()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        soundModel.audioStop()
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let planeAnchor = anchor as! ARPlaneAnchor
            
            let addNode = paintingManager.createAnchorPlaneNode(planeAnchor)
            node.addChildNode(addNode)
        } else {
            return
        }
    }
    
    @IBAction func deleteOnPressed(_ sender: UIButton) {
        paintingManager.clearAllPaintings()
    }
    
    @IBAction func drawButtonHold(_ sender: UIButton) {
        if paintingManager.isSprayAvailable() {
            let url = Bundle.main.url(forResource: "gambar", withExtension: "mp3")!
            
            let player = soundModel.audioAssign(url)
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                self.updateNodePosition()
                
                if self.isDrawing {
                    player?.numberOfLoops = -1
                    player?.delegate = self
                    player?.play()
                }
                
                self.overlayView.isHidden = self.paintingManager.isSprayAvailable()
            }
        } else {
            overlayView.isHidden = paintingManager.isSprayAvailable()
        }
    }
    
    @IBAction func drawButtonExit(_ sender: UIButton) {
        timer?.invalidate()
        
        paintingManager.finalizeCurrentPaintStroke()
        soundModel.audioStop()
        
        isDrawing = false
        overlayView.isHidden = paintingManager.isSprayAvailable()
        
        timer = nil
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        let photoTaken = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(photoTaken, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        paintingManager.triggerFlashEffectInScene(sceneView)
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        paintingManager.undoLastPaintStroke()
    }
    
    @objc func updateNodePosition() {
        if paintingManager.isSprayAvailable() {
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
//            let results = sceneView.hitTest(screenCenter, types: .existingPlaneUsingExtent)
            guard let raycastQuery = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .vertical) else {
                return
            }

            let results = sceneView.session.raycast(raycastQuery)
            
            if let hitResult = results.first {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: CGFloat(radiusSlider.value)))
                
                paintingManager.applyPaintAtLocation(sphereNode, colorWheel.selectedColor!, hitResult)
                paintingManager.sprayAmount -= 1
                
                DispatchQueue.main.async {
                    self.sceneView.scene.rootNode.addChildNode(sphereNode)
                }
                
                isDrawing = true
            }
        } else {
            soundModel.audioStop()
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
        }
    }
}
