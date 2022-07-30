//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation
import CoreGraphics


public struct Location {
    public var coordinates: CGPoint
    public var heading: CGFloat
    
    public init(_ coordinates: CGPoint, _ heading: CGFloat){
        self.coordinates = coordinates
        self.heading = heading
    }
}
