import Foundation
import ApplicationServices

final class PermissionService {
    var isTrusted: Bool { AXIsProcessTrusted() }

    @discardableResult
    func ensureTrusted(prompt: Bool) -> Bool {
        if AXIsProcessTrusted() { return true }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options: NSDictionary = [key: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }
}
