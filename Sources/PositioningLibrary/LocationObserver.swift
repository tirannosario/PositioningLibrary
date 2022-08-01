//
//  File.swift
//  
//
//  Created by Rosario Galioto on 28/07/22.
//

import Foundation

public protocol LocationObserver {
    func onLocationUpdate(_ newLocation: Location)
    func onBuildingChanged(_ newBuilding: Building)
    func onFloorChanged(_ newFloor: Floor)
}
