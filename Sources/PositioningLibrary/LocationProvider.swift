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
    private var locationObservers: [LocationObserver] // lista di LocationObserver che andremo a notificare con gli aggiornamenti
    private var floorMapView: FloorMapView!
    private var originFixed = false
    
    //MARK: Setup

    public init(arView: ARView, markers: [Marker]) {
        self.markers = markers
        self.arView = arView
        self.locationObservers = []
    }
    
    public init(arView: ARView, jsonName: String) {
        self.markers = LocationProvider.loadFromJSON(forName: jsonName)
        self.arView = arView
        self.locationObservers = []
    }
        
    public func addLocationObserver(locationObserver: LocationObserver) {
        self.locationObservers.append(locationObserver)
    }
    
    public func removeLocationObserver(locationObserver: LocationObserver) {
        self.locationObservers = self.locationObservers.filter{$0 !== locationObserver}
    }
            
    public func start(debug: Bool = false) {
        // Set ARView delegate so we can define delegate methods in this controller
        self.arView.session.delegate = self

        // Forgo automatic configuration to do it manually instead
        self.arView.automaticallyConfigureSession = false

        // Show statistics if desired
        if(debug) { self.arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins] }

        // Disable any unneeded rendering options
        self.arView.renderOptions = [.disableCameraGrain, .disableHDR, .disableMotionBlur, .disableDepthOfField, .disableFaceMesh, .disablePersonOcclusion, .disableGroundingShadows, .disableAREnvironmentLighting]

        // Instantiate configuration object
        let configuration = ARWorldTrackingConfiguration()

        // Both trackingImages and maximumNumberOfTrackedImages are required
        configuration.maximumNumberOfTrackedImages = self.markers.count //TODO a quanto?
        configuration.detectionImages = loadReferenceMarkers()
        
        // Run an ARView session with the defined configuration object
        self.arView.session.run(configuration)
    }
    
    private static func loadFromJSON(forName fileName: String) -> [Marker] {
        let jsonParser = CustomJsonParser(forName: fileName)
        return jsonParser.getMarkers()
    }
    
    public func showFloorMap(_ cgRect: CGRect) {
        if(self.floorMapView == nil) {
            floorMapView = FloorMapView(frame: cgRect)
            arView.addSubview(floorMapView)
            addLocationObserver(locationObserver: floorMapView)
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
    
    public func startFollowUser() {
        self.floorMapView?.startFollowUser()
    }
    
    public func stopFollowUser() {
        self.floorMapView?.stopFollowUser()
    }
    
    //MARK: Utility
    
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
    
    // trova il relativo Marker e inoltre avvisa se cambiamo Floor/Building
    private func findMarkByID(markerID: String) -> Marker? {
        for marker in markers {
            if marker.id == markerID {
                let floor = marker.location.floor
                let building = floor.building
                if(self.currentBuilding == nil || self.currentBuilding?.id != building.id) { // se currentBuilding = nil anche currentFloor lo è, poichè non abbiamo ancora visitato nessun Building
                    self.currentBuilding = building
                    notifyBuildChanged(newBuilding: self.currentBuilding!)
                    self.currentFloor = floor
                    notifyFloorChanged(newFloor: self.currentFloor!)
                    removeAllAnchors(markerID)
                }
                else if(self.currentFloor?.number != floor.number) {
                    self.currentFloor = floor
                    notifyFloorChanged(newFloor: self.currentFloor!)
                    removeAllAnchors(markerID)
                }
                return marker
            }
        }
        return nil
    }
    
    //quando cambiamo floor andiamo ad eliminare tutte le ancore precedente, tranne l'ultima aggiunta (quella che è nel nuovo floor)
    private func removeAllAnchors(_ lastMarkerID: String) {
        let allAnchors = self.arView.session.currentFrame!.anchors
        for anchor in allAnchors {
            if(anchor.name != lastMarkerID) {
                self.arView.session.remove(anchor: anchor)
            }
        }
    }
    
    private func notifyBuildChanged(newBuilding: Building) {
        for locationObserver in self.locationObservers {
            locationObserver.onBuildingChanged(newBuilding)
        }
    }
    
    private func notifyFloorChanged(newFloor: Floor) {
        for locationObserver in self.locationObservers {
            locationObserver.onFloorChanged(newFloor)
        }
    }
    
    private func notifyLocationUpdate(newLocation: ApproxLocation) {
        for locationObserver in self.locationObservers {
            locationObserver.onLocationUpdate(newLocation)
        }
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
    
    // metodo richiamato quando continuo a vedere lo stesso Marker
//    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        //TODO, cosa succede se si inquadrano più marker? Come ci dobbiamo comportare?
//        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
//        if let imgId = imageAnchor.referenceImage.name {
//            let markerFound = findMarkByID(markerID: imgId)
//            if markerFound != nil {
//                if imageAnchor.isTracked {
//                 print(getSCARotationY(imageAnchor))
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
        let alpha = -(alpha_a - alpha_m)
//        print("alpha_a: \(alpha_a)    alpha_m: \(alpha_m)  -> alpha: \(alpha)")
        
        let (x_m, y_m) = (Float(location.coordinates.x), Float(location.coordinates.y))
        let (x_a, z_a) = getMarkerSCACoordinates(imageAnchor)
//        print("x_a:\(x_a)  z_a:\(z_a)")
        
        let x_b = x_a * cos(alpha) - z_a * sin(alpha)
        let y_b = x_a * sin(alpha) + z_a * cos(alpha)
        
        let x_t = x_m - x_b
        let y_t = y_m - y_b
//        print("x_t:\(x_t)  y_t:\(y_t)")
        
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
//        return (node.rotation.y * node.rotation.w) // in radianti
//        return atan2(imageAnchor.transform[2][0], imageAnchor.transform[2][2])
        let q = node.orientation
        return -atan2f((2*q.y*q.w)-(2*q.x*q.z), 1-(2*pow(q.y,2))-(2*pow(q.z,2)))
    }
    
    private func calculateDevicePose(_ frame: ARFrame) {
        if(originFixed) { // solo se abbiamo trovato un marker e abbiamo fixato l'origine SCA
            let transform = frame.camera.transform.columns.3
            let devicePosition = simd_float3(x: transform.x, y: transform.y, z: transform.z)
            let deviceOrientation = frame.camera.eulerAngles.y
            let newPosition = ApproxLocation(coordinates: CGPoint(x: CGFloat(devicePosition.x), y: CGFloat(devicePosition.z)), heading: deviceOrientation, floor: self.currentFloor!, approxRadius: 0, approxAngle: 0)
            notifyLocationUpdate(newLocation: newPosition)
        }
    }
}

extension Float {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}
