import Foundation
import HTTP
import Models
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
            print("Connected to \(webSocketURL)")
            
            ws.onText = { ws, text in
                print("[event] - \(text)")
                
                let event = try JSON(bytes: text.utf8.array)
                guard
                    let type = event["type"]?.string,
                    let fromUserID = event["user"]?.string
                    else { return }


                do {
                    if let text = event["text"]?.string,
                        let channelID = event["channel"]?.string,
                        let timestamp = event["ts"]?.string
                    {
                        if text.hasPrefix("hello") {
                            let response = SlackMessage(to: channelID, text: "Hi there 👋")
                            try ws.send(response)
                            return
                        } else if text.hasPrefix("version") {
                            let response = SlackMessage(to: channelID, text: "Current Version: \(VERSION)")
                            try ws.send(response)
                            return
                        }
                        
                        let kudoRegex = try NSRegularExpression(pattern: "(\\w+)\\+\\+\\s+(.*)", options: [])
                        if let match = kudoRegex.actuallyUsableMatch(in: text) {
                            let toUser = match.captures[0]
                            let description = match.captures[1]
                            guard
                                let channel = try self.webClient.getChannelName(forID: channelID),
                                let fromUser = try self.webClient.getUserName(forID: fromUserID) else {
                                    return
                            }

                            var kudo = Kudo(fromUser: fromUser, toUser: toUser, description: description, channel: channel, timestamp: timestamp)
                            try kudo.save()

                            let values = try Value.all()
                            for value in values where text.contains(":\(value.emojiAlphaCode):") {
                                var reaction = Reaction(kudoID: kudo.id, valueID: value.id, fromUser: fromUser)
                                try reaction.save()
                                try self.webClient.react(with: value.emojiAlphaCode, toMessageIn: channelID, at: timestamp)
                            }
                        }
                    }
                    
                    if type == "reaction_added" {
                        guard
                            let emojiAlphaCode = event["reaction"]?.string,
                            let value = try Value.query().filter("emoji_alpha_code", emojiAlphaCode).first(),
                            let fromUser = try self.webClient.getUserName(forID: fromUserID),
                            !fromUser.contains("bot"), // TODO: make detecting own name better
                            let item = event["item"]?.object,
                            let channelID = item["channel"]?.string,
                            let channel = try self.webClient.getChannelName(forID: channelID),
                            let timestamp = item["ts"]?.string
                            else
                        {
                                return
                        }
                        
                        guard let kudo = try Kudo.query().filter("channel", channel).filter("timestamp", timestamp).first() else {
                            print("Couldn't find kudo for channel \(channel), timestamp \(timestamp)")
                            return
                        }


                        var reaction = Reaction(kudoID: kudo.id, valueID: value.id, fromUser: fromUser)
                        try reaction.save()
                        
                        let response = SlackMessage(to: channelID, text: "Recorded additional reaction of \(value.name) on \(kudo.description)")
                        try ws.send(response)
                    }
                } catch {
                    print("Error: \(error)")
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
        let nsString = NSString(string: string)
        let range = NSMakeRange(0, nsString.length)
        guard let match = firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        
        let fullMatch = nsString.substring(with: match.range)
        var captures: [String] = []
        for i in 1 ..< match.numberOfRanges {
            #if os(Linux)
                let range = match.range(at: i)
            #else
                let range = match.rangeAt(i)
            #endif
            captures.append(nsString.substring(with: range))
        }
        return (fullMatch, captures)
    }
}
