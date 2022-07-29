//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//


import Foundation
#if !os(macOS)
import ARKit


public class LocationProvider: ARSessionDelegate {
    private var building: [Building]
    private var userLocation: Location?
    private var arView: ARView
    private var locationObserver: LocationObserver?
    
    init(_ arView: ARView) {
        self.building = []
        self.arView = arView
    }
    
    init(_ arView: ARView, _ buildings: [Building]) {
        self.building = buildings
        self.arView = arView
    }
    
    public func addBuilding(_ building: Building) {
        self.building.append(building)
    }
    
    public func addLocationObserver(_ locationObserver: LocationObserver) {
        self.locationObserver = locationObserver
    }
    
    public func start() {
        // There must be a set of reference images in project's assets
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { fatalError("Missing expected asset catalog resources.") }
        
        // Set ARView delegate so we can define delegate methods in this controller
        self.arView.session.delegate = self

        // Forgo automatic configuration to do it manually instead
        self.arView.automaticallyConfigureSession = false

        // Show statistics if desired
        self.arView.debugOptions = [.showStatistics]

        // Disable any unneeded rendering options
        self.arView.renderOptions = [.disableCameraGrain, .disableHDR, .disableMotionBlur, .disableDepthOfField, .disableFaceOcclusions, .disablePersonOcclusion, .disableGroundingShadows, .disableAREnvironmentLighting]

        // Instantiate configuration object
        let configuration = ARImageTrackingConfiguration()

        // Both trackingImages and maximumNumberOfTrackedImages are required
        // This example assumes there is only one reference image named "target"
        configuration.maximumNumberOfTrackedImages = 1
        configuration.trackingImages = referenceImages
        // Note that this config option is different than in world tracking, where it is
        // configuration.detectionImages
        
        // Run an ARView session with the defined configuration object
        self.arView.session.run(configuration)
    }
    
    //MARK: AR stuff
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
       
        // This example assumes only one reference image of interest
        // A for-in loop could work for more targets

        // Ensure the first anchor in the list of added anchors can be downcast to an ARImageAnchor
        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }

        // If the added anchor is named "target", do something with it
        if let imageName = imageAnchor.name, imageName  == "target" {

            // An example of something to do: Attach a ball marker to the added reference image.
            // Create an AnchorEntity, create a virtual object, add object to AnchorEntity
            let refImageAnchor = AnchorEntity(anchor: imageAnchor)
            let refImageMarker = generateBallMarker(radius: 0.02, color: .systemPink)
            refImageMarker.position.y = 0.04
            refImageAnchor.addChild(refImageMarker)
            
            // Add new AnchorEntity and its children to ARView's scene's anchor collection
            self.arView.scene.addAnchor(refImageAnchor)
            // There is now RealityKit content anchored to the target reference image!
            
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
        // Assuming only one reference image. A for-in loop could work for more targets

        if let imageName = imageAnchor.name, imageName  == "target" {
            // If anything needs to be done as the ref image anchor is updated frame-to-frame, do it here
            
            // E.g., to check if the reference image is still being tracked:
            // (https://developer.apple.com/documentation/arkit/artrackable/2928210-istracked)
            if imageAnchor.isTracked {
                print("\(imageName) is tracked and has a valid transform")
            } else {
                print("The anchor for \(imageName) is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.")
            }
        }
    }
    
    // Convenience method to create colored spheres
    func generateBallMarker(radius: Float, color: UIColor) -> ModelEntity {
        let ball = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        return ball
    }
}

#endif
