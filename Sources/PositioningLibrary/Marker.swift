//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//
#if os(iOS)

import Foundation
import UIKit


public struct Marker {
    public var id: String
    public var image: UIImage
    public var location: Location
    public var physicalWidth: CGFloat
    
    public init(_ id: String, _ image: UIImage, _ location: Location, _ physicalWidth: CGFloat){
        self.id = id
        self.image = image
        self.location = location
        self.physicalWidth = physicalWidth
    }
}
#endif
