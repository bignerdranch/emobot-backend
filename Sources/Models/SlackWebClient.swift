import HTTP
import JSON

public struct SlackWebClient {
    
    let token: String
    
    public init(token: String) {
        self.token = token
    }
    
    private let baseURL = "https://slack.com/api"

    private func url(for endpoint: String) -> String {
        return "\(baseURL)/\(endpoint)"
    }
    
    private func sendRequest(for endpoint: String, query: [String: CustomStringConvertible]) throws -> Response {
        var fullQuery = query
        fullQuery["token"] = token
        return try BasicClient.get(url(for: endpoint), query: fullQuery)
    }
    
    public func getUserName(forID userID: String) throws -> String? {
        let response = try sendRequest(for: "users.info", query: ["user": userID])
        guard let bytes = response.body.bytes else {
            return nil
        }
        let json = try JSON(bytes: bytes)
        return json["user", "name"]?.string
    }
    
    public func getUsers() throws -> JSON? {
        let response = try sendRequest(for: "users.list", query: ["presence": false])
        guard let bytes = response.body.bytes else {
            return nil
        }
        return try JSON(bytes: bytes)
    }
    
    public func getChannelName(forID channelID: String) throws -> String? {
        if channelID.hasPrefix("G") {
            let response = try sendRequest(for:"groups.info", query: ["channel": channelID])
            guard let json = response.json else {
                return nil
            }
            return json["group", "name"]?.string
        } else if channelID.hasPrefix("C") {
            let response = try sendRequest(for:"channels.info", query: ["channel": channelID])
            guard let json = response.json else {
                return nil
            }
            return json["channel", "name"]?.string
        }
        return nil
    }
    
    public func react(with emojiName: String, toMessageIn channelID: String, at timestamp: String) throws {
        let query = ["name": emojiName, "channel": channelID, "timestamp": timestamp]
        _ = try sendRequest(for: "reactions.add", query: query)
    }
}
