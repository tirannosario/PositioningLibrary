//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//


import Foundation
#if !os(macOS)
import ARKit
import UIKit
import RealityKit

public class LocationProvider: NSObject, ARSessionDelegate {
    private var buildings: [Building]
    private var userLocation: Location?
    private var arView: ARView
    private var locationObserver: LocationObserver?
    
    public init(_ arView: ARView) {
        self.buildings = []
        self.arView = arView
    }
    
    public init(_ arView: ARView, _ buildings: [Building]) {
        self.buildings = buildings
        self.arView = arView
    }
    
    public func addBuilding(_ building: Building) {
        self.buildings.append(building)
    }
    
    public func addLocationObserver(_ locationObserver: LocationObserver) {
        self.locationObserver = locationObserver
    }
    
    private func calculateLocation() {
        
    }
    
    private func setNewLocation(_ location: Location) {
        self.userLocation = location
        self.locationObserver?.onLocationUpdate(location)
    }
    
    public func start() {
        // Set ARView delegate so we can define delegate methods in this controller
        self.arView.session.delegate = self

        // Forgo automatic configuration to do it manually instead
        self.arView.automaticallyConfigureSession = false

        // Show statistics if desired
        self.arView.debugOptions = [.showStatistics]

        // Disable any unneeded rendering options
        self.arView.renderOptions = [.disableCameraGrain, .disableHDR, .disableMotionBlur, .disableDepthOfField, .disableFaceMesh, .disablePersonOcclusion, .disableGroundingShadows, .disableAREnvironmentLighting]

        // Instantiate configuration object
        let configuration = ARWorldTrackingConfiguration()

        // Both trackingImages and maximumNumberOfTrackedImages are required
        // This example assumes there is only one reference image named "target"
        configuration.maximumNumberOfTrackedImages = 100 //TODO a quanto?
        configuration.trackingImages = loadReferenceMarkers()
        // Note that this config option is different than in world tracking, where it is
        // configuration.detectionImages
        
        // Run an ARView session with the defined configuration object
        self.arView.session.run(configuration)
    }
    
    private func loadReferenceMarkers() -> Set<ARReferenceImage> {
        var references: Set<ARReferenceImage> = []
        for building in buildings {
            for floor in building.floors {
                for marker in floor.markers {
                    guard let image = marker.image.cgImage else { continue }
                    let reference = ARReferenceImage(image, orientation: .up, physicalWidth: marker.physicalWidth)
                    reference.name = marker.id
                    references.insert(reference)
                }
            }
        }
        return references
    }
    
    private func findMarkByID(_ markerID: String) -> Marker? {
        for building in buildings {
            for floor in building.floors {
                for marker in floor.markers {
                    if marker.id == markerID {
                        return marker
                    }
                }
            }
        }
        return nil
    }
    
    
    //MARK: AR Delegate Methods
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //TODO, cosa succede se si inquadrano più marker? Come ci dobbiamo comportare?
        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
        if let imgId = imageAnchor.referenceImage.name {
            let markerFound = findMarkByID(imgId)
            if markerFound != nil {
                print("Found: \(markerFound!.id) at Location <\(markerFound!.location)>")
                setNewLocation(markerFound!.location)
            }
            else {
                print("Nothing found")
            }
        }
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //TODO, cosa succede se si inquadrano più marker? Come ci dobbiamo comportare?
        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
        if let imgId = imageAnchor.referenceImage.name {
            let markerFound = findMarkByID(imgId)
            if markerFound != nil {
                if imageAnchor.isTracked {
                    print("Tracked: \(markerFound!.id) at Location <\(markerFound!.location)>")
                    setNewLocation(markerFound!.location)
                } else {
                    print("The anchor for \(markerFound!.id) is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.")
                }
            }
            else {
                print("Nothing found")
            }
        }
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
       print("new frame")
    }
}

#endif
