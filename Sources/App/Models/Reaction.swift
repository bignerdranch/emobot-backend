import Vapor
import Fluent
import Foundation

final class Reaction: Model {
    var exists = false
    var id: Node?
    var kudoID: Node?
    var valueID: Node?
    var fromUser: String
    var dateSent: String
    
    init(kudoID: Node? = nil, valueID: Node? = nil, fromUser: String, dateSent: String) {
        self.id = UUID().uuidString.makeNode()
        self.kudoID = kudoID
        self.valueID = valueID
        self.fromUser = fromUser
        self.dateSent = dateSent
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        kudoID = try node.extract("kudo_id")
        valueID = try node.extract("value_id")
        fromUser = try node.extract("from_user")
        dateSent = try node.extract("date_sent")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "kudo_id": kudoID,
            "value_id": valueID,
            "from_user": fromUser,
            "date_sent": dateSent,
        ])
    }
}

extension Reaction {
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
    static func prepare(_ database: Database) throws {
        try database.create("reactions") { kudos in
            kudos.id()
            kudos.parent(Kudo.self, optional: false)
            kudos.parent(Value.self, optional: false)
            kudos.string("from_user")
            kudos.string("date_sent")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("reactions")
    }
}
