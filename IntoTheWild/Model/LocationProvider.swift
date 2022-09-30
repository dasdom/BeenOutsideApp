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
  var numberOfDays: Int = 30 {
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
          let enterUpdate = RegionUpdate(date: startOfNextDay, updateType: .enter)
          regionUpdates.append(enterUpdate)
          let exitUpdate = RegionUpdate(date: startOfNextDay, updateType: .exit)
          regionUpdates.append(exitUpdate)
          beginningOfDuration = startOfNextDay
        }
      }
      let regionUpdate = RegionUpdate(date: now, updateType: type)
      regionUpdates.append(regionUpdate)

      writeRegionUpdates()
    }
  }

  func setHome() {
    locationManager.requestLocation()
  }

  func writeRegionUpdates() {
    do {
      let data = try JSONEncoder().encode(regionUpdates)
      try data.write(to: FileManager.regionUpdatesDataPath(),
                     options: .atomic)
    } catch {
      print("error: \(error)")
    }
  }

  func loadRegionUpdates() {
    do {
      let data = try Data(contentsOf: FileManager.regionUpdatesDataPath())
      regionUpdates = try JSONDecoder().decode([RegionUpdate].self,
                                               from: data)
    } catch {
      print("error: \(error)")
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
    let totalSeconds = dayEntries.map({ $0.duration }).reduce(0.0, +)
    last28DaysTotal = .seconds(totalSeconds)
    average = totalSeconds / 60.0 / 60.0 / Double(numberOfDays)
    print("totalSeconds: \(totalSeconds), average: \(average), numberOfDays: \(numberOfDays)")
  }
}
