import Foundation
import HTTP
import Vapor

class Bot {
    let token: String
    
    private func webSocketURL() throws -> String {
        let rtmResponse = try BasicClient.loadRealtimeApi(token: token)
        guard let webSocketURL = rtmResponse.data["url"]?.string else { throw BotError.invalidResponse }
        return webSocketURL
    }
    
    init(token: String) {
        self.token = token
    }
    
    func run() throws {
        let webSocketURL = try self.webSocketURL()
        try WebSocket.connect(to: webSocketURL) { ws in
            print("Connected to \(self.webSocketURL)")
            
            ws.onText = { ws, text in
                print("[event] - \(text)")
                
                let event = try JSON(bytes: text.utf8.array)
                guard
                    let fromUser = event["user"]?.string,
                    let channel = event["channel"]?.string,
                    let text = event["text"]?.string
                    else { return }

                if text.hasPrefix("hello") {
                    let response = SlackMessage(to: channel, text: "Hi there 👋")
                    try ws.send(response)
                    return
                } else if text.hasPrefix("version") {
                    let response = SlackMessage(to: channel, text: "Current Version: \(VERSION)")
                    try ws.send(response)
                    return
                }
                
                let kudoRegex = try NSRegularExpression(pattern: "(\\w+)\\+\\+\\s+(.*)")
                if let match = kudoRegex.actuallyUsableMatch(in: text) {
                    let toUser = match.captures[0]
                    let description = match.captures[1]
                    let response = SlackMessage(to: channel, text: "\(fromUser) sent kudos to \(toUser) in \(channel) for \(description)")
                    try ws.send(response)
                }
            }
            
            ws.onClose = { ws, _, _, _ in
                print("\n[CLOSED]\n")
            }
        }
    }
}

extension NSRegularExpression {
    func actuallyUsableMatch(in string: String) -> (fullMatch: String, captures: [String])? {
        let nsString = string as NSString
        let range = NSMakeRange(0, nsString.length)
        guard let match = firstMatch(in: string, range: range) else {
            return nil
        }
        
        let fullMatch = nsString.substring(with: match.range)
        var captures: [String] = []
        for i in 1 ..< match.numberOfRanges {
            captures.append(nsString.substring(with: match.rangeAt(i)))
        }
        return (fullMatch, captures)
    }
}

extension Bot {
    convenience init() throws {
        let config = try Config(prioritized: [.directory(root: workingDirectory + "Config/secrets"),
                                              .directory(root: workingDirectory + "Config/")])
        guard let token = config["bot", "token"]?.string else { throw BotError.missingConfig }
        self.init(token: token)
    }
}
