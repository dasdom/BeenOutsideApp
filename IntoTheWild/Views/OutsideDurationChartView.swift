//  Created by Dominik Hauser on 19.06.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import Charts

struct OutsideDurationChartView: View {

  @EnvironmentObject private var locationProvider: LocationProvider
  @State private var selectedTimeFrame = 0
  
    var body: some View {
      VStack(alignment: .leading) {
        Picker("Time Frame", selection: $selectedTimeFrame) {
          Text("7 days").tag(0)
          Text("30 days").tag(1)
        }
        .pickerStyle(.segmented)

        Text("Total time spend away from home")
          .font(.callout)
          .foregroundStyle(.secondary)
        Text("\(locationProvider.last28DaysTotal, format: .time(pattern: .hourMinute)) hours")
          .font(.title2.bold())

        Chart {
          ForEach(locationProvider.dayEntries, id: \.self) { entry in
            BarMark(
              x: .value("Day", entry.weekday, unit: .day),
              y: .value("Duration", entry.duration / 3600)
            )
          }

          RuleMark(y: .value("Average", locationProvider.average))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [15, 10]))
            .foregroundStyle(Color(uiColor: UIColor.label))
            .annotation(position: .top, alignment: .leading) {
              Text("Average: \(Duration.seconds(locationProvider.average * 60.0 * 60.0), format: .time(pattern: .hourMinute)) hours")
                .font(.footnote)
                .foregroundStyle(Color(uiColor: UIColor.label))
                .padding(.horizontal, 5)
                .background(Color(uiColor: UIColor.systemBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
            }

        }.animation(.default, value: locationProvider.dayEntries)
      }
      .padding()
      .onChange(of: selectedTimeFrame) { newValue in
        switch newValue {
          case 0:
            locationProvider.numberOfDays = 7
          case 1:
            locationProvider.numberOfDays = 30
          default:
            locationProvider.numberOfDays = 30
        }
      }
    }
}

struct OutsideDurationChartView_Previews: PreviewProvider {

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
    OutsideDurationChartView()
      .previewLayout(.sizeThatFits)
      .environmentObject(locationProvider)
  }
}
