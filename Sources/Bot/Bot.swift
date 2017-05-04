import Foundation
import HTTP
import Vapor

class Bot {
    let token: String
    let webClient: SlackWebClient
    
    private func webSocketURL() throws -> String {
        let rtmResponse = try BasicClient.loadRealtimeApi(token: token)
        guard let webSocketURL = rtmResponse.data["url"]?.string else { throw BotError.invalidResponse }
        return webSocketURL
    }
    
    init(token: String) {
        self.token = token
        self.webClient = SlackWebClient(token: token)
    }
    
    func run() throws {
        let webSocketURL = try self.webSocketURL()
        try WebSocket.connect(to: webSocketURL) { ws in
            print("Connected to \(self.webSocketURL)")
            
            ws.onText = { ws, text in
                print("[event] - \(text)")
                
                let event = try JSON(bytes: text.utf8.array)
                guard
                    let fromUserID = event["user"]?.string,
                    let channelID = event["channel"]?.string,
                    let text = event["text"]?.string
                    else { return }

                if text.hasPrefix("hello") {
                    let response = SlackMessage(to: channelID, text: "Hi there 👋")
                    try ws.send(response)
                    return
                } else if text.hasPrefix("version") {
                    let response = SlackMessage(to: channelID, text: "Current Version: \(VERSION)")
                    try ws.send(response)
                    return
                }
                
                let kudoRegex = try NSRegularExpression(pattern: "(\\w+)\\+\\+\\s+(.*)")
                if let match = kudoRegex.actuallyUsableMatch(in: text) {
                    let toUser = match.captures[0]
                    let description = match.captures[1]
                    let channel = try self.webClient.getChannelName(forID: channelID)
                    let fromUser = try self.webClient.getUserName(forID: fromUserID)

                    let response = SlackMessage(to: channelID, text: "\(fromUser ?? "-") sent kudos to \(toUser) in \(channel ?? "-"): \(description)")
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
