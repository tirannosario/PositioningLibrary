//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//
#if os(iOS)

import Foundation

public struct Floor {
    public var name: String
    public var number: Int
    public var markers: [Marker]
    
    public init(_ name: String, _ number: Int) {
        self.name = name
        self.number = number
        self.markers = []
    }
    
    public mutating func addMarker(_ marker: Marker) {
        self.markers.append(marker)
    }
}

#endif
