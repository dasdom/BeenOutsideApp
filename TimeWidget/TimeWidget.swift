//  Created by Dominik Hauser on 16.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> RegionUpdateEntry {
    RegionUpdateEntry(date: Date(), exitDate: .distantPast, updateType: .exit)
  }

  func getSnapshot(in context: Context, completion: @escaping (RegionUpdateEntry) -> ()) {
    let entry = RegionUpdateEntry(date: Date(), exitDate: .distantPast, updateType: .exit)
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [RegionUpdateEntry] = []

    //        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    //        let currentDate = Date()
    //        for hourOffset in 0 ..< 5 {
    //            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
    //            let entry = SimpleEntry(date: entryDate)
    //            entries.append(entry)
    //        }

    do {
      let data = try Data(contentsOf: FileManager.default.lastUpdatURL())
      let lastUpdate = try JSONDecoder().decode(RegionUpdate.self, from: data)
      let entry = RegionUpdateEntry(date: Date(), exitDate: lastUpdate.date, updateType: lastUpdate.updateType)
      entries.append(entry)
    } catch {
      print("\(#filePath), \(#line): error: \(error)")

    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct RegionUpdateEntry: TimelineEntry {
  let date: Date
  let exitDate: Date
  let updateType: UpdateType
}

struct TimeWidgetEntryView : View {

  @Environment(\.widgetFamily) var family
  var entry: Provider.Entry

  var body: some View {
    VStack(alignment: .center) {
      decorationViews(for: entry.updateType, widgetFamily: family)
      Text(entry.exitDate, style: .relative)
        .font(.subheadline)
        .bold()
        .multilineTextAlignment(.center)
    }
    .padding(family == .accessoryRectangular ? 2 : 5)
  }

  func decorationViews(for updateType: UpdateType, widgetFamily: WidgetFamily) -> some View {
    let imageName: String
    let text: String
    switch updateType {
      case .exit:
        imageName = "leaf"
        text = "Outside since"
      case .enter:
        imageName = "house"
        text = "Inside since"
    }
    if widgetFamily == .accessoryRectangular {
      return AnyView(
        HStack {
          Image(systemName: imageName)
          Text(text)
        }
          .font(.subheadline)
      )
    } else {
      return AnyView(
        VStack {
          Image(systemName: imageName)
            .font(.largeTitle)
          Text(text)
            .font(.subheadline)
        }
      )
    }
  }
}

@main
struct TimeWidget: Widget {
  let kind: String = "TimeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      TimeWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("My Widget")
    .description("This is an example widget.")
    .supportedFamilies([.accessoryRectangular, .systemSmall])
  }
}

//struct TimeWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        TimeWidgetEntryView(entry: SimpleEntry(date: Date()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
