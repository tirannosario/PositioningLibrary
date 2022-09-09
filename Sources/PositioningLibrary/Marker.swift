//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation
import UIKit


public struct Marker {
    public var id: String
    public var image: UIImage
    public var physicalWidth: CGFloat  // width of the marker in meters
    public var location: Location
    
    public init (id: String, image: UIImage, physicalWidth: CGFloat, location: Location){
        self.id = id
        self.image = image
        self.physicalWidth = physicalWidth
        self.location = location
    }
}
