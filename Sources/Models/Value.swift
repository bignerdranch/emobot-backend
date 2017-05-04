import Vapor
import Fluent
import Foundation

public final class Value: Model {
    public var exists = false
    public var id: Node?
    public var name: String
    public var slug: String
    public var emojiCharacter: String
    public var emojiAlphaCode: String
    
    public init(name: String, slug: String, emojiCharacter: String, emojiAlphaCode: String) {
        self.name = name
        self.slug = slug
        self.emojiCharacter = emojiCharacter
        self.emojiAlphaCode = emojiAlphaCode
    }
    
    public init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        slug = try node.extract("slug")
        emojiCharacter = try node.extract("emoji_character")
        emojiAlphaCode = try node.extract("emoji_alpha_code")
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "slug": slug,
            "emoji_character": emojiCharacter,
            "emoji_alpha_code": emojiAlphaCode,
        ])
    }
}

extension Value: Hashable, Equatable {
    public var hashValue: Int {
        return name.hashValue ^
            slug.hashValue ^
            emojiCharacter.hashValue ^
            emojiAlphaCode.hashValue
    }
    
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        return lhs.name == rhs.name &&
            lhs.slug == rhs.slug &&
            lhs.emojiCharacter == rhs.emojiCharacter &&
            lhs.emojiAlphaCode == rhs.emojiAlphaCode
    }
}

public extension Value {
    func reactions() throws -> [Reaction] {
        return try children(nil, Reaction.self).all()
    }
}

extension Value: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create("values") { kudos in
            kudos.id()
            kudos.string("name")
            kudos.string("slug")
            kudos.string("emoji_character")
            kudos.string("emoji_alpha_code")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("values")
    }
}
