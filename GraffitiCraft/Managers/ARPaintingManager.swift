//
//  ARPaintingManager.swift
//  GraffitiCraft
//
//  Created by Kurnia Kharisma Agung Samiadjie on 10/12/24.
//

import Foundation
import ARKit
import AVFoundation

struct ARPaintingManager {
    private var fullPaintArray = [[SCNNode]]()
    private var singlePaintArray = [SCNNode]()
    public var sprayAmount = 0
    
    mutating func applyPaintAtLocation(_ node: SCNNode, _ color: UIColor, _ hitResult: ARRaycastResult){
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = color
        
        node.geometry?.materials = [sphereMaterial]
        
        node.position = SCNVector3(
            x: hitResult.worldTransform.columns.3.x,
            y: hitResult.worldTransform.columns.3.y,
            z: hitResult.worldTransform.columns.3.z
        )
        
        singlePaintArray.append(node)
    }
    
    mutating func finalizeCurrentPaintStroke(){
        fullPaintArray.append(singlePaintArray)
        singlePaintArray.removeAll()
    }
    
    mutating func clearAllPaintings(){
        for nodes in fullPaintArray {
            for node in nodes{
                node.removeFromParentNode()
            }
        }
        
        fullPaintArray.removeAll()
    }
    
    mutating func undoLastPaintStroke(){
        if let nodeWillDelete = fullPaintArray.last {
            for node in nodeWillDelete {
                node.removeFromParentNode()
            }
            
            fullPaintArray.removeLast()
        }else{
            print("Kosong")
        }
    }
    
    func createAnchorPlaneNode(_ anchor: ARPlaneAnchor) -> SCNNode{
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let planeNode = SCNNode()
        
        planeNode.position = SCNVector3(x: anchor.center.x, y: 0, z: anchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.white
        gridMaterial.transparency = 0.5
        
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
    }
    
    func triggerFlashEffectInScene(_ scene: ARSCNView) {
        // Create a white view
        let flashView = UIView(frame: scene.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        scene.addSubview(flashView)
        
        // Animate the flash effect
        UIView.animate(withDuration: 0.1, animations: {
            flashView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                flashView.alpha = 0.0
            }) { _ in
                // Remove the flash view after the animation
                flashView.removeFromSuperview()
            }
        }
    }
    
    func isSprayAvailable() -> Bool{
        if sprayAmount > 0 {
            return true
        }else{
            return false
        }
    }
}
