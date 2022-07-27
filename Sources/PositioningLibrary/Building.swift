//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation

public struct Building {
    private var name: String
    private var floors: [Floor]
    
    public init (_ name: String) {
        self.name = name
        self.floors = []
    }
    
    public mutating func addFloor(_ floor: Floor) {
        self.floors.append(floor)
    }
}
