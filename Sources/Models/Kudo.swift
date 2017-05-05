import Vapor
import Fluent
import Foundation

public final class Kudo: Model {
    public var exists = false
    public var id: Node?
    public var fromUser: String
    public var toUser: String
    public var description: String
    public var channel: String
    public var dateSent: String
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return f
    }()
    
    private static func now() -> String {
        return dateFormatter.string(from: Date())
    }
    
    public init(fromUser: String, toUser: String, description: String, channel: String, dateSent: String) {
        self.fromUser = fromUser
        self.toUser = toUser
        self.description = description
        self.channel = channel
        self.dateSent = dateSent
    }

    public init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fromUser = try node.extract("from_user")
        toUser = try node.extract("to_user")
        description = try node.extract("description")
        channel = try node.extract("channel")
        dateSent = Kudo.now()
//        dateSent = try node.extract("date_sent") // makes the class work!
    }

    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "from_user": fromUser,
            "to_user": toUser,
            "description": description,
            "channel": channel,
            "date_sent": dateSent,
        ])
    }
}

public extension Kudo {
    func reactions() throws -> [Reaction] {
        return try children(nil, Reaction.self).all()
    }
    
    func reactionCountsByValue() throws -> [Value: Int] {
        let reactions = try self.reactions()
        var reactionCountsByValue: [Value: Int] = [:]
        for value in try Value.all() {
            reactionCountsByValue[value] = reactions.filter({ $0.valueID == value.id }).count
        }
        return reactionCountsByValue
    }
}

extension Kudo: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create("kudos") { kudos in
            kudos.id()
            kudos.string("from_user")
            kudos.string("to_user")
            kudos.string("description")
            kudos.string("channel")
            kudos.string("date_sent")
        }
    }

    public static func revert(_ database: Database) throws {
        try database.delete("kudos")
    }
}
