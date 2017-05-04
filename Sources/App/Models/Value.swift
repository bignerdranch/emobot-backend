import Vapor
import Fluent
import Foundation

final class Value: Model {
    var exists = false
    var id: Node?
    var name: String
    var emoji: String
    var alphaCode: String
    
    init(name: String, emoji: String, alphaCode: String) {
        self.id = UUID().uuidString.makeNode()
        self.name = name
        self.emoji = emoji
        self.alphaCode = alphaCode
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        emoji = try node.extract("emoji")
        alphaCode = try node.extract("alpha_code")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "emoji": emoji,
            "alpha_code": alphaCode,
        ])
    }
}

extension Value {
    func reactions() throws -> [Reaction] {
        return try children(nil, Reaction.self).all()
    }
}

extension Value: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("values") { kudos in
            kudos.id()
            kudos.string("name")
            kudos.string("emoji")
            kudos.string("alpha_code")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("values")
    }
}
