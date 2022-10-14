//  Created by Dominik Hauser on 30.09.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import SwiftUI
import Charts

struct DurationChart: View {
  @EnvironmentObject private var locationProvider: LocationProvider
  @Binding var selectedElement: DayEntry?

  func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> DayEntry? {
    let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
    if let date = proxy.value(atX: relativeXPosition) as Date? {
      // Find the closest date element.
      var minDistance: TimeInterval = .infinity
      var index: Int? = nil
      for salesDataIndex in locationProvider.dayEntries.indices {
        let nthSalesDataDistance = locationProvider.dayEntries[salesDataIndex].weekday.distance(to: date)
        if abs(nthSalesDataDistance) < minDistance {
          minDistance = abs(nthSalesDataDistance)
          index = salesDataIndex
        }
      }
      if let index = index {
        return locationProvider.dayEntries[index]
      }
    }
    return nil
  }

  var body: some View {
    Chart {
      ForEach(locationProvider.dayEntries, id: \.self) { entry in
        BarMark(
          x: .value("Day", entry.weekday, unit: .day),
          y: .value("Duration", entry.duration / 3600)
        )
        .foregroundStyle(by: .value("Type", entry.isCurrent ? "Current" : "Past" ))
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

    }
    .chartOverlay { proxy in
      GeometryReader { nthGeometryItem in
        Rectangle()
          .fill(.clear)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged({ value in
                let element = findElement(location: value.location,
                                          proxy: proxy,
                                          geometry: nthGeometryItem)
                selectedElement = element
              })
              .onEnded { value in
                selectedElement = nil
              }
          )
      }
    }
    .animation(.default, value: locationProvider.dayEntries)
  }
}
