//
//  File.swift
//
//
//  Created by Rosario Galioto on 28/07/22.
//

import Foundation
import WorldRepresentationLibrary

public protocol ArLocationObserver: AnyObject {
    func onLocationUpdate(_ newLocation: LocalLocation)
    func onBuildingChanged(_ newBuilding: Building)
    func onFloorChanged(_ newFloor: Floor)
}
