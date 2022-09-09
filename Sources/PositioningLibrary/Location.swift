//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation
import CoreGraphics

public class Location: CustomStringConvertible {
    public var coordinates: CGPoint
    public var heading: Float // heading relative to the floor origin
    public var floor: Floor
    
    public init(coordinates: CGPoint, heading: Float, floor: Floor){
        self.coordinates = coordinates
        self.heading = heading
        self.floor = floor
    }
    
    public var description: String { return "Coord=(\(self.coordinates.x),\(self.coordinates.y)) Heading=\(self.heading) Floor=\(self.floor.number) Building=\(self.floor.building.name) "}

}
