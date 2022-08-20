//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//


import Foundation
import ARKit
import UIKit
import RealityKit
import SceneKit

public class LocationProvider: NSObject, ARSessionDelegate {
    private var markers: [Marker]
    private var userLocation: Location?
    private var currentBuilding: Building?
    private var currentFloor: Floor?
    private var arView: ARView
    private var locationObserver: LocationObserver?
    private var floorMapView: FloorMapView!
    
    private var originFixed = false

    
    public init(arView: ARView) {
        self.markers = []
        self.arView = arView
    }
    
    public init(arView: ARView, markers: [Marker]) {
        self.markers = markers
        self.arView = arView
    }
    
    public func addMarker(marker: Marker) {
        self.markers.append(marker)
    }
    
    public func addLocationObserver(locationObserver: LocationObserver) {
        self.locationObserver = locationObserver
    }
            
    public func start() {
        // Set ARView delegate so we can define delegate methods in this controller
        self.arView.session.delegate = self

        // Forgo automatic configuration to do it manually instead
        self.arView.automaticallyConfigureSession = false

        // Show statistics if desired
        self.arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins]

        // Disable any unneeded rendering options
        self.arView.renderOptions = [.disableCameraGrain, .disableHDR, .disableMotionBlur, .disableDepthOfField, .disableFaceMesh, .disablePersonOcclusion, .disableGroundingShadows, .disableAREnvironmentLighting]

        // Instantiate configuration object
        let configuration = ARWorldTrackingConfiguration()

        // Both trackingImages and maximumNumberOfTrackedImages are required
        // This example assumes there is only one reference image named "target"
        configuration.maximumNumberOfTrackedImages = 100 //TODO a quanto?
        configuration.detectionImages = loadReferenceMarkers()
        // Note that this config option is different than in world tracking, where it is
        // configuration.detectionImages
        
        // Run an ARView session with the defined configuration object
        self.arView.session.run(configuration)
    }
    
    public func showFloorMap(_ cgRect: CGRect) {
        if(self.floorMapView == nil) {
            floorMapView = FloorMapView(frame: cgRect)
            arView.addSubview(floorMapView)
        }
        else {
            print("An FloorMap already exist")
        }
    }
    
    public func hideFloorMap() {
        if(self.floorMapView != nil) {
            self.floorMapView.removeFromSuperview()
            self.floorMapView = nil
        }
        else {
            print("Any FloorMap exist")
        }
    }
    
    private func loadReferenceMarkers() -> Set<ARReferenceImage> {
        var references: Set<ARReferenceImage> = []
        for marker in markers {
            guard let image = marker.image.cgImage else { continue }
            let reference = ARReferenceImage(image, orientation: .up, physicalWidth: marker.physicalWidth)
            reference.name = marker.id
            references.insert(reference)
        }
        return references
    }
    
    private func findMarkByID(markerID: String) -> Marker? {
        for marker in markers {
            if marker.id == markerID {
                let floor = marker.location.floor
                let building = floor.building
                if(self.currentBuilding == nil || self.currentBuilding?.id != building.id) { // se currentBuilding = nil anche currentFloor lo è, poichè non abbiamo ancora visitato nessun Building
                    self.currentBuilding = building
                    self.locationObserver?.onBuildingChanged(self.currentBuilding!)
                    self.currentFloor = floor
                    self.locationObserver?.onFloorChanged(self.currentFloor!)
                }
                else if(self.currentFloor?.number != floor.number) {
                    self.currentFloor = floor
                    self.locationObserver?.onFloorChanged(self.currentFloor!)
                }
                return marker
            }
        }
        return nil
    }
    
    //MARK: AR Delegate Methods
    
    // quando trovo per la prima volta un Marker, faccio il fix dell'origin
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //TODO, cosa succede se si inquadrano più marker? Come ci dobbiamo comportare?
        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
        if let imgId = imageAnchor.referenceImage.name {
            let markerFound = findMarkByID(markerID: imgId)
            if markerFound != nil {
                print("Found: \(markerFound!.id) at Location <\(markerFound!.location)>")
                fixAROrigin(imageAnchor: imageAnchor, location: markerFound!.location)
            }
            else {
                print("Nothing found")
            }
        }
    }
    
    // quando continuo a vedere lo stesso Marker, ricalcolo la posizione del device
