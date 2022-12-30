//
//  FloorMapView.swift
//  
//
//  Created by Rosario Galioto on 20/08/22.
//

import UIKit
import MapKit
import ARKit

public class FloorMapView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var mapView: MKMapView!
    private var mapOverlay: MapOverlay?
    private var whiteOverlay: MapOverlay?
    private var userAnnotation: UserPositionAnnotation?
    private var userAnnotationView: MKAnnotationView?
    private var originMap: CLLocationCoordinate2D? // origin coord. of the floor map
    private var endMap: CLLocationCoordinate2D? // end coord. of the floor map
    private var widthCoord: Double? // width of the floor map (difference between longitudes)
    private var heightCoord: Double? // height of the floor map (difference between latitudes)
    private var userHeading: Float? // heading relative to the origin of floor map
    private var cameraHeading: Float = 0 // heading relative to the north (by default it points to north)
    private var floorMapExist = false
    private var posNumber = 0 // n. of times we receive the user position
    private var followUser = false
    private var buildingAnnotation: BuildingAnnotation?
    private var currentFloor: Floor?
    private let whiteMultiplier = 5.0 // white overlay size multiplier with respect to floor map overlay
    /* Indoor Map = Floor Map Overlay + White Overlay */
    
    /// init called when using a FloorMapView in storyboards
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }

    /// init called when using a FloorMapView programatically
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }

    func initSubviews() {
        let nib = UINib(nibName: "FloorMapView", bundle: Bundle.module)
        nib.instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)

        mapView.delegate = self
        self.mapView.isHidden = true
        mapView.isPitchEnabled = false // to remove pitch that enable 3D view
        mapView.subviews[2].isHidden = true //to remove Apple Logo from the map view
    }
    
    //MARK: Utility
    
    /// Centers the map camera in the user's position
    public func centerToUserPosition() {
        if(self.userAnnotation != nil) {
            self.mapView.centerCoordinate = userAnnotation!.coordinate
        }
    }
    
    /// The map camera begins to follow the user's position. Any gesture on the map is blocked
    public func startFollowUser() {
        if(self.userAnnotation != nil) {
            self.followUser = true
        }
    }
    
    /// The map camera stops to follo the user's position.
    public func stopFollowUser() {
        if(self.userAnnotation != nil) {
            self.followUser = false
        }
    }
    
    /// Manages the change of Floor, modifying the visual elements of the map.
    private func changeFloorMap(newFloor: Floor) {
        self.currentFloor = newFloor
        self.posNumber = 0
        // remove previous overlays
        self.mapView.removeOverlays(self.mapView.overlays)
        if(self.buildingAnnotation != nil) { self.mapView.removeAnnotation(self.buildingAnnotation!) }
        self.userAnnotationView?.isHidden = false
            
        // if we have the image for the floor plan
        if(newFloor.floorMap != nil) {
            self.floorMapExist = true
            self.mapView.isHidden = false
            
            // limit zoom-in
            let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 5)
            mapView.setCameraZoomRange(zoomRange, animated: false)
            
            let originCoord = newFloor.building.coord
            let nMapPoints = MKMapPointsPerMeterAtLatitude(originCoord.latitude)
            // Floor Map overlay
            self.mapOverlay = MapOverlay(coordinate: originCoord, size: MKMapSize(width: Double(newFloor.maxWidth)*nMapPoints, height: Double(newFloor.maxHeight)*nMapPoints), image: newFloor.floorMap!)

            // variables that we will need later to plot the user's position in the Floor Map
            self.originMap = MKMapPoint(x: self.mapOverlay!.boundingMapRect.minX, y: self.mapOverlay!.boundingMapRect.minY).coordinate
            self.endMap = MKMapPoint(x: self.mapOverlay!.boundingMapRect.maxX, y: self.mapOverlay!.boundingMapRect.maxY).coordinate
            self.widthCoord = abs(self.originMap!.longitude - self.endMap!.longitude)
            self.heightCoord = abs(self.originMap!.latitude - self.endMap!.latitude)
            
            // a bigger white overlay that encompasses the floor map
            self.whiteOverlay = MapOverlay(
                coordinate: CLLocationCoordinate2D(
                    latitude: self.mapOverlay!.coordinate.latitude+heightCoord!*whiteMultiplier/2,
                    longitude: self.mapOverlay!.coordinate.longitude-widthCoord!*whiteMultiplier/2),
                size: MKMapSize(width: mapOverlay!.size.width*whiteMultiplier, height: mapOverlay!.size.height*whiteMultiplier),
                image: UIImage.imageWithColor(color: .white))
            
            mapView.addOverlay(whiteOverlay!)
            mapView.addOverlay(mapOverlay!)
        }
        else {
            self.floorMapExist = false
            self.mapView.isHidden = true
        }
    }
    
    /// Calculates the user's position within the drawn map. Basically converts the position from the Floor coordinate system in real-world coordinates (lat, long)
    private func moveUserAnnotation(x:Float, y:Float, heading:Float, widthFloorInMeters:Float, heightFloorInMeters:Float) {
        let offsetX = (Double(x) * self.widthCoord!) / Double(widthFloorInMeters)
        let offsetY = (Double(y) * self.heightCoord!) / Double(heightFloorInMeters)
        self.userHeading = heading

        if(userAnnotation == nil) {
            userAnnotation = UserPositionAnnotation()
            userAnnotation!.title = "Position"
            userAnnotation!.coordinate = CLLocationCoordinate2D(latitude: self.originMap!.latitude - offsetY, longitude: self.originMap!.longitude + offsetX)
            mapView.addAnnotation(userAnnotation!)
        }
        else { // if the user mark already exists
            userAnnotation!.coordinate = CLLocationCoordinate2D(latitude: self.originMap!.latitude - offsetY, longitude: self.originMap!.longitude + offsetX)
            // angles in the opposite direction (-)
            // rotate the marker orientation also considering the map camera orientation
            userAnnotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(-(self.userHeading! + self.cameraHeading)))
            userAnnotationView?.image = userAnnotation!.image // force update of the img, 'cause it disappears if the app goes in background
        }
        
        // discards the first positions because they aren't precise
        if(self.posNumber == 2) {
            self.mapView.centerToLocation(CLLocation(latitude: userAnnotation!.coordinate.latitude, longitude: userAnnotation!.coordinate.longitude))
            self.posNumber = self.posNumber + 1
        }
        else if(self.posNumber < 2) { self.posNumber = self.posNumber + 1 }
        
        if(self.followUser) { // the map camera starts to follow user position
            self.mapView.centerCoordinate = userAnnotation!.coordinate
        }
    }
    
    /// Create/Retrieve the Building annotation
    private func getBuildingAnnotation() -> BuildingAnnotation {
        let annotation = self.buildingAnnotation != nil ? self.buildingAnnotation! : BuildingAnnotation()
        annotation.title = self.currentFloor?.building.name ?? "Building"
        annotation.coordinate = self.mapOverlay!.coordinate
        annotation.subtitle = "Current Floor: \(self.currentFloor?.name ?? "unknown")"
        return annotation
    }
    
    /// Shows the indoor map  that was hidden
    private func revealIndoorMap() {
        self.mapView.removeAnnotation(self.buildingAnnotation!)
        self.mapView.addOverlay(self.whiteOverlay!)
        self.mapView.addOverlay(self.mapOverlay!)
        self.userAnnotationView!.isHidden = false
        self.mapView.centerToLocation(CLLocation(latitude: userAnnotation!.coordinate.latitude, longitude: userAnnotation!.coordinate.longitude))
    }
}
    

