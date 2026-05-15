import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey]

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@", String(describing: message))

        guard let messageDict = message as? [String: Any],
              let urlString = messageDict["url"] as? String
        else {
            let errorResponse = NSExtensionItem()
            errorResponse.userInfo = [SFExtensionMessageKey: ["status": "error", "reason": "invalid_message"]]
            context.completeRequest(returningItems: [errorResponse])
            return
        }

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "?&=#")
        let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: allowed) ?? urlString

        guard let deepLink = URL(string: "miraknit://add?url=\(encodedURL)") else {
            let errorResponse = NSExtensionItem()
            errorResponse.userInfo = [SFExtensionMessageKey: ["status": "error", "reason": "encoding_failed"]]
            context.completeRequest(returningItems: [errorResponse])
            return
        }

        NSWorkspace.shared.open(deepLink)

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["status": "ok"]]
        context.completeRequest(returningItems: [response])
    }
}
