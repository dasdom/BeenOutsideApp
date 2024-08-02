//  Created by Dominik Hauser on 16.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import Lighter
import WidgetKit

class DataStore: ObservableObject {

  @Published var dayEntries: [DayEntry] = []
  @Published var lastXDaysTotal: Duration = .seconds(0)
  @Published var average: Double = 0
  var db: BeenOutside!
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
  var numberOfNotEmptyDayEntries: Int {
    return dayEntries.filter({ $0.duration > 0 }).count
  }

  init() {
    loadRegionUpdates()
  }
  
  func loadRegionUpdates() {
    let sqliteURL = FileManager.default.regionUpdatesSQLitePath()
    do {
      db = try BeenOutside.bootstrap(at: sqliteURL)
    } catch {
      print("\(#filePath), \(#line): error: \(error)")
    }
    do {
      regionUpdates = try db.regionUpdates.fetch(limit: 2000, orderBy: \.date, .descending).sorted(by: { $0.date < $1.date })
    } catch {
      regionUpdates = []
    }
  }

  func addRegionUpdate(type: UpdateType, name: String? = nil) {

    let now = Date()

    let lastUpdateType = regionUpdates.last?.updateType
    if type != lastUpdateType {
      let id = (regionUpdates.last?.id ?? 0) + 1
      let regionUpdate = RegionUpdate(id: id, date: now, updateTypeRaw: type.rawValue, regionName: name)
      regionUpdates.append(regionUpdate)
      do {
        _ = try db.insert(regionUpdate)

        let data = try JSONEncoder().encode(regionUpdate)
        try data.write(to: FileManager.default.lastUpdatURL())

        WidgetCenter.shared.reloadAllTimelines()
      } catch {
        print("\(#filePath), \(#line): error: \(error)")
      }
    }
  }

  func updateValues() {
    dayEntries = DayEntriesCalculator.dayEntries(from: regionUpdates, numberOfDays: numberOfDays)
    let totalSeconds = dayEntries.filter({ $0.type == .outside }).map({ $0.duration }).reduce(0.0, +)
    lastXDaysTotal = .seconds(totalSeconds)
    average = totalSeconds / 60.0 / 60.0 / Double(numberOfDays)
    print("totalSeconds: \(totalSeconds), average: \(average), numberOfDays: \(numberOfDays)")
  }
}
