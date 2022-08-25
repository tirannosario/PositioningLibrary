//
//  File.swift
//
//
//  Created by Rosario Galioto on 27/07/22.
//

import Foundation

public class Building: CustomStringConvertible {
    public var id: String
    public var name: String
    
    public init (id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    public var description: String { return "Building: id=\(id)  name=\(name)"}

}

