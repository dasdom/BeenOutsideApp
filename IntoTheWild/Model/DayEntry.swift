//  Created by dasdom on 30.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import Foundation
import Charts

enum EntryType: String, Plottable {
  case home
  case outside
}

struct DayEntry : Hashable, Equatable {
  let duration: TimeInterval
  let weekday: Date
  let type: EntryType
  var isCurrent: Bool = false

  static func ==(lhs: DayEntry, rhs: DayEntry) -> Bool {
    if abs(lhs.duration - rhs.duration) > 0.1 {
      return false
    }
    if abs(lhs.weekday.timeIntervalSince(rhs.weekday)) > 0.1 {
      return false
    }
    if lhs.type != rhs.type {
      return false
    }
    return true
  }
}
