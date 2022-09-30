//  Created by dasdom on 28.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import SwiftUI
import CoreLocationUI

struct OutsideDurationOverviewView: View {
  
  @EnvironmentObject private var locationProvider: LocationProvider

  var body: some View {
    VStack {
      if let _ = locationProvider.coordinateRegion {
//        HeaderView()

        OutsideDurationChartView()

        if let regionUpdate = locationProvider.regionUpdates.last {
          Text("Last \(regionUpdate.updateType.rawValue): \(regionUpdate.date.formatted(date: .abbreviated, time: .shortened))")
            .font(.footnote)
        }
      } else {
        NotMonitoringRegionView()
      }
    }
//    .edgesIgnoringSafeArea(.top)

    .alert(isPresented: $locationProvider.wrongAuthorization) {
      Alert(title: Text("Not authorized"),
            message: Text("Open settings and authorize."),
            primaryButton: .default(Text("Settings"), action: {
        UIApplication.shared.open(
          URL(string: UIApplication.openSettingsURLString)!)
      }),
            secondaryButton: .default(Text("OK")))
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  
  static var locationProvider: LocationProvider = {
    let locationProvider = LocationProvider()
    let now = Date()
    for i in 1..<28 {
      if let date = Calendar.current.date(byAdding: .day, value: -i, to: now) {
        let dayEntry = DayEntry(duration: TimeInterval.random(in: 1200...20640), weekday: date)
        locationProvider.dayEntries.append(dayEntry)
      }
    }
    return locationProvider
  }()
  
  static var previews: some View {
    Group {
      OutsideDurationOverviewView()
        .environmentObject(locationProvider)
      OutsideDurationOverviewView()
        .environmentObject(locationProvider)
        .environment(\.colorScheme, .dark)
    }
  }
}
