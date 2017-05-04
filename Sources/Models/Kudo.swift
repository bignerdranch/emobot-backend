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
        dateSent = try node.extract("date_sent")
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
    // TODO: reactions by value, reaction counts by value
    func reactions() throws -> [Reaction] {
        return try children(nil, Reaction.self).all()
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
