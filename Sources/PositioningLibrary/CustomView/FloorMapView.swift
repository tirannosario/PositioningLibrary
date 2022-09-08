//
//  FloorMapView.swift
//  
//
//  Created by Rosario Galioto on 20/08/22.
//

import UIKit
import MapKit

public class FloorMapView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var mapView: MKMapView!
    private var mapOverlay: MapOverlay?
    private var whiteOverlay: MapOverlay?
    private var userAnnotation: UserPositionAnnotation?
    private var userAnnotationView: MKAnnotationView?
    private var originMap: CLLocationCoordinate2D? // coord. punto in basso a sx della mappa
    private var endMap: CLLocationCoordinate2D? // coord. punto in alto a dx della mappa
    private var widthCoord: Double? // larghezza (diff. tra longitudine delle coord.)
    private var heightCoord: Double? // altezza (diff. tra latitudine delle coord.)
    private var userHeading: Float? // orientamento dell'utente
    private var cameraHeading: Float = 0// l'oriantamento della camera della mappa rispetto al Nord
    private var floorMapExist = false
    private var posNumber = 0 // numero di volte che riceviamo la pos.
    private var followUser = false
    private var buildingAnnotation: BuildingAnnotation?
    private var currentFloor: Floor?
    private let whiteMultiplier = 5.0 // moltiplicatore dell'indoor map per disegnare l'overlay bianco
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }

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
        mapView.isPitchEnabled = false // per rimuovere gesture per mappa 3d
        mapView.subviews[2].isHidden = true // per rimuovere logo Apple dalla mappa
    }
    
    //MARK: Utility
    /// La camera della mappa comincia a seguire la posizione dell'uente. Qualsiasi gesture sulla mappa viene ignorata
    public func startFollowUser() {
        self.followUser = true
    }
    
    public func stopFollowUser() {
        self.followUser = false
    }
    
    /// Gestisce il cambiamento di Floor, modificando gli elementi della mappa. Quindi mostra la Indoor Map di newFloor (se disponibile)
    private func changeFloorMap(newFloor: Floor) {
        self.currentFloor = newFloor
        self.posNumber = 0
        // rimuovo overlays precedenti
        self.mapView.removeOverlays(self.mapView.overlays)
        if(self.buildingAnnotation != nil) { self.mapView.removeAnnotation(self.buildingAnnotation!) }
        self.userAnnotationView?.isHidden = false
            
        // se abbiamo l'img per quel piano
        if(newFloor.floorMap != nil) {
            self.floorMapExist = true
            self.mapView.isHidden = false
            
            // limitiamo il zoom-in
            let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 5)
            mapView.setCameraZoomRange(zoomRange, animated: false)
            
            let originCoord = newFloor.building.coord
            let nMapPoints = MKMapPointsPerMeterAtLatitude(originCoord.latitude)
            // overlay della Indoor Map
            self.mapOverlay = MapOverlay(coordinate: originCoord, size: MKMapSize(width: Double(newFloor.maxWidth)*nMapPoints, height: Double(newFloor.maxHeight)*nMapPoints), image: newFloor.floorMap!)

            // calcoliamo delle variabili che ci serviranno dopo per disegnare la posizione dell'utente nell'Indoor Map
            self.originMap = MKMapPoint(x: self.mapOverlay!.boundingMapRect.minX, y: self.mapOverlay!.boundingMapRect.minY).coordinate
            self.endMap = MKMapPoint(x: self.mapOverlay!.boundingMapRect.maxX, y: self.mapOverlay!.boundingMapRect.maxY).coordinate
            self.widthCoord = abs(self.originMap!.longitude - self.endMap!.longitude)
            self.heightCoord = abs(self.originMap!.latitude - self.endMap!.latitude)
            
            // creiamo uno sfondo bianco più grande dell'Indoor Map
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
    
    /// calcola la posizione dell'utente dell'utente all'interno della mappa disegnata
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
        else { // se già il marker esiste
            userAnnotation!.coordinate = CLLocationCoordinate2D(latitude: self.originMap!.latitude - offsetY, longitude: self.originMap!.longitude + offsetX)
            // gli angoli in senso opposto (-)
            // ruotiamo il marker considerando anche l'orientamento della camera della mappa
            userAnnotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(-(self.userHeading! + self.cameraHeading)))
            userAnnotationView?.image = userAnnotation!.image // per forzare l'aggiornamento dell'img, poichè veniva rimossa quando l'app passava in background
        }
        
        // scartiamo le prime pos. poichè poco precise, alla terza mostriamo la pos. dell'utente corretta
        if(self.posNumber == 2) {
            self.mapView.centerToLocation(CLLocation(latitude: userAnnotation!.coordinate.latitude, longitude: userAnnotation!.coordinate.longitude))
            self.posNumber = self.posNumber + 1
        }
        else if(self.posNumber < 2) { self.posNumber = self.posNumber + 1 }
        
        if(self.followUser) { // la camera seguirà l'utente
            self.mapView.centerCoordinate = userAnnotation!.coordinate
        }
    }
    
    /// crea/recupera l'Annotation per mostrare il Building
    private func getBuildingAnnotation() -> BuildingAnnotation {
        let annotation = self.buildingAnnotation != nil ? self.buildingAnnotation! : BuildingAnnotation()
        annotation.title = self.currentFloor?.building.name ?? "Building"
        annotation.coordinate = self.mapOverlay!.coordinate
        annotation.subtitle = "Current Floor: \(self.currentFloor?.name ?? "unknown")"
        return annotation
    }
    
    /// mostra l'indoor map che era stata nascosta
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
    // per renderizzare overlay
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MapOverlayRenderer(overlay: overlay, image: (overlay as! MapOverlay).image)
    }
    
    // per renderizzare annotation
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
            // gli angoli in senso opposto (-)
            // ruotiamo il marker considerando anche l'orientamento della camera della mappa
            userAnnotationView!.transform = CGAffineTransform(rotationAngle: CGFloat(-(self.userHeading! + self.cameraHeading)))
            return userAnnotationView
        }
        else {
            let identifier = "BuildingAnnotation"
            var buildingAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if(buildingAnnotationView == nil) {
                buildingAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                buildingAnnotationView!.canShowCallout = true
                let calloutBtn = UIButton(type: .detailDisclosure)
                calloutBtn.setImage(UIImage(systemName: "map"), for: .normal)
                buildingAnnotationView!.rightCalloutAccessoryView = calloutBtn
            }
            else { buildingAnnotationView?.annotation = annotation }
            return buildingAnnotationView
        }
    }
    
    /// per gestire tocco callout Annotation
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        revealIndoorMap()
    }
    
    /// per gestire spostamenti di camera/zoom/rotazione
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        // se facciamo zoom-out, nascondiamo l'Indoor Map e mostriamo un Annotation sul Building
        if(self.mapOverlay != nil && self.whiteOverlay != nil) {
            if(mapView.region.span.latitudeDelta > self.heightCoord!*(whiteMultiplier-1) || mapView.region.span.longitudeDelta > self.widthCoord!*(whiteMultiplier-1)) {
                self.mapView.removeOverlay(self.mapOverlay!)
                self.mapView.removeOverlay(self.whiteOverlay!)
                self.userAnnotationView?.isHidden = true
                self.buildingAnnotation = getBuildingAnnotation()
                self.mapView.addAnnotation(self.buildingAnnotation!)
                mapView.setCameraBoundary(nil, animated: true)
            }
            // se torniamo al livello di zoom della vista Indoor
            else if(!self.mapView.overlays.isEmpty){
                mapView.setCameraBoundary(
                    MKMapView.CameraBoundary(mapRect: self.mapOverlay!.boundingMapRect),
                  animated: true)
            }
        }
        let mapHeading = self.mapView.camera.heading; // orientamento rispetto al nord
        self.cameraHeading = Float(mapHeading * 3.14 / 180) //  in rad
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
        let mapSize = size // change these numbers for the width and height of your image
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

class UserPositionAnnotation: MKPointAnnotation { var image = UIImage(named: "icon-pos", in: .module, compatibleWith: nil)}

class BuildingAnnotation: MKPointAnnotation { }


//MARK: LocationObserver Methods

extension FloorMapView: LocationObserver {
    public func onLocationUpdate(_ newLocation: ApproxLocation) {
        // se abbiamo l'img per quel Floor
        if(self.floorMapExist) {
            moveUserAnnotation(x: Float(newLocation.coordinates.x), y: Float(newLocation.coordinates.y), heading: newLocation.heading, widthFloorInMeters: newLocation.floor.maxWidth, heightFloorInMeters: newLocation.floor.maxHeight)
        }
    }
    
    public func onBuildingChanged(_ newBuilding: Building) {
    }
    
    public func onFloorChanged(_ newFloor: Floor) {
        changeFloorMap(newFloor: newFloor)
    }
}

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

