//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation
import CoreGraphics


public struct Location: CustomStringConvertible {
    public var coordinates: CGPoint
    public var heading: CGFloat
    
    public init(_ coordinates: CGPoint, _ heading: CGFloat){
        self.coordinates = coordinates
        self.heading = heading
    }
    
    public var description: String { return "Coord=(\(self.coordinates.x),\(self.coordinates.y)) Heading=\(self.heading)" }

}
