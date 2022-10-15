//  Created by Dominik Hauser on 17.06.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import CoreLocationUI

struct NotMonitoringRegionView: View {

  @EnvironmentObject private var locationProvider: LocationProvider

  var body: some View {
    VStack(spacing: 20) {
      Text("Into the wild")
        .font(.title)

      LocationButton(.currentLocation) {
        locationProvider.setHome()
      }
      .clipShape(RoundedRectangle(cornerRadius: 20))
      .foregroundColor(.white)

      VStack {
        Text("Tap the 'Current Location' button when you are home.")
        Text("This sets your current location as monitored region.")
          .font(.footnote)
      }
      .multilineTextAlignment(.center)
    }
    .padding()
    .onAppear {
      locationProvider.startUpdates()
    }
    .onDisappear {
      locationProvider.stopUpdates()
    }
  }
}

struct NotMonitoringRegionView_Previews: PreviewProvider {
  static var previews: some View {
    NotMonitoringRegionView()
      .environmentObject(LocationProvider())
  }
}
