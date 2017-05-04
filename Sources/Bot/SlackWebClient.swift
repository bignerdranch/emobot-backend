import HTTP
import JSON

struct SlackWebClient {
    
    let token: String
    
    private let baseURL = "https://slack.com/api"

    private func url(for endpoint: String) -> String {
        return "\(baseURL)/\(endpoint)"
    }
    
    private func sendRequest(for endpoint: String, query: [String: CustomStringConvertible]) throws -> Response {
        var fullQuery = query
        fullQuery["token"] = token
        return try BasicClient.get(url(for: endpoint), query: fullQuery)
    }
    
    func getUserName(forID userID: String) throws -> String? {
        let response = try sendRequest(for: "users.info", query: ["user": userID])
        guard let bytes = response.body.bytes else {
            return nil
        }
        let json = try JSON(bytes: bytes)
        return json["user", "name"]?.string
    }
    
    func getChannelName(forID channelID: String) throws -> String? {
        let response = try sendRequest(for:"groups.info", query: ["channel": channelID])
        guard let bytes = response.body.bytes else {
            return nil
        }
        let json = try JSON(bytes: bytes)
        return json["group", "name"]?.string
    }
}
