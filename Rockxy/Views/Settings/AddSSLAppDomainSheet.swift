import SwiftUI

// MARK: - AddSSLAppDomainSheet

/// Placeholder sheet for adding SSL proxying rules by domain.
/// A future version will show observed domains grouped by source app
/// once the traffic-capture layer exposes per-app domain aggregation
/// to secondary windows. Until then this sheet simply opens the
/// standard Add Domain editor so the user flow remains functional.
struct AddSSLAppDomainSheet: View {
    let onAdd: ([String]) -> Void

    var body: some View {
        AddSSLDomainSheet { domain in
            onAdd([domain])
        }
    }
}
