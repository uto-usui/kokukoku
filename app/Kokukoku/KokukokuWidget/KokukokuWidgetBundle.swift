import SwiftUI
import WidgetKit

@main
struct KokukokuWidgetBundle: WidgetBundle {
    var body: some Widget {
        KokukokuStatusWidget()
        KokukokuLiveActivityWidget()
    }
}
