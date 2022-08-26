//
//  ApproxLocation.swift
//  PositioningLibrary
//
//  Created by Rosario Galioto on 12/08/22.
//

import Foundation
import CoreGraphics

public class ApproxLocation: Location {
    public var approxRadius: Float
    public var approxAngle: Float
    
    public init(coordinates: CGPoint, heading: Float, floor: Floor, approxRadius: Float, approxAngle: Float){
        self.approxRadius = approxRadius
        self.approxAngle = approxAngle
        super.init(coordinates: coordinates, heading: heading, floor: floor)
    }
    
    public override var description: String { return "Coord=(\(self.coordinates.x),\(self.coordinates.y)) Heading=\(self.heading)" }

}
