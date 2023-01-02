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
import WorldRepresentationLibrary

public class LocationProvider: NSObject, ARSessionDelegate {
    private var markers: [Marker]
    private var userLocation: LocalLocation?
    private var currentBuilding: Building?
    private var currentFloor: Floor?
    private var arView: ARView
    private var locationObservers: [ArLocationObserver] // list of Observers who will be notified of the change of position
    private var floorMapView: FloorMapView?
    private var originFixed = false // true if AR Origin==Floor Origin
    
    // AR Accuracy variables
    private var insufficentFeatures = 0
    private var excessiveMotion = 0
    private var startingTime: Date?
    
    private var approxFloor: Int = -1
    
    //MARK: Setup

    /// Initializes the LocationProvider with the ARView and a list of markers
    public init(arView: ARView, markers: [Marker]) {
        self.markers = markers
        self.arView = arView
        self.locationObservers = []
    }
    
    /// Initializes the LocationProvider with the ARView and a json file
    public init(arView: ARView, jsonName: String) {
        self.markers = LocationProvider.loadFromJSON(forName: jsonName)
        self.arView = arView
        self.locationObservers = []
    }
    
    /// Adds the specified LocationObserver to the list of observers who will be notified
    public func addLocationObserver(locationObserver: ArLocationObserver) {
        self.locationObservers.append(locationObserver)
    }
    
    /// Removes the specified LocationObserver from the list of observers
    public func removeLocationObserver(locationObserver: ArLocationObserver) {
        self.locationObservers = self.locationObservers.filter{$0 !== locationObserver}
    }
     
    /// Starts the position calculation
    /// - Parameter debug: Indicates whether or not to show the anchors of the Ar Session
    public func start(debug: Bool = false) {
        // Set ARView delegate so we can define delegate methods in this controller
        self.arView.session.delegate = self
        self.arView.automaticallyConfigureSession = false
        // Show statistics if desired
        if(debug) { self.arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins] }
        // Disable any unneeded rendering options
        self.arView.renderOptions = [.disableCameraGrain, .disableHDR, .disableMotionBlur, .disableDepthOfField, .disableFaceMesh, .disablePersonOcclusion, .disableGroundingShadows, .disableAREnvironmentLighting]
        let configuration = ARWorldTrackingConfiguration()
        configuration.maximumNumberOfTrackedImages = self.markers.count // TODO: upload only markers of the near building (using the user gps signal)
        configuration.detectionImages = loadReferenceMarkers()
        self.arView.session.run(configuration)
    }
    
//    /// Shows in the cgRect defined, the Map of the current floor (if the map exists)
//    /// - Parameter cgRect: Defines the size and position of the map to show
//    public func showFloorMap(_ cgRect: CGRect) {
//        if(self.floorMapView == nil) {
//            floorMapView = FloorMapView(frame: cgRect)
//            arView.addSubview(floorMapView!)
//            addLocationObserver(locationObserver: floorMapView!)
//        }
//        else {
//            print("An FloorMap already exist")
//        }
//    }
//
//    /// Hides the Map
//    public func hideFloorMap() {
//        if(self.floorMapView != nil) {
//            self.floorMapView!.removeFromSuperview()
//            self.floorMapView = nil
//        }
//        else {
//            print("Any FloorMap exist")
//        }
//    }
//
//    /// Centers the map camera in the user's position
//    public func centerToUserPosition() {
//        self.floorMapView?.centerToUserPosition()
//    }
//
//    /// The map camera starts following the user's position. When this option is on, it's not possible to move the camera
//    public func startFollowUser() {
//        self.floorMapView?.startFollowUser()
//    }
//
//    /// The map camera stops following the user's position.
//    public func stopFollowUser() {
//        self.floorMapView?.stopFollowUser()
//    }
    
    
    //MARK: Utility
    
    private static func loadFromJSON(forName fileName: String) -> [Marker] {
        let jsonParser = CustomJsonParser(forName: fileName)
        return jsonParser.getMarkers()
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
    
    /// Find the Marker with markerID if it exists, otherwise it returns nil. It also notifies if the user changes Floor or Building
    private func findMarkByID(markerID: String) -> Marker? {
        for marker in markers {
            if marker.id == markerID {
                resetFloorTimer() // reset to 0 the approxFloor and start a new timer
                let floor = marker.location.floor
                let building = floor.building!
                // the user visit a new building or a different one
                if(self.currentBuilding == nil || self.currentBuilding?.id != building.id) {
                    self.currentBuilding = building
                    notifyBuildChanged(newBuilding: self.currentBuilding!)
                    self.currentFloor = floor
                    notifyFloorChanged(newFloor: self.currentFloor!)
                    removeAllAnchors(markerID)
                }
                // the user visit a different floor of the same building
                else if(self.currentFloor?.id != floor.id) {
                    self.currentFloor = floor
                    notifyFloorChanged(newFloor: self.currentFloor!)
                    removeAllAnchors(markerID)
                }
                return marker
            }
        }
        return nil
    }
    
    /// The first time (-1) starts a timer that increments approxFloor, the next time that is called it simple reset approxFloor
    private func resetFloorTimer() {
        if(self.approxFloor == -1) {
            self.approxFloor = 0
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
                self.approxFloor += 1
            }
        }
        else { self.approxFloor = 0 }
    }
    
    /// Removes all the previous anchors, except the last one (lastMarkerID), that is in the new floor
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
    
    private func notifyLocationUpdate(newLocation: LocalLocation) {
        for locationObserver in self.locationObservers {
            locationObserver.onLocationUpdate(newLocation)
        }
    }
    
    //MARK: AR Delegate Methods
    
    /// Method called when a Marker is recognized for the first time
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // TODO: what happen if two or more Markers are recognized?
        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
        if let imgId = imageAnchor.referenceImage.name {
            let markerFound = findMarkByID(markerID: imgId)
            if markerFound != nil {
                print("Found: \(markerFound!.id) at Location <\(markerFound!.location)>")
                fixAROrigin(imageAnchor: imageAnchor, location: markerFound!.location)
                // reset accuracy variables
                self.insufficentFeatures = 0
                self.excessiveMotion = 0
                self.startingTime = Date()
            }
            else {
                print("Nothing found")
            }
        }
    }
    
    /// Method called when we continue to recognize a marker already seen
