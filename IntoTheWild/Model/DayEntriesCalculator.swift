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

    var regionUpdates = regionUpdates

    var dateWithLastDuration: Date? = nil
    for i in 0..<numberOfDays {
      if let date = Calendar.current.date(byAdding: .day, value: -i, to: now) {
        let duration = durationFor(date: date, from: regionUpdates)

        if duration > 0 {
          dateWithLastDuration = date
        }

        dayEntries.append(DayEntry(duration: duration,
                                   weekday: date,
                                   type: .outside))
      }
    }

    var pastDayEntries = Array(dayEntries.reversed())

    if let lastRegionUpdate = regionUpdates.last, lastRegionUpdate.updateType == .exit {
      let id = lastRegionUpdate.id ?? 0
      let regionUpdate = RegionUpdate(id: id + 1, date: now, updateTypeRaw: UpdateType.enter.rawValue)
      regionUpdates.append(regionUpdate)

      var currentDayEntries: [DayEntry] = []

      for i in 0..<numberOfDays {
        if let date = Calendar.current.date(byAdding: .day, value: -i, to: now), let dateWithLastDuration = dateWithLastDuration {
          if date.timeIntervalSince(dateWithLastDuration) < 0 {
            break
          }
          var duration = durationFor(date: date, from: regionUpdates)

          if let dayEntry = dayEntries.first(where: { $0.weekday.timeIntervalSince(date) < 0.1 }) {
            duration -= dayEntry.duration
          }

          if duration > 0.1 {
            currentDayEntries.append(DayEntry(duration: duration,
                                              weekday: date,
                                              type: .outside,
                                              isCurrent: true))
          }
        }
      }

      for currentDayEntry in currentDayEntries {
        pastDayEntries.append(currentDayEntry)
      }
    }
    
    return pastDayEntries
  }
}
