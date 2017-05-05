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
    
    let directKudoRegex = try! NSRegularExpression(pattern: "(\\w+)\\+\\+\\s+(.*)", options: [])
    let atKudoRegex = try! NSRegularExpression(pattern: "<@(\\w+)>\\+\\+\\s+(.*)", options: [])
    
    private func findKudo(in text: String) throws -> (toUser: String, description: String)? {
        // direct username
        if let match = directKudoRegex.actuallyUsableMatch(in: text) {
            let toUser = match.captures[0]
            let description = match.captures[1]
            return (toUser, description)
        }
        
        // @ username
        if let match = atKudoRegex.actuallyUsableMatch(in: text) {
            let toUserID = match.captures[0]
            let description = match.captures[1]
            if let toUser = try webClient.getUserName(forID: toUserID) {
                return (toUser, description)
            }
        }
        return nil
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
                        if let (toUser, description) = try self.findKudo(in: text) {
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
                        // handles if multiple emoji are sent in the reaction, e.g. skin tones
                        let alphaCodeRegex = try NSRegularExpression(pattern: "([-_a-zA-Z]+)", options: [])
                        guard
                            let emojiAlphaCode = event["reaction"]?.string,
                            let emojiMatch = alphaCodeRegex.actuallyUsableMatch(in: emojiAlphaCode),
                            let value = try Value.query().filter("emoji_alpha_code", emojiMatch.captures[0]).first(),
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
                        print("Recorded additional reaction of \(value.name) on \(kudo.description)")
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