//    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        guard let imageAnchor = anchors[0] as? ARImageAnchor else { return }
//        if let imgId = imageAnchor.referenceImage.name {
//            let markerFound = findMarkByID(markerID: imgId)
//            if markerFound != nil {
//                if imageAnchor.isTracked {
//                } else {
//                    print("The anchor for \(markerFound!.id) is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.")
//                }
//            }
//            else {
//                print("Nothing found")
//            }
//        }
//    }
    
    /// Method called at each frame, even when we don't frame any marker
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        calculateDevicePose(frame)
    }

    
    //MARK: Position Calculation
    
    /// Moves the AR Origin so that it matches the Floor Origin
    private func fixAROrigin(imageAnchor: ARImageAnchor, location: LocalLocation) {
        let alpha_a = getSCARotationY(imageAnchor)
        let alpha_m = location.heading
        let alpha = -(alpha_a - alpha_m)
        
        let (x_m, y_m) = (Float(location.position.x), Float(location.position.y))
        let (x_a, z_a) = getMarkerSCACoordinates(imageAnchor)
        
        let x_b = x_a * cos(alpha) - z_a * sin(alpha)
        let y_b = x_a * sin(alpha) + z_a * cos(alpha)
        
        let x_t = x_m - x_b
        let y_t = y_m - y_b
        
        // rotate ar origin
        let cosa = cos(alpha)
        let sina = sin(alpha)
        let rotationMatrix = simd_float4x4(
            SIMD4(cosa, 0, -sina, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(sina, 0, cosa, 0),
            SIMD4(0, 0, 0, 1)
        )
        self.arView.session.setWorldOrigin(relativeTransform: rotationMatrix)
        
        // move ar origin
        let translationMatrix = simd_float4x4(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(-x_t, imageAnchor.transform.columns.3.y, -y_t, 1) // translation: x=-x_t, z=-y_t, y=height of the marker ('cause we don't care)
        )
        let newWorldTransform = simd_mul(rotationMatrix, translationMatrix)
        self.arView.session.setWorldOrigin(relativeTransform: newWorldTransform)
        originFixed = true
    }
    
    /// Returns the coordiates (x,z) of the Marker Image in the AR Coordinate System
    private func getMarkerSCACoordinates(_ imageAnchor: ARImageAnchor)-> (Float, Float) {
        let coordinates = imageAnchor.transform.columns.3
        return (coordinates.x, coordinates.z) //(x_a, z_a)
    }
        
    /// Returns the rotation of the y axis relative to the AR Origin
    private func getSCARotationY(_ imageAnchor: ARImageAnchor) -> Float{
        let node = SCNNode()
        node.transform = SCNMatrix4(imageAnchor.transform)
        let q = node.orientation
        return -atan2f((2*q.y*q.w)-(2*q.x*q.z), 1-(2*pow(q.y,2))-(2*pow(q.z,2)))
    }
    
    /// Calculates the user's position within relative to the AR Origin (that now matches with the Floor Origin). It uses dead reckoning methods.
    private func calculateDevicePose(_ frame: ARFrame) {
        if(originFixed) { // only if the ar origin is fixed
            let transform = frame.camera.transform.columns.3
            let devicePosition = simd_float3(x: transform.x, y: transform.y, z: transform.z)
            let deviceOrientation = frame.camera.eulerAngles.y
            
            // get Ar Camera noise level
            switch frame.camera.trackingState {
                case ARCamera.TrackingState.limited(.insufficientFeatures): self.insufficentFeatures+=1
                case ARCamera.TrackingState.limited(.excessiveMotion): self.excessiveMotion+=1
                default: ()
            }
            // calculates accuracy of Ar Position
            let approxPosition = (Float(self.insufficentFeatures + self.excessiveMotion) + Float(abs(self.startingTime?.timeIntervalSinceNow ?? 0)))/100
            let approxHeading = (Float(self.insufficentFeatures + self.excessiveMotion) + Float(abs(self.startingTime?.timeIntervalSinceNow ?? 0)))/100
            
            let newPosition = LocalLocation(position: CGPoint(x: CGFloat(devicePosition.x), y: CGFloat(devicePosition.z)), positionAltitude: Float(devicePosition.y), heading: deviceOrientation, ts: Date(), approxPosition: approxPosition, approxHeading: approxHeading, floor: self.currentFloor!, approxFloor: self.approxFloor)
            notifyLocationUpdate(newLocation: newPosition)
        }
    }
}
