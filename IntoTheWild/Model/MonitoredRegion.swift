//  Created by Dominik Hauser on 13.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import CoreLocation

struct MonitoredRegion: Hashable {
  let name: String
  let coordinate: Coordinate
  let radius: Double
  let date: Date?

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(coordinate)
  }

  func contains(location: CLLocation?) -> Bool {
    guard let location = location else {
      return false
    }

    let clRegion = CLCircularRegion(center: coordinate.clCoordinate, radius: radius, identifier: name)
    return clRegion.contains(location.coordinate)
  }
}
