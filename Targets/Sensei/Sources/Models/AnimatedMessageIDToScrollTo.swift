import SwiftUI

struct AnimatedMessageIDToScrollTo: Equatable {
    let animated: Bool
    let messageID: Message.ID
    let anchor: UnitPoint
}
