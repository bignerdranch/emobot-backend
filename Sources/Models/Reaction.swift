import Vapor
import Fluent
import Foundation

public final class Reaction: Model {
    public var exists = false
    public var id: Node?
    public var kudoID: Node?
    public var valueID: Node?
    public var fromUser: String
    public var dateSent: String
    
    public init(kudoID: Node? = nil, valueID: Node? = nil, fromUser: String, dateSent: String) {
        self.kudoID = kudoID
        self.valueID = valueID
        self.fromUser = fromUser
        self.dateSent = dateSent
    }
    
    public init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        kudoID = try node.extract("kudo_id")
        valueID = try node.extract("value_id")
        fromUser = try node.extract("from_user")
        dateSent = try node.extract("date_sent")
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "kudo_id": kudoID,
            "value_id": valueID,
            "from_user": fromUser,
            "date_sent": dateSent,
        ])
    }
}

public extension Reaction {
    func kudo() throws -> Kudo {
        guard let kudo = try parent(kudoID, nil, Kudo.self).get() else {
            preconditionFailure("Reaction's Kudo should not be nil")
        }
        return kudo
    }
    
    func value() throws -> Value {
        guard let value = try parent(valueID, nil, Value.self).get() else {
            preconditionFailure("Reaction's Value should not be nil")
        }
        return value
    }
}

extension Reaction: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create("reactions") { kudos in
            kudos.id()
            kudos.parent(Kudo.self, optional: false)
            kudos.parent(Value.self, optional: false)
            kudos.string("from_user")
            kudos.string("date_sent")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("reactions")
    }
}
