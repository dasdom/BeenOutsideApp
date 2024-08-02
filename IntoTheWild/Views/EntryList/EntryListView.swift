//  Created by Dominik Hauser on 01.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI

struct EntryListView: View {

  private enum Destination {
    case share
  }

  @EnvironmentObject private var locationProvider: LocationProvider
  @EnvironmentObject private var dataStore: DataStore
  @State private var selectedDataType = 0
  @State private var startDate: Date = .distantPast
  @State private var endDate: Date = .now
  var earliestDate: Date {
    dataStore.regionUpdates.first?.date ?? .distantPast
  }

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
      VStack {
        DatePicker("Start date", selection: $startDate, in:earliestDate...endDate, displayedComponents: .date)
        DatePicker("End date", selection: $endDate, in:startDate...Date.now, displayedComponents: .date)
      }
      .padding()

        List {
          ForEach(dataStore.regionUpdates.reversed().filter({ startDate <= $0.date && $0.date <= endDate + 1 })) { update in
            HStack {
              HStack {
                Text(update.updateTypeRaw)
                  .bold()
                if let regionName = update.regionName {
                  Text(regionName)
                }
              }
              Spacer()
              HStack {
                switch update.updateType {
                  case .enter:
                    Image(systemName: "square.and.arrow.down")
                      .font(.footnote)
                      .bold()
                      .foregroundColor(Color(UIColor.systemGreen))
                  case .exit:
                    Image(systemName: "square.and.arrow.up")
                      .font(.footnote)
                      .bold()
                      .foregroundColor(Color(UIColor.systemRed))
                }
                Text(update.date.formatted())
              }
            }
          }
        }
//      }
    }
    .navigationTitle("Entries")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear(perform: {
      startDate = earliestDate
    })
    .toolbar {
      let sqliteURL = FileManager.default.regionUpdatesSQLitePath()
      if let data = try? Data(contentsOf: sqliteURL) {
        ToolbarItem(placement: .navigationBarTrailing) {
          ShareLink(item: data, preview: SharePreview(Text("SQLite database")))
        }
      }
    }
  }
}
