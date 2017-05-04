import Vapor
import Fluent
import Foundation

final class Value: Model {
    var exists = false
    var id: Node?
    var name: String
    var emojiAlphaCode: String
    
    init(name: String, emojiAlphaCode: String) {
        self.id = UUID().uuidString.makeNode()
        self.name = name
        self.emojiAlphaCode = emojiAlphaCode
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        emojiAlphaCode = try node.extract("emoji_alpha_code")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "emoji_alpha_code": emojiAlphaCode,
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
            kudos.string("emoji_alpha_code")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("values")
    }
}
