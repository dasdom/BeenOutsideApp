//  Created by dasdom on 29.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import Foundation

extension RegionUpdate {

  enum CodingKeys: String, CodingKey {
    case date
    case updateType
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    date = try container.decode(Date.self, forKey: .date)
    let updateType = try container.decode(UpdateType.self, forKey: .updateType)
    updateTypeRaw = updateType.rawValue
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(date, forKey: .date)
    try container.encode(UpdateType(rawValue: updateTypeRaw), forKey: .updateType)
  }

  var updateType: UpdateType {
    get {
      return UpdateType(rawValue: updateTypeRaw)!
    }
    set {
      updateTypeRaw = newValue.rawValue
    }
  }
}