//MARK: MKMapViewDelegate

extension FloorMapView: MKMapViewDelegate {
    /// Method called to render overlays
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MapOverlayRenderer(overlay: overlay, image: (overlay as! MapOverlay).image)
    }
    
    /// Method called to render annotations
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if(annotation is UserPositionAnnotation) {
            let identifier = "UserAnnotation"
            self.userAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if userAnnotationView == nil {
                userAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                userAnnotationView!.canShowCallout = false
                userAnnotationView!.image = (annotation as! UserPositionAnnotation).image
            } else {
                userAnnotationView!.annotation = annotation
            }
            // angles in the opposite direction (-)
            // rotate the marker orientation also considering the map camera orientation
            userAnnotationView!.transform = CGAffineTransform(rotationAngle: CGFloat(-(self.userHeading! + self.cameraHeading)))
            return userAnnotationView
        }
        else {
            let identifier = "BuildingAnnotation"
            var buildingAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if(buildingAnnotationView == nil) {
                buildingAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                // to enable click on the annotation
                buildingAnnotationView!.canShowCallout = true
                let calloutBtn = UIButton(type: .detailDisclosure)
                calloutBtn.setImage(UIImage(systemName: "map"), for: .normal)
                buildingAnnotationView!.rightCalloutAccessoryView = calloutBtn
            }
            else { buildingAnnotationView?.annotation = annotation }
            return buildingAnnotationView
        }
    }
    
    /// Method called to manage the touch of the annotation callout
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        revealIndoorMap()
    }
    
    /// Method called to manage camera zoom/rotation movements
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        // if we zoom out, we hide the Indoor Map and show an annotation on the Building
        if(self.mapOverlay != nil && self.whiteOverlay != nil) {
            if(mapView.region.span.latitudeDelta > self.heightCoord!*(whiteMultiplier-1) || mapView.region.span.longitudeDelta > self.widthCoord!*(whiteMultiplier-1)) {
                self.mapView.removeOverlay(self.mapOverlay!)
                self.mapView.removeOverlay(self.whiteOverlay!)
                self.userAnnotationView?.isHidden = true
                self.buildingAnnotation = getBuildingAnnotation()
                self.mapView.addAnnotation(self.buildingAnnotation!)
                mapView.setCameraBoundary(nil, animated: true)
            }
            // when we are in the zoom level of the Indoor Map, we set map boundaries
            else if(!self.mapView.overlays.isEmpty){
                mapView.setCameraBoundary(
                    MKMapView.CameraBoundary(mapRect: self.mapOverlay!.boundingMapRect),
                  animated: true)
            }
        }
        let mapHeading = self.mapView.camera.heading;
        self.cameraHeading = Float(mapHeading * 3.14 / 180) // convert to rad
   }
}


