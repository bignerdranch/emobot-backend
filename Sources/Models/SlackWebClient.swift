import HTTP
import JSON

public class SlackWebClient {
    
    let token: String
    
    public init(token: String) {
        self.token = token
    }
    
    private let baseURL = "https://slack.com/api"

    private var channelNameCache: [String: String] = [:]
    private var userNameCache: [String: String] = [:]
    
    // TODO: for demo performance. not a good idea to keep!
    private var userCache: JSON?
    
    private func url(for endpoint: String) -> String {
        return "\(baseURL)/\(endpoint)"
    }
    
    private func sendRequest(for endpoint: String, query: [String: CustomStringConvertible]) throws -> Response {
        print("SENDING SLACK REQUEST: \(endpoint)")
        var fullQuery = query
        fullQuery["token"] = token
        return try BasicClient.get(url(for: endpoint), query: fullQuery)
    }
    
    public func getUserName(forID userID: String) throws -> String? {
        if let name = userNameCache[userID] {
            return name
        }

        let response = try sendRequest(for: "users.info", query: ["user": userID])
        let name = response.json?["user", "name"]?.string
        userNameCache[userID] = name
        return name
    }
    
    public func getUsers() throws -> JSON? {
        if let users = userCache {
            return users
        }
        
        let response = try sendRequest(for: "users.list", query: ["presence": false])
        
        let users = response.json
        userCache = users
        return users
    }
    
    public func getChannelName(forID channelID: String) throws -> String? {
        if let name = channelNameCache[channelID] {
            return name
        }
        
        var name: String?
        if channelID.hasPrefix("G") {
            let response = try sendRequest(for:"groups.info", query: ["channel": channelID])
            name = response.json?["group", "name"]?.string
        } else if channelID.hasPrefix("C") {
            let response = try sendRequest(for:"channels.info", query: ["channel": channelID])
            name = response.json?["channel", "name"]?.string
        }
        
        if let name = name {
            channelNameCache[channelID] = name
        }
        
        return name
    }
    
    public func sendMessage(to channelID: String, text: String, inReplyToMessageWithTimestamp threadTS: String? = nil, attachments: [[String: String]]) throws {
        let attachmentJSON = try JSON(node: attachments.map({ try JSON(node: $0) }))
        let attachmentString = try attachmentJSON.makeBytes().string()
        var query = ["channel": channelID, "text": text, "as_user": "true", "attachments": attachmentString]
        if let threadTS = threadTS {
            query["thread_ts"] = threadTS
        }
        _ = try sendRequest(for: "chat.postMessage", query: query)
    }
    
    public func react(with emojiName: String, toMessageIn channelID: String, at timestamp: String) throws {
        let query = ["name": emojiName, "channel": channelID, "timestamp": timestamp]
        _ = try sendRequest(for: "reactions.add", query: query)
    }
}
