//  Created by Dominik Hauser on 13.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import MapKit

struct RegionsView: View {

  @EnvironmentObject private var locationProvider: LocationProvider
  @State var showsRegionMapView = false

  var body: some View {
    List {
      ForEach(locationProvider.regions, id: \.self) { region in
        VStack(alignment: .leading, spacing: 5) {
          HStack {
            Text(region.name)
              .font(.headline)
            Spacer()
            Text("Radius: \(region.radius, format: .number) m")
          }
          .shadow(color: (region.contains(location: locationProvider.location) ? Color.green : Color(uiColor: .systemBackground)), radius: 3)
          if let distance = distance(for: region), distance > 0 {
            Text("Current distance: \(distance, format: .number) km")
          } else {
            Text("Current distance: < 1 km")
          }
          if let date = region.date {
            Text("Created: \(date.formatted(.dateTime.year().month().day().hour().minute()))")
              .font(.footnote)
          }
        }
      }
      .onDelete { indexSet in
        locationProvider.deleteRegions(at: indexSet)
      }
    }
    .sheet(isPresented: $showsRegionMapView, content: { RegionMapView() })
    .navigationTitle("Regions")
    .onAppear {
      locationProvider.startUpdates()
    }
    .onDisappear {
      locationProvider.stopUpdates()
    }
    .toolbar(content: toolbarContent)
  }

  @ToolbarContentBuilder
  func toolbarContent() -> some ToolbarContent {
    if locationProvider.regions.count < 10 {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showsRegionMapView.toggle() }) {
          Image(systemName: "plus")
        }
      }
    }
  }

  func distance(for region: MonitoredRegion) -> Int? {
    if let location = locationProvider.location {
      return Int(location.distance(from: CLLocation(latitude: region.coordinate.latitude, longitude: region.coordinate.longitude))) / 1000
    } else {
      return nil
    }
  }
}
