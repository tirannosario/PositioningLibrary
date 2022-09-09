//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation
import MapKit

public class Floor: CustomStringConvertible {
    public var id: String
    public var name: String
    public var number: Int
    public var building: Building
    public var maxWidth: Float // the width of the floor in meters
    public var maxHeight: Float // the height of the floor in meters
    public var floorMap: UIImage? // image of the floor map
    
    public init(id: String, name: String, number: Int, building: Building, maxWidth: Float, maxHeight: Float, floorMap: UIImage? = nil) {
        self.id = id
        self.name = name
        self.number = number
        self.building = building
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.floorMap = floorMap
    }
    
    public var description: String { return "Floor: id=\(id)  name=\(name)"}
}

