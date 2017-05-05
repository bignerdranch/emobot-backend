import Fluent

struct TestTableSetup: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("posts3") { kudos in
            kudos.id()
            kudos.string("from_user")
            kudos.string("to_user")
            kudos.string("description")
            kudos.string("channel")
            kudos.string("date_sent")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("posts3")
    }
}
