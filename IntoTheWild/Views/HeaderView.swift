//  Created by Dominik Hauser on 19.06.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import MapKit

struct HeaderView: View {

  @EnvironmentObject private var locationProvider: LocationProvider

  var body: some View {
    VStack {
      Map(coordinateRegion: coordinateRegionBinding, interactionModes: MapInteractionModes(), showsUserLocation: true, annotationItems: [locationProvider.place], annotationContent: { place in
        MapAnnotation(coordinate: place.location) {
          Image(systemName: "house.circle.fill")
            .font(.title)
        }
      })
        .frame(height: 200)
      Text("Into The Wild")
        .font(.headline)
    }
  }

  private var coordinateRegionBinding: Binding<MKCoordinateRegion> {
    Binding {
      locationProvider.coordinateRegion ?? MKCoordinateRegion()
    } set: {
      locationProvider.coordinateRegion = $0
    }

  }
}

struct HeaderView_Previews: PreviewProvider {
  static var previews: some View {
    HeaderView()
      .environmentObject(LocationProvider())
  }
}
