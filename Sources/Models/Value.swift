import Vapor
import Fluent
import Foundation

public final class Value: Model {
    public var exists = false
    public var id: Node?
    public var name: String
    public var slug: String
    
    public init(name: String, slug: String) {
        self.name = name
        self.slug = slug
    }
    
    public init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        slug = try node.extract("slug")
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "slug": slug,
        ])
    }
}

extension Value: Hashable, Equatable {
    public var hashValue: Int {
        return name.hashValue ^
            slug.hashValue
    }
    
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        return lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }
}

public extension Value {
    func emoji() throws -> [Emoji] {
        return try children(nil, Emoji.self).all()
    }
    
    func reactions() throws -> [Reaction] {
        return try children(nil, Reaction.self).all()
    }
    
    func kudos() throws -> [Kudo] {
        guard let id = id?.int else {
            preconditionFailure("Attempted to get kudos for an unsaved value")
        }
        return try Kudo.query()
            .union(Reaction.self, localKey: "id", foreignKey: "kudo_id")
            .filter(Reaction.self, "value_id", .equals, id)
            .sort("id", .descending)
            .all()
    }
}

extension Value: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create("values") { kudos in
            kudos.id()
            kudos.string("name")
            kudos.string("slug")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("values")
    }
}
