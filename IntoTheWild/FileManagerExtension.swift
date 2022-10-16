//  Created by dasdom on 30.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import Foundation

extension FileManager {
  private func documentsURL() -> URL {
    guard let url = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask).first else {
        fatalError()
    }
    return url
  }
  
  func regionUpdatesDataPath() -> URL {
    return documentsURL().appendingPathComponent("region_updates.json")
  }

  func lastUpdatURL() -> URL {
    if let url = containerURL(forSecurityApplicationGroupIdentifier: "group.de.dasdom.beenoutside") {
      let lastUpdatesURL = url.appendingPathComponent("last_update.json")
      return lastUpdatesURL
    } else {
      return documentsURL().appendingPathComponent("last_update.json")
    }
  }

  func regionUpdatesSQLitePath() -> URL {
    let preGroupURL = documentsURL().appendingPathComponent("region_updates.sqlite")

    if let url = containerURL(forSecurityApplicationGroupIdentifier: "group.de.dasdom.beenoutside") {
      let regionUpdatesURL = url.appendingPathComponent("region_updates.sqlite")
      if false == fileExists(atPath: regionUpdatesURL.path) {
        if fileExists(atPath: preGroupURL.path) {
          try? copyItem(at: preGroupURL, to: regionUpdatesURL)
        }
      }
      return regionUpdatesURL
    } else {
      return preGroupURL
    }
  }

  func homeCoordinateURL() -> URL {
    return documentsURL().appendingPathComponent("home.json")
  }
}
