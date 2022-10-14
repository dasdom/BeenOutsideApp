//  Created by dasdom on 23.05.20.
//  Copyright © 2020 dasdom. All rights reserved.
//

import Foundation

struct DayEntriesCalculator {
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
  }()

  static func durationFor(date: Date, from regionUpdates: [RegionUpdate]) -> TimeInterval {

    var duration = 0.0
    var enter: RegionUpdate?
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)

    for regionUpdate in regionUpdates.reversed() {

      if regionUpdate.date.timeIntervalSince(startOfDay) < 0 {
        break
      }

      if let unwrappedEnter = enter,
         regionUpdate.updateType == .exit {

        if calendar.isDate(date, inSameDayAs: regionUpdate.date) {

          if calendar.isDate(unwrappedEnter.date, inSameDayAs: regionUpdate.date) {
            duration += unwrappedEnter.date.timeIntervalSince(regionUpdate.date)
          } else if let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) {
            duration += startOfNextDay.timeIntervalSince(regionUpdate.date)
          }
        }
        enter = nil
      } else if regionUpdate.updateType == .enter {
        enter = regionUpdate
      }
    }

    if let enter = enter, enter.date.timeIntervalSince(startOfDay) > 0 {

      if calendar.isDate(enter.date, inSameDayAs: startOfDay) {
        duration += enter.date.timeIntervalSince(startOfDay)
      } else if let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) {
        duration += startOfNextDay.timeIntervalSince(startOfDay)
      }
    }

    return duration
  }

  static func dayEntries(from regionUpdates: [RegionUpdate], numberOfDays: Int) -> [DayEntry] {
    
    var dayEntries: [DayEntry] = []
    let now = Date()
    
    for i in 0..<numberOfDays {
      if let date = Calendar.current.date(byAdding: .day, value: -i, to: now) {
        let duration = durationFor(date: date, from: regionUpdates)

        dayEntries.append(DayEntry(duration: duration,
                                   weekday: date,
                                   type: .outside))
        //        dayEntries.append(DayEntry(duration: 24.0 * 60 * 60 - duration,
        //                                   weekday: date,
        //                                   type: .home))
      }
    }
    
    return dayEntries.reversed()
  }
}