//MARK: Custom Classes/Extensions

extension MKMapView {
  func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 7) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: false)
  }
}

class MapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var image: UIImage
    var size: MKMapSize
    var boundingMapRect: MKMapRect

    init(coordinate: CLLocationCoordinate2D, size: MKMapSize, image: UIImage) {
        self.size = size
        self.coordinate = coordinate
        self.image = image
        let mapSize = size
        boundingMapRect = MKMapRect(origin: MKMapPoint(self.coordinate), size: mapSize)
        super.init()
    }
}

class MapOverlayRenderer: MKOverlayRenderer {
    let overlayImage: UIImage
    
    init(overlay: MKOverlay, image: UIImage) {
        self.overlayImage = image
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let imageReference = overlayImage.cgImage else { return }
        let rect = self.rect(for: overlay.boundingMapRect)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -rect.size.height)
        context.draw(imageReference, in: rect)
    }
}

// Extension that enables the creation of an UIImage filled with a color
extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

class UserPositionAnnotation: MKPointAnnotation {
    var image = UIImage(named: "icon-pos", in: .module, compatibleWith: nil)
}

class BuildingAnnotation: MKPointAnnotation { }


//MARK: LocationObserver Methods

extension FloorMapView: LocationObserver {
    
    public func onLocationUpdate(_ newLocation: ApproxLocation) {
        if(self.floorMapExist) {
            moveUserAnnotation(x: Float(newLocation.coordinates.x), y: Float(newLocation.coordinates.y), heading: newLocation.heading, widthFloorInMeters: newLocation.floor.maxWidth, heightFloorInMeters: newLocation.floor.maxHeight)
        }
    }
    
    public func onBuildingChanged(_ newBuilding: Building) {
    }
    
    public func onFloorChanged(_ newFloor: Floor) {
        changeFloorMap(newFloor: newFloor)
    }
    
    public func onMeasurementMarkerFound(imageAnchor: ARImageAnchor, marker: Marker) {
        // nothing to do
    }
    
    public func onNewFrame(frame: ARFrame) {
        // nothing to do
    }
}

