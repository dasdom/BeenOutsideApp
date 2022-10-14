//  Created by Dominik Hauser on 13.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import MapKit

struct RegionsView: View {

  @EnvironmentObject private var locationProvider: LocationProvider

  var body: some View {
    List {
      ForEach(locationProvider.regions, id: \.self) { region in
        VStack(alignment: .leading) {
          HStack {
            Text(region.name)
              .font(.headline)
            Spacer()
            Text("radius: \(region.radius, format: .number) m")
          }
          Text("(\(region.coordinate.latitude), \(region.coordinate.longitude))")
        }
      }
    }
  }
}
