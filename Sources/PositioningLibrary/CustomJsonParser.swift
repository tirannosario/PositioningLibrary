//
//  CustomJsonParser.swift
//
//  Created by Rosario Galioto on 24/08/22.
//

import Foundation
import CoreGraphics
import UIKit
import MapKit


public class CustomJsonParser {
    private var myBuilding: [Building]
    private var myFloors: [Floor]
    private var myMarkers: [Marker]
    
    public init(forName fileName: String) {
        myBuilding = []
        myFloors = []
        myMarkers = []
        loadFromJSON(fileName: fileName)
    }
    
    public func getMarkers() -> [Marker] {
        return myMarkers
    }
    
    private func loadFromJSON(fileName: String) {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let dictionary = object as? [String: AnyObject] {
                    if let buildings = dictionary["buildings"] as? [Any] {
                        for building in buildings {
                            let b = building as! [String:Any]
                            myBuilding.append(Building(id: b["id"] as! String,
                                                       name: b["name"] as! String, coord: CLLocationCoordinate2D(latitude: b["latitude"] as! Double, longitude: b["longitude"] as! Double)))
                        }
                    }
                    else { throw NotValid.noBuildings }
                    
                    if let floors = dictionary["floors"] as? [Any] {
                        for floor in floors {
                            let f = floor as! [String:Any]
                            myFloors.append(Floor(id: f["id"] as! String,
                                                  name: f["name"] as! String,
                                                  number: f["number"] as! Int,
                                                  building: getBuilding(buildingID: f["building"] as! String),
                                                  maxWidth: getFloat(f["maxWidth"]!),
                                                  maxHeight: getFloat(f["maxHeight"]!)))
                        }
                    }
                    else { throw NotValid.noFloors }
                    
                    if let markers = dictionary["markers"] as? [Any] {
                        for marker in markers {
                            let m = marker as! [String:Any]
                            if let l = m["location"] as? [String:Any] {
                            let location = Location(coordinates: CGPoint(x: l["x"] as! Double, y: l["y"] as! Double),
                                                    heading: getFloat(l["heading"]!),
                                                    floor: getFloor(floorID: l["floor"] as! String))
                            myMarkers.append(Marker(id: m["id"] as! String,
                                                    image: UIImage(named: m["image"] as! String)!,
                                                    physicalWidth: m["physicalWidth"] as! CGFloat,
                                                    location: location))
                            }
                            else { throw NotValid.noLocation(m["id"] as! String) }
                        }
                    }
                    else { throw NotValid.noMarkers }
//                    print("Buildings-> \(myBuilding)")
//                    print("Floors-> \(myFloors)")
//                    print("Markers-> \(myMarkers)")
                }
                else { throw NotValid.badStructure }
                
            }
            catch let error {
                switch error {
                    case NotValid.badStructure: print("Error: \(fileName).json with bad structure, check doc.")
                    case NotValid.noBuildings: print("Error: Buildings not found")
                    case NotValid.noFloors: print("Error: Floors not found")
                    case NotValid.noMarkers: print("Error: Markers not found")
                    case NotValid.noLocation(let markerID): print("Error: Missing Location for Marker: \(markerID)")
                    default:
                        print("Error: Unable to parse \(fileName).json")
                }
            }
        }
        else { print("Error: \(fileName).json not found!")}
    }
    
    private func getBuilding(buildingID: String) -> Building {
        return self.myBuilding.filter{b in b.id == buildingID}.first!
    }
    
    private func getFloor(floorID: String) -> Floor {
        return self.myFloors.filter{f in f.id == floorID}.first!
    }
    
    private func getFloat(_ object: Any) -> Float {
        if let n = object as? NSNumber { return n.floatValue }
        else { return -1 }
    }
}

enum NotValid: Error {
    case badStructure
    case noBuildings
    case noFloors
    case noMarkers
    case noLocation(String)
}
