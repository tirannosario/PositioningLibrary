//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation
import MapKit

public class Building: CustomStringConvertible {
    public var id: String
    public var name: String
    public var coord: CLLocationCoordinate2D
    
    public init (id: String, name: String, coord: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coord = coord
    }
    
    public var description: String { return "Building: id=\(id)  name=\(name)"}

}

