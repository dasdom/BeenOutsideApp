//  Created by Dominik Hauser on 13.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation

struct MonitoredRegion: Hashable {
  let name: String
  let coordinate: Coordinate
  let radius: Double

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(coordinate)
  }
}
