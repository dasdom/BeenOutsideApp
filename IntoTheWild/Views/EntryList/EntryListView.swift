//  Created by Dominik Hauser on 01.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI

struct EntryListView: View {

  @EnvironmentObject private var locationProvider: LocationProvider
  @EnvironmentObject private var dataStore: DataStore
  @State private var selectedDataType = 0

  var body: some View {

    VStack {
//      Picker("Data Types", selection: $selectedDataType) {
//        Text("Days").tag(0)
//        Text("Entries/Exits").tag(1)
//      }
//      .pickerStyle(.segmented)

//      if selectedDataType == 0 {
//        List {
//          ForEach(locationProvider.dayEntries.reversed(), id: \.self) { dayEntry in
//            HStack {
//              Text(dayEntry.weekday.formatted())
//              Spacer()
//              Text("\(Duration.seconds(dayEntry.duration), format: .time(pattern: .hourMinute)) h")
//            }
//          }
//        }
//      } else {
        List {
          ForEach(dataStore.regionUpdates.reversed()) { update in
            HStack {
              HStack {
                Text(update.updateTypeRaw)
                if let regionName = update.regionName {
                  Text(regionName)
                }
              }
              Spacer()
              Text(update.date.formatted())
            }
          }
        }
//      }
    }
    .navigationTitle("Entries")
  }
}
