//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//
#if os(iOS)

import Foundation
import ARKit

public class LocationProvider {
    private var building: [Building]
    private var userLocation: Location?
    private var arSession: ARSession
    private var locationObserver: LocationObserver?
    
    init(_ arSession: ARSession) {
        self.building = [Building]
        self.arSession = arSession
    }
    
    init(_ arSession: ARSession, _ buildings: [Building]) {
        self.building = buildings
        self.arSession = arSession
    }
    
    public func addLocationObserver(_ locationObserver: LocationObserver) {
        self.locationObserver = locationObserver
    }
}
#endif
