import Vapor
import Fluent
import Foundation

enum KudoError: Error {
    case databaseNotConfigured
    case recordNotSaved
}

public final class Kudo: Model {
    public var exists = false
    public var id: Node?
    public var fromUser: String
    public var toUser: String
    public var description: String
    public var channel: String
    public var timestamp: String
    
    public init(fromUser: String, toUser: String, description: String, channel: String, timestamp: String) {
        self.fromUser = fromUser
        self.toUser = toUser
        self.description = description
        self.channel = channel
        self.timestamp = timestamp
    }

    public init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fromUser = try node.extract("from_user")
        toUser = try node.extract("to_user")
        description = try node.extract("description")
        channel = try node.extract("channel")
        timestamp = try node.extract("timestamp")
    }

    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "from_user": fromUser,
            "to_user": toUser,
            "description": description,
            "channel": channel,
            "timestamp": timestamp,
        ])
    }
}

public extension Kudo {
    func reactions() throws -> [Reaction] {
        return try children(nil, Reaction.self).all()
    }
    
    func reactionCountsByValue() throws -> [String: Int] {
        guard let pg = Kudo.database?.driver else {
            throw KudoError.databaseNotConfigured
        }
        guard let id = id?.int else {
            throw KudoError.recordNotSaved
        }
        let result: Node = try pg.raw("SELECT v.slug AS value, (SELECT COUNT(*) FROM kudos k JOIN reactions r ON k.id = r.kudo_id WHERE r.value_id = v.id AND k.id = $1) AS points FROM values v ORDER BY v.slug ASC", [id])
        let resultArray = result.array!
        
        var reactionCountsByValue: [String: Int] = [:]
        for row in resultArray {
            if let rowObject = row.object,
                let value = rowObject["value"]?.string,
                let points = rowObject["points"]?.int
            {
                reactionCountsByValue[value] = points
            }
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
            kudos.string("timestamp")
        }
    }

    public static func revert(_ database: Database) throws {
        try database.delete("kudos")
    }
}
