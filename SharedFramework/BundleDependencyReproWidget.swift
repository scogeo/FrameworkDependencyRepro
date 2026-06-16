//
//  BundleDependencyReproWidget.swift
//  BundleDependencyReproWidget
//
//  Created by George Scott on 6/16/26.
//

import WidgetKit
import SwiftUI
internal import SharedModels
internal import Dependencies

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), model: nil, configuration: ConfigurationAppIntent())
  }
  
  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
    SimpleEntry(date: Date(), model: nil, configuration: configuration)
  }
  
  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
    
    @Dependency(\.myModelStore) var modelStore
    
    let model = try! await modelStore.load(id: UUID())
    
    var entries: [SimpleEntry] = []
    
    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, model: model, configuration: configuration)
      entries.append(entry)
    }
    
    return Timeline(entries: entries, policy: .atEnd)
  }
  
  //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
  //        // Generate a list containing the contexts this widget is relevant in.
  //    }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let model: MyModel?
  let configuration: ConfigurationAppIntent
}

struct BundleDependencyReproWidgetEntryView : View {
  var entry: Provider.Entry
  
  var body: some View {
    VStack {
      Text("Time:")
      Text(entry.date, style: .time)
      
      Text("Favorite Emoji:")
      Text(entry.configuration.favoriteEmoji)
    }
  }
}

public struct BundleDependencyReproWidget: Widget {
  public let kind: String = "BundleDependencyReproWidget"
  
  public init() {}
  
  public var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
      BundleDependencyReproWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

extension ConfigurationAppIntent {
  fileprivate static var smiley: ConfigurationAppIntent {
    let intent = ConfigurationAppIntent()
    intent.favoriteEmoji = "😀"
    return intent
  }
  
  fileprivate static var starEyes: ConfigurationAppIntent {
    let intent = ConfigurationAppIntent()
    intent.favoriteEmoji = "🤩"
    return intent
  }
}

#Preview(as: .systemSmall) {
  BundleDependencyReproWidget()
} timeline: {
  SimpleEntry(date: .now, model: nil, configuration: .smiley)
  SimpleEntry(date: .now, model: nil, configuration: .starEyes)
}
