//
//  File.swift
//
//
//  Created by Rosario Galioto on 28/07/22.
//

import Foundation
import ARKit

public protocol LocationObserver: AnyObject {
    func onLocationUpdate(_ newLocation: ApproxLocation)
    func onBuildingChanged(_ newBuilding: Building)
    func onFloorChanged(_ newFloor: Floor)
    func onMeasurementMarkerFound(imageAnchor: ARImageAnchor, marker: Marker)
}
