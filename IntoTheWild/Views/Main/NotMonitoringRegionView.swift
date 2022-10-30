//  Created by Dominik Hauser on 17.06.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import CoreLocationUI

struct NotMonitoringRegionView: View {

  @EnvironmentObject private var locationProvider: LocationProvider
  @State var showsRegionMapView = false

  var body: some View {
    VStack(spacing: 20) {
      Text("Into the wild")
        .font(.title)

//      LocationButton(.currentLocation) {
//        locationProvider.setHome()
//      }
//      .clipShape(RoundedRectangle(cornerRadius: 20))
//      .foregroundColor(.white)
      Button("Add Region", action: {
        showsRegionMapView.toggle()
      })

      VStack {
        Text("You don't have a monitored region yet. Select 'Add Region' to start using region monitoring.")
      }
      .multilineTextAlignment(.center)
    }
    .padding()
    .sheet(isPresented: $showsRegionMapView) {
      RegionMapView()
    }
    .onAppear {
      locationProvider.startUpdates()
    }
    .onDisappear {
      locationProvider.stopUpdates()
    }
  }
}

//struct NotMonitoringRegionView_Previews: PreviewProvider {
//  static var previews: some View {
//    NotMonitoringRegionView()
//      .environmentObject(LocationProvider())
//  }
//}
