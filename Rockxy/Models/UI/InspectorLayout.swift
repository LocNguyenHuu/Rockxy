/// Controls the inspector panel's position relative to the request list.
/// `.hidden` collapses the inspector entirely; `.right` and `.bottom` correspond
/// to the horizontal/vertical split layout toggle in the toolbar.
enum InspectorLayout: Equatable {
    case hidden
    case right
    case bottom
}
