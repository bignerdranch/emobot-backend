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
                    let channel = event["channel"]?.string,
                    let text = event["text"]?.string
                    else { return }
                
                if text.hasPrefix("hello") {
                    let response = SlackMessage(to: channel, text: "Hi there 👋")
                    try ws.send(response)
                } else if text.hasPrefix("version") {
                    let response = SlackMessage(to: channel, text: "Current Version: \(VERSION)")
                    try ws.send(response)
                }
            }
            
            ws.onClose = { ws, _, _, _ in
                print("\n[CLOSED]\n")
            }
        }
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
