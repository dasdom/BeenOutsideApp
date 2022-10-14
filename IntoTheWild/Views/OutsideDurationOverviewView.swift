//  Created by dasdom on 28.12.19.
//  Copyright © 2019 dasdom. All rights reserved.
//

import SwiftUI
import CoreLocationUI

struct OutsideDurationOverviewView: View {

  private enum Destination {
    case settings
    case list
  }
  
  @EnvironmentObject private var locationProvider: LocationProvider

  var body: some View {
    NavigationStack {
      VStack {
        if let _ = locationProvider.coordinateRegion {

          OutsideDurationChartView()

          if let regionUpdate = locationProvider.regionUpdates.last {
            Text("Last \(regionUpdate.updateType.rawValue): \(regionUpdate.date.formatted(date: .abbreviated, time: .shortened))")
              .font(.footnote)
          }
        } else {
          NotMonitoringRegionView()
        }
      }
      .alert(isPresented: $locationProvider.wrongAuthorization) {
        Alert(title: Text("Not authorized"),
              message: Text("Open settings and authorize."),
              primaryButton: .default(Text("Settings"), action: {
          UIApplication.shared.open(
            URL(string: UIApplication.openSettingsURLString)!)
        }),
              secondaryButton: .default(Text("OK")))
      }
      .navigationTitle("Been Outside")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          NavigationLink(value: Destination.settings) {
            Image(systemName: "gearshape")
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink(value: Destination.list) {
            Image(systemName: "list.bullet")
          }
        }
      }
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
          case .settings:
            RegionsView()
          case .list:
            EntryListView()
        }
      }
    }
  }
}

