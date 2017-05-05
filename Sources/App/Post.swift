import Vapor
import Fluent
import Foundation

final class Post: Model {
    static var entity = "posts2"
    
    var exists: Bool = false
    var id: Node?
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
    
    init(fromUser: String, toUser: String, description: String, channel: String, dateSent: String) {
        self.fromUser = fromUser
        self.toUser = toUser
        self.description = description
        self.channel = channel
        self.dateSent = dateSent
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        fromUser = try node.extract("from_user")
        toUser = try node.extract("to_user")
        description = try node.extract("description")
        channel = try node.extract("channel")
        dateSent = Post.now()
    }
    
    func makeNode(context: Context) throws -> Node {
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

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("posts2") { kudos in
            kudos.id()
            kudos.string("from_user")
            kudos.string("to_user")
            kudos.string("description")
            kudos.string("channel")
            kudos.string("date_sent")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("posts2")
    }
}
