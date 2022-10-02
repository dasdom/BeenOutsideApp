//  Created by dasdom on 30.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import Foundation

extension FileManager {
  private static func documentsURL() -> URL {
    guard let url = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask).first else {
        fatalError()
    }
    return url
  }
  
  static func regionUpdatesDataPath() -> URL {
    return documentsURL().appendingPathComponent("region_updates.json")
  }

  static func regionUpdatesSQLitePath() -> URL {
    return documentsURL().appendingPathComponent("region_updates.sqlite")
  }

  static func homeCoordinateURL() -> URL {
    return documentsURL().appendingPathComponent("home.json")
  }
}
