//
//  HaruWidgetLiveActivity.swift
//  HaruWidget
//
//  Created by 임경택 on 10/5/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HaruWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HaruWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HaruWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HaruWidgetAttributes {
    fileprivate static var preview: HaruWidgetAttributes {
        HaruWidgetAttributes(name: "World")
    }
}

extension HaruWidgetAttributes.ContentState {
    fileprivate static var smiley: HaruWidgetAttributes.ContentState {
        HaruWidgetAttributes.ContentState(emoji: "😀")
     }

     fileprivate static var starEyes: HaruWidgetAttributes.ContentState {
         HaruWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HaruWidgetAttributes.preview) {
   HaruWidgetLiveActivity()
} contentStates: {
    HaruWidgetAttributes.ContentState.smiley
    HaruWidgetAttributes.ContentState.starEyes
}
