//  Created by dasdom on 28.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

func date(year: Int, month: Int, day: Int = 1) -> Date {
  Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

class LocationProvider: NSObject,
                        CLLocationManagerDelegate,
                        ObservableObject {

  @Published var wrongAuthorization = false
  @Published var location: CLLocation?
  @Published var regions: [MonitoredRegion] = []
  @Published var coordinateRegion: MKCoordinateRegion?
  let locationManager: CLLocationManager
  let dataStore: DataStore

  init(dataStore: DataStore) {
    
    locationManager = CLLocationManager()
    self.dataStore = dataStore
    
    super.init()
    
//    loadRegionUpdates()

    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.distanceFilter = 1

    regions = locationManager.monitoredRegions.map({ clRegion in
      let circularRegion = clRegion as! CLCircularRegion
      let coordinate = Coordinate(clCoordinate: circularRegion.center)
      let timestamp = UserDefaults.standard.double(forKey: String(describing: coordinate))
      let date: Date? = timestamp > 0.1 ? Date(timeIntervalSince1970: timestamp) : nil
      return MonitoredRegion(name: circularRegion.identifier, coordinate: coordinate, radius: circularRegion.radius, date: date)
    }).sorted(by: { $0.name < $1.name })

    if let homeCoordinate = loadHome() {
      coordinateRegion = MKCoordinateRegion(center: homeCoordinate.clCoordinate, latitudinalMeters: 100, longitudinalMeters: 100)
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didChangeAuthorization status:
                       CLAuthorizationStatus) {
    
    switch status {
      case .authorizedAlways:
        print("success")
//        manager.startUpdatingLocation()
      case .notDetermined:
        print("notDetermined")
      default:
        wrongAuthorization = true
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {

    guard let location = locations.last else {
      return
    }

    self.location = location
  }

  func locationManager(_ manager: CLLocationManager,
                       didFailWithError error: Error) {
    
    print("locationManager didFailWithError: \(error)")
  }

  func locationManager(_ manager: CLLocationManager,
                       didEnterRegion region: CLRegion) {
    
    print("didEnterRegion: \(String(describing: region))")
    dataStore.addRegionUpdate(type: .enter, name: region.identifier)
  }

  func locationManager(_ manager: CLLocationManager,
                       didExitRegion region: CLRegion) {
    
    print("didExitRegion: \(String(describing: region))")

    dataStore.addRegionUpdate(type: .exit, name: region.identifier)
  }

  func startUpdates() {
    locationManager.startUpdatingLocation()
  }

  func stopUpdates() {
    locationManager.stopUpdatingLocation()
  }

  func addRegion(coordinate: CLLocationCoordinate2D, identifier: String, radius: CLLocationDistance) {
    let region = CLCircularRegion(center: coordinate,
                                  radius: radius,
                                  identifier: identifier)
    locationManager.startMonitoring(for: region)

    let key = Coordinate(clCoordinate: coordinate)
    let timestamp = Date().timeIntervalSince1970
    UserDefaults.standard.setValue(timestamp, forKey: String(describing: Coordinate(clCoordinate: coordinate)))

    if let location = location, region.contains(location.coordinate) {
      dataStore.addRegionUpdate(type: .enter, name: identifier)
    }

    coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100, longitudinalMeters: 100)

    writeHome(coordinate: Coordinate(clCoordinate: coordinate))

    regions = locationManager.monitoredRegions.map({ clRegion in
      let circularRegion = clRegion as! CLCircularRegion
      let coordinate = Coordinate(clCoordinate: circularRegion.center)
      let timestamp = UserDefaults.standard.double(forKey: String(describing: coordinate))
      let date: Date? = timestamp > 0.1 ? Date(timeIntervalSince1970: timestamp) : nil
      return MonitoredRegion(name: circularRegion.identifier, coordinate: coordinate, radius: circularRegion.radius, date: date)
    }).sorted(by: { $0.name < $1.name })
  }

  func deleteRegions(at offsets: IndexSet) {
    for offset in offsets {
      let region = regions[offset]
      if let clRegion = locationManager.monitoredRegions.first(where: { $0.identifier == region.name }) {
        locationManager.stopMonitoring(for: clRegion)
        if regions.count > 1, let location = location, let circularRegion = clRegion as? CLCircularRegion, circularRegion.contains(location.coordinate) {
          dataStore.addRegionUpdate(type: .exit, name: clRegion.identifier)
        }
      }
    }
    regions.remove(atOffsets: offsets)
  }

  func writeHome(coordinate: Coordinate) {
    do {
      let data = try JSONEncoder().encode(coordinate)
      try data.write(to: FileManager.default.homeCoordinateURL(), options: .atomic)
    } catch {
      print("error: \(error)")
    }
  }

  func loadHome() -> Coordinate? {
    do {
      let data = try Data(contentsOf: FileManager.default.homeCoordinateURL())
      return try JSONDecoder().decode(Coordinate.self, from: data)
    } catch {
      print("error: \(error)")
    }
    return nil
  }
}
