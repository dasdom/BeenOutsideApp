//  Created by Dominik Hauser on 19.06.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import CoreLocation

struct Coordinate: Codable {
  let latitude: Double
  let longitude: Double
  var clCoordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  init(clCoordinate: CLLocationCoordinate2D) {
    latitude = clCoordinate.latitude
    longitude = clCoordinate.longitude
  }
}
