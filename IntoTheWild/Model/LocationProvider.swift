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

//  var db: BeenOutside!
  @Published var wrongAuthorization = false
  @Published var location: CLLocation?
//  @Published var dayEntries: [DayEntry] = []
//  @Published var place: IdentifiablePlace = IdentifiablePlace(lat: 0, long: 0)
//  @Published var average: Double = 0
//  @Published var last28DaysTotal: Duration = .seconds(0)
  @Published var regions: [MonitoredRegion] = []
  @Published var coordinateRegion: MKCoordinateRegion?
//  {
//    didSet {
//      if let center = coordinateRegion?.center {
//        place = IdentifiablePlace(lat: center.latitude, long: center.longitude)
//      }
//    }
//  }
  let locationManager: CLLocationManager
//  var numberOfDays: Int = 7 {
//    didSet {
//      updateValues()
//    }
//  }
//  var regionUpdates: [RegionUpdate] = [] {
//    didSet {
//      updateValues()
//    }
//  }
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
      return MonitoredRegion(name: circularRegion.identifier, coordinate: coordinate, radius: circularRegion.radius)
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

//  func addRegionUpdate(type: UpdateType, name: String? = nil) {
//
//    let now = Date()
//
//    let lastUpdateType = regionUpdates.last?.updateType
//    if type != lastUpdateType {
//      let id = (regionUpdates.last?.id ?? 0) + 1
//      let regionUpdate = RegionUpdate(id: id, date: now, updateTypeRaw: type.rawValue, regionName: name)
//      regionUpdates.append(regionUpdate)
//      do {
//        _ = try db.insert(regionUpdate)
//      } catch {
//        print("\(#filePath), \(#line): error: \(error)")
//
//      }
//    }
//  }

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

    if let location = location, region.contains(location.coordinate) {
      dataStore.addRegionUpdate(type: .enter, name: identifier)
    }

    coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100, longitudinalMeters: 100)

    writeHome(coordinate: Coordinate(clCoordinate: coordinate))

    regions = locationManager.monitoredRegions.map({ clRegion in
      let circularRegion = clRegion as! CLCircularRegion
      let coordinate = Coordinate(clCoordinate: circularRegion.center)
      return MonitoredRegion(name: circularRegion.identifier, coordinate: coordinate, radius: circularRegion.radius)
    }).sorted(by: { $0.name < $1.name })
  }

  func deleteRegions(at offsets: IndexSet) {
    for offset in offsets {
      let region = regions[offset]
      if let clRegion = locationManager.monitoredRegions.first(where: { $0.identifier == region.name }) {
        locationManager.stopMonitoring(for: clRegion)
        if let location = location, let circularRegion = clRegion as? CLCircularRegion, circularRegion.contains(location.coordinate) {
          dataStore.addRegionUpdate(type: .exit, name: clRegion.identifier)
        }
      }
    }
    regions.remove(atOffsets: offsets)
  }

//  func loadRegionUpdates() {
//    let sqliteURL = FileManager.default.regionUpdatesSQLitePath()
//    do {
//      db = try BeenOutside.bootstrap(at: sqliteURL)
//    } catch {
//      print("\(#filePath), \(#line): error: \(error)")
//    }
//    do {
//      regionUpdates = try db.regionUpdates.fetch(limit: 50)
//    } catch {
//      regionUpdates = []
//    }
//  }

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

//  func updateValues() {
//    dayEntries = DayEntriesCalculator.dayEntries(from: regionUpdates, numberOfDays: numberOfDays)
//    let totalSeconds = dayEntries.filter({ $0.type == .outside }).map({ $0.duration }).reduce(0.0, +)
//    last28DaysTotal = .seconds(totalSeconds)
//    average = totalSeconds / 60.0 / 60.0 / Double(numberOfDays)
//    print("totalSeconds: \(totalSeconds), average: \(average), numberOfDays: \(numberOfDays)")
//  }
}
