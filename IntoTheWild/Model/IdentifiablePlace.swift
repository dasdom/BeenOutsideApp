//  Created by Dominik Hauser on 30.09.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation

struct IdentifiablePlace: Identifiable {
  let id: UUID
  let location: CLLocationCoordinate2D

  init(id: UUID = UUID(), lat: Double, long: Double) {
    self.id = id
    self.location = CLLocationCoordinate2D(
      latitude: lat,
      longitude: long)
  }
}
