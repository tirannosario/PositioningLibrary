//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation

public struct Floor {
    public var name: String
    public var number: Int
    public var markers: [Marker]
    
    public init(_ name: String, _ number: Int) {
        self.name = name
        self.number = number
    }
    
    public mutating func addMarker(_ marker: Marker) {
        self.markers.append(marker)
    }
}
