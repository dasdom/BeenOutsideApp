//  Created by dasdom on 28.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SQLite3

func date(year: Int, month: Int, day: Int = 1) -> Date {
  Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

class LocationProvider: NSObject,
                        CLLocationManagerDelegate,
                        ObservableObject {

  var db : OpaquePointer?
  @Published var wrongAuthorization = false
  @Published var coordinateRegion: MKCoordinateRegion? {
    didSet {
      if let center = coordinateRegion?.center {
        place = IdentifiablePlace(lat: center.latitude, long: center.longitude)
      }
    }
  }
  @Published var dayEntries: [DayEntry] = []
  @Published var place: IdentifiablePlace = IdentifiablePlace(lat: 0, long: 0)
  @Published var average: Double = 0
  @Published var last28DaysTotal: Duration = .seconds(0)

  let locationManager: CLLocationManager
  var numberOfDays: Int = 7 {
    didSet {
      updateValues()
    }
  }
  var regionUpdates: [RegionUpdate] = [] {
    didSet {
      updateValues()
    }
  }

  override init() {
    
    locationManager = CLLocationManager()
    
    super.init()
    
    loadRegionUpdates()

    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()

    if let homeCoordinate = loadHome() {
      coordinateRegion = MKCoordinateRegion(center: homeCoordinate.clCoordinate, latitudinalMeters: 100, longitudinalMeters: 100)
    }
  }

  deinit {
    sqlite3_close(db)
  }

  func locationManager(_ manager: CLLocationManager,
                       didChangeAuthorization status:
                       CLAuthorizationStatus) {
    
    switch status {
      case .authorizedAlways:
        print("success")
      case .notDetermined:
        print("notDetermined")
      default:
        wrongAuthorization = true
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {

    guard let location = locations.last else { return }
    print("location: \(location)")
    
    let region = CLCircularRegion(center: location.coordinate,
                                  radius: 10,
                                  identifier: "home")
    manager.startMonitoring(for: region)

    coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)

    writeHome(coordinate: Coordinate(clCoordinate: location.coordinate))
  }

  func locationManager(_ manager: CLLocationManager,
                       didFailWithError error: Error) {
    
    print("locationManager didFailWithError: \(error)")
  }

  func locationManager(_ manager: CLLocationManager,
                       didEnterRegion region: CLRegion) {
    
    print("didEnterRegion: \(String(describing: region))")
    addRegionUpdate(type: .enter)
  }

  func locationManager(_ manager: CLLocationManager,
                       didExitRegion region: CLRegion) {
    
    print("didExitRegion: \(String(describing: region))")

    addRegionUpdate(type: .exit)
  }

  func addRegionUpdate(type: UpdateType) {

    let calendar = Calendar.current
    let now = Date()
    
    let lastUpdateType = regionUpdates.last?.updateType
    if type != lastUpdateType {
      if type == .enter, let lastUpdate = regionUpdates.last {
        var beginningOfDuration: Date = lastUpdate.date
        while false == calendar.isDate(beginningOfDuration, inSameDayAs: now) {
          guard let nextDayAfterBeginningOfDuration = calendar.date(byAdding: .day, value: 1, to: beginningOfDuration) else {
            break
          }
          let startOfNextDay = calendar.startOfDay(for: nextDayAfterBeginningOfDuration)
          let enterUpdate = RegionUpdate(date: startOfNextDay, updateTypeRaw: UpdateType.enter.rawValue)
          regionUpdates.append(enterUpdate)
          let exitUpdate = RegionUpdate(date: startOfNextDay, updateTypeRaw: UpdateType.exit.rawValue)
          regionUpdates.append(exitUpdate)
          beginningOfDuration = startOfNextDay
        }
      }
      var regionUpdate = RegionUpdate(date: now, updateTypeRaw: type.rawValue)
      regionUpdates.append(regionUpdate)
      regionUpdate.insert(into: db)

      writeRegionUpdates()
    }
  }

  func setHome() {
    locationManager.requestLocation()
  }

  func writeRegionUpdates() {
//    sqlite3_close(db)
//    do {
//      let data = try JSONEncoder().encode(regionUpdates)
//      try data.write(to: FileManager.regionUpdatesDataPath(),
//                     options: .atomic)
//    } catch {
//      print("error: \(error)")
//    }
  }

  func loadRegionUpdates() {
    let sqliteURL = FileManager.regionUpdatesSQLitePath()
    let path = sqliteURL.path
    if FileManager.default.fileExists(atPath: path) {
      sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil)
      regionUpdates = RegionUpdate.fetch(from: db, orderBy: "date") ?? []
    } else {
      let rc = BeenOutside.create(sqliteURL.path, in: &db)
      if rc != SQLITE_OK {
        print("\(#filePath), \(#line): Could not create db.")
      }
      do {
        let data = try Data(contentsOf: FileManager.regionUpdatesDataPath())
        regionUpdates = try JSONDecoder().decode([RegionUpdate].self,
                                                 from: data)
        for regionUpdate in regionUpdates {
          var mutableRegionUpdate = regionUpdate
          mutableRegionUpdate.insert(into: db)
        }
      } catch {
        print("error: \(error)")
      }
    }
  }

  func writeHome(coordinate: Coordinate) {
    do {
      let data = try JSONEncoder().encode(coordinate)
      try data.write(to: FileManager.homeCoordinateURL(), options: .atomic)
    } catch {
      print("error: \(error)")
    }
  }

  func loadHome() -> Coordinate? {
    do {
      let data = try Data(contentsOf: FileManager.homeCoordinateURL())
      return try JSONDecoder().decode(Coordinate.self, from: data)
    } catch {
      print("error: \(error)")
    }
    return nil
  }

  func updateValues() {
    dayEntries = DayEntriesCalculator.dayEntries(from: regionUpdates, numberOfDays: numberOfDays)
    let totalSeconds = dayEntries.filter({ $0.type == .outside }).map({ $0.duration }).reduce(0.0, +)
    last28DaysTotal = .seconds(totalSeconds)
    average = totalSeconds / 60.0 / 60.0 / Double(numberOfDays)
    print("totalSeconds: \(totalSeconds), average: \(average), numberOfDays: \(numberOfDays)")
  }
}