//    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        //TODO, cosa succede se si inquadrano più marker? Come ci dobbiamo comportare?
//        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
//        if let imgId = imageAnchor.referenceImage.name {
//            let markerFound = findMarkByID(markerID: imgId)
//            if markerFound != nil {
//                if imageAnchor.isTracked {
//                    updateLocation(imageAnchor: imageAnchor, location: markerFound!.location)
//                } else {
//                    print("The anchor for \(markerFound!.id) is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.")
//                }
//            }
//            else {
//                print("Nothing found")
//            }
//        }
//    }
    
    // viene richiamata ad ogni frame (anche quando non inquadriamo nessun marker), calcola la posizione dell'utente rispetto all'orgine SCA (la aggiorna con tecn. dead reckoning)
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        calculateDevicePose(frame)
      }

    
    //MARK: Calcolo della Posizione
    
    private func fixAROrigin(imageAnchor: ARImageAnchor, location: Location) {
        let alpha_a = getSCARotationY(imageAnchor)
        let alpha_m = location.heading
        let alpha = alpha_a - alpha_m
//        print("alpha_a: \(alpha_a)    alpha_m: \(alpha_m)  -> alpha: \(alpha)")
        
        let (x_m, y_m) = (Float(location.coordinates.x), Float(location.coordinates.y))
        let (x_a, z_a) = getMarkerSCACoordinates(imageAnchor)
//        print("x_a:\(x_a)  z_a:\(z_a)")
        
        let x_b = x_a * cos(alpha) - z_a * sin(alpha)
        let y_b = x_a * sin(alpha) + z_a * cos(alpha)
        
        let x_t = x_m - x_b
        let y_t = y_m - y_b
        print("x_t:\(x_t)  y_t:\(y_t)")
        
        // ruoto origine SCA
        let cosa = cos(alpha)
        let sina = sin(alpha)
        let rotationMatrix = simd_float4x4(
            SIMD4(cosa, 0, -sina, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(sina, 0, cosa, 0),
            SIMD4(0, 0, 0, 1)
        )
        self.arView.session.setWorldOrigin(relativeTransform: rotationMatrix)
        
        // traslo origine SCA
        let translationMatrix = simd_float4x4(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(-x_t, imageAnchor.transform.columns.3.y, -y_t, 1) // andiamo a settare x con x_t e z con y_t, settiamo y all'altezza del marker (non importa)
        )
        let newWorldTransform = simd_mul(rotationMatrix, translationMatrix)
        self.arView.session.setWorldOrigin(relativeTransform: newWorldTransform)
        originFixed = true
    }
    
    private func getMarkerSCACoordinates(_ imageAnchor: ARImageAnchor)-> (Float, Float) {
        let coordinates = imageAnchor.transform.columns.3
        return (coordinates.x, coordinates.z) // ritorna (x_a, z_a), y non ci interessa
    }
        
    private func getSCARotationY(_ imageAnchor: ARImageAnchor) -> Float{
        let node = SCNNode()
        node.transform = SCNMatrix4(imageAnchor.transform)
        return (node.rotation.y * node.rotation.w) // in radianti
    }
    
    private func calculateDevicePose(_ frame: ARFrame) {
        if(originFixed) { // solo se abbiamo trovato un marker e abbiamo fixato l'origine SCA
            let transform = frame.camera.transform.columns.3
            let devicePosition = simd_float3(x: transform.x, y: transform.y, z: transform.z)
            let deviceOrientation = frame.camera.eulerAngles.y
            let newPosition = ApproxLocation(coordinates: CGPoint(x: CGFloat(devicePosition.x), y: CGFloat(devicePosition.z)), heading: deviceOrientation, floor: self.currentFloor!, approxRadius: 0, approxAngle: 0)
            self.locationObserver?.onLocationUpdate(newPosition)
        }
    }
}

extension Float {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}
