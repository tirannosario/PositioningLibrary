//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation

public class Floor: CustomStringConvertible {
    public var id: String
    public var name: String
    public var number: Int
    public var building: Building
    public var maxWidth: Float // punto max a dx
    public var maxHeight: Float // punto max in alto
    
    public init(id: String, name: String, number: Int, building: Building, maxWidth: Float, maxHeight: Float) {
        self.id = id
        self.name = name
        self.number = number
        self.building = building
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    public var description: String { return "Floor: id=\(id)  name=\(name)"}

}

