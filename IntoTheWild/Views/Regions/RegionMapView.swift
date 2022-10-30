//  Created by Dominik Hauser on 27.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import MapKit

struct RegionMapView: View {

  @EnvironmentObject private var locationProvider: LocationProvider
  @Environment(\.dismiss) private var dismiss
  @State private var region: MKCoordinateRegion = .init()
  @State private var triggerDistance: Double = 20
  @State private var name = ""

  var body: some View {
    NavigationView {
      Form {
        Map(coordinateRegion: $region, interactionModes: [.pan])
          .overlay(
            Image(systemName: "plus")
              .allowsHitTesting(false)
          )
          .overlay(
            Circle()
              .strokeBorder(Color.red, lineWidth: 1)
              .background(Circle().foregroundColor(Color.black.opacity(0.1)))
              .frame(width: 60, height: 60)
              .allowsHitTesting(false)
          )
          .overlay(alignment: .bottom, content: locationCoordinates)
          .onAppear(perform: setLocation)
          .frame(height: 200)
          .listRowBackground(Color.clear)
          .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))

        TextField("Name", text: $name)
          .padding(3)

        Stepper("Region radius: \(Int(triggerDistance))", value: $triggerDistance, in: 10...100, step: 10, onEditingChanged: { _ in
          setSpanOfMap()
        })

        Button("Add Region") {
          locationProvider.addRegion(coordinate: region.center,
                                     identifier: name,
                                     radius: triggerDistance)
          dismiss.callAsFunction()
        }
        .disabled(name.count < 2)
      }
    }
    .onChange(of: triggerDistance) { newValue in
      setSpanOfMap()
    }
    .onAppear {
      setLocation()
      setSpanOfMap()
    }
  }

  func locationCoordinates() -> some View {
    Text("\(region.center.latitude), \(region.center.longitude)")
      .font(.footnote)
      .monospacedDigit()
      .padding(3)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
      .padding(.bottom, 10)
  }

  private var mapSpanInMeters: CLLocationDistance {
    return triggerDistance * 10
  }

  private func setSpanOfMap() {
    region = MKCoordinateRegion(center: region.center, latitudinalMeters: mapSpanInMeters, longitudinalMeters: mapSpanInMeters)
  }

  private func setLocation() {
    if let location = locationProvider.location?.coordinate {
      region.center = location
    }
    setSpanOfMap()
  }
}

struct RegionMapView_Previews: PreviewProvider {
  static var previews: some View {
    RegionMapView()
  }
}
