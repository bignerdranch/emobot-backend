import Vapor
import Fluent
import Foundation

public final class Emoji: Model {
    
    public static var entity = "emoji"
    
    public var exists = false
    public var id: Node?
    public var valueID: Node?
    public var character: String
    public var alphaCode: String
    
    public init(valueID: Node? = nil, character: String, alphaCode: String) {
        self.valueID = valueID
        self.character = character
        self.alphaCode = alphaCode
    }
    
    public init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        valueID = try node.extract("value_id")
        character = try node.extract("character")
        alphaCode = try node.extract("alpha_code")
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "value_id": valueID,
            "character": character,
            "alpha_code": alphaCode,
        ])
    }
}

extension Emoji {
    public func value() throws -> Value {
        guard let value = try parent(valueID, nil, Value.self).get() else {
            preconditionFailure("Emoji's Value should not be nil")
        }
        return value
    }
}

extension Emoji: Hashable, Equatable {
    public var hashValue: Int {
        return character.hashValue ^
            alphaCode.hashValue
    }
    
    public static func ==(lhs: Emoji, rhs: Emoji) -> Bool {
        return lhs.valueID == rhs.valueID &&
            lhs.character == rhs.character &&
            lhs.alphaCode == rhs.alphaCode
    }
}

extension Emoji: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create("emoji") { kudos in
            kudos.id()
            kudos.string("value_id")
            kudos.string("character")
            kudos.string("alpha_code")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("emoji")
    }
}
