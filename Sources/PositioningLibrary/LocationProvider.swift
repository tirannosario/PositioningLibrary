//
//  File.swift
//  
//
//  Created by Rosario Galioto on 27/07/22.
//


import Foundation
#if !os(macOS)
import ARKit


public class LocationProvider {
    private var building: [Building]
    private var userLocation: Location?
    private var arSession: ARSession
    private var locationObserver: LocationObserver?
    
    init(_ arSession: ARSession) {
        self.building = []
        self.arSession = arSession
    }
    
    init(_ arSession: ARSession, _ buildings: [Building]) {
        self.building = buildings
        self.arSession = arSession
    }
    
    public func addBuilding(_ building: Building) {
        self.building.append(building)
    }
    
    public func addLocationObserver(_ locationObserver: LocationObserver) {
        self.locationObserver = locationObserver
    }
}

#endif
