//  Created by dasdom on 30.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import Foundation
import Charts

enum EntryType: String, Plottable {
  case home
  case outside
}

struct DayEntry : Hashable {
  let duration: TimeInterval
  let weekday: Date
  let type: EntryType
}
