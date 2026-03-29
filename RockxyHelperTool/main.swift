import Foundation
import os

// Boots the privileged helper, restores stale proxy state, and starts the XPC listener.

private let logger = Logger(subsystem: "com.amunx.Rockxy.HelperTool", category: "Main")

logger.info("RockxyHelperTool starting up")

// Check for stale proxy settings from a previous crash
CrashRecovery.restoreIfNeeded()

let delegate = HelperDelegate()
let machServiceName = Bundle.main.infoDictionary?["RockxyHelperMachServiceName"] as? String ?? "com.amunx.Rockxy.HelperTool"
let listener = NSXPCListener(machServiceName: machServiceName)
listener.delegate = delegate
listener.resume()

logger.info("RockxyHelperTool listening on Mach service \(machServiceName)")

RunLoop.current.run()
