import Foundation
import SwiftUI

/// Bridges SwiftUI's `OpenWindowAction` into an injectable dependency so non-view code
/// (coordinators, services) can open auxiliary windows by ID without holding a view reference.
@MainActor
final class WindowOpener {
    var openWindow: OpenWindowAction?

    func open(id: String) {
        openWindow?(id: id)
    }
}
