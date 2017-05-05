import Foundation
import Models
import Vapor
import VaporPostgreSQL

let drop = Droplet()
drop.preparations.append(Value.self)
drop.preparations.append(Kudo.self)
drop.preparations.append(Reaction.self)

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
} catch {
    preconditionFailure("Error adding provider: \(error)")
}

drop.middleware.insert(CORSMiddleware(), at: 0)

enum AppError: Error {
    case missingConfig
}

let config = try Config(prioritized: [.commandLine,
                                      .directory(root: workingDirectory + "Config/secrets"),
                                      .directory(root: workingDirectory + "Config/")])
guard let token = config["slack", "token"]?.string else { throw AppError.missingConfig }
let slackWebClient = SlackWebClient(token: token)

func convertKudoToJSON(_ kudo: Kudo, users: JSON?) throws -> JSON {
    var reactionCountsByValueSlug: [String: Int] = [:]
    for (value, count) in try kudo.reactionCountsByValue() {
        reactionCountsByValueSlug[value.slug] = count
    }
    
    var fromAvatar = ""
    var toAvatar = ""
    
    if let users = users {
        let memberArray = users["members"]?.array!
        for member in memberArray! {
            if let name = member.object?["name"]?.string, name == kudo.fromUser {
                if let avatar = member.object?["profile"]?.object?["image_512"]?.string {
                    fromAvatar = avatar
                }
            }
            if let name = member.object?["name"]?.string, name == kudo.toUser {
                if let avatar = member.object?["profile"]?.object?["image_512"]?.string {
                    toAvatar = avatar
                }
            }
        }
    }
    
    return try JSON(node: [
        "from": [
            "user_name": kudo.fromUser.makeNode(),
            "avatar": fromAvatar.makeNode()
        ],
        "to": [
            "user_name": kudo.toUser.makeNode(),
            "avatar": toAvatar.makeNode()
        ],
        "channel": kudo.channel.makeNode(),
        "description": kudo.description.makeNode(),
        "value_points": reactionCountsByValueSlug.makeNode(),
    ])
}


drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

func formatLeaderboardResults(_ results: Node, users: JSON) throws -> [JSON] {
    let overallResultsArray: [Polymorphic] = results.array!
    
    var formattedOverallResults: [JSON] = []
    for (i, row) in overallResultsArray.enumerated() {
        let rowObject = row.object!
        
        var avatar = ""
        let userName = rowObject["to_user"]!.string!
        let memberArray = users["members"]?.array!
        for member in memberArray! {
            if let name = member.object?["name"]?.string, name == userName {
                if let newAvatar = member.object?["profile"]?.object?["image_512"]?.string {
                    avatar = newAvatar
                }
            }
        }
        
        let result = try JSON(node: [
            "rank": i + 1,
            "user": try JSON(node: [
                "user_name": userName,
                "avatar": avatar,
                ]),
            "points": rowObject["points"]!.int!,
            ])
        formattedOverallResults.append(result)
    }
    return formattedOverallResults
}

drop.get("/leaderboard") { req in
    guard let pg = drop.database?.driver as? PostgreSQLDriver else {
        throw Abort.serverError
    }
    
    guard let users = try slackWebClient.getUsers() else {
        throw Abort.serverError
    }
    
    var valueSlugs: [String] = try Value.all().map({ $0.slug })
    valueSlugs.append("overall")
    
    var allResults: [String: Node] = [:]
    for valueSlug in valueSlugs {
        let results: Node
        if valueSlug == "overall" {
            results = try pg.raw("select k.to_user, count(*) as points from kudos k join reactions r on k.id = r.kudo_id group by k.to_user order by count(*) desc;")
        } else {
            results = try pg.raw("select k.to_user, count(*) as points from kudos k join reactions r on k.id = r.kudo_id join values v on r.value_id = v.id where v.slug = $1 group by k.to_user, v.name order by count(*) desc", [valueSlug])
        }
        let formattedResults = try formatLeaderboardResults(results, users: users)
        allResults[valueSlug] = try formattedResults.makeNode()
    }
    
    return JSON([
        "meta": ["static": false],
        "data": try allResults.makeNode(),
    ])
}

drop.get("users", String.self) { request, username in
    let sentKudos = try Kudo.query().filter("from_user", username).all()
    let receivedKudos = try Kudo.query().filter("to_user", username).all()
    
    let users = try slackWebClient.getUsers()
    let sentKudoJSONs = try sentKudos.map { try convertKudoToJSON($0, users: users) }
    let receivedKudoJSONs = try receivedKudos.map { try convertKudoToJSON($0, users: users) }
    
    return JSON([
        "meta": ["static": false],
        "data": [
            "kudos": [
                "sent": try sentKudoJSONs.makeNode(),
                "received": try receivedKudoJSONs.makeNode(),
            ],
        ],
    ])
}

drop.get("values", String.self) { req, valueSlug in
    guard let value = try Value.query().filter("slug", valueSlug).first() else {
        return "KUDO NOT FOUND"
    }
    
    let users = try slackWebClient.getUsers()
    let kudos = try value.reactions().map({ try $0.kudo() })
    let kudoJSONs = try kudos.map({ try convertKudoToJSON($0, users: users) })
    
    return JSON([
        "meta": ["static": false],
        "data": [
            "name": value.name.makeNode(),
            "slug": value.slug.makeNode(),
            "emoji_character": value.emojiCharacter.makeNode(),
            "emoji_alpha_code": value.emojiAlphaCode.makeNode(),
            "kudos": try kudoJSONs.makeNode(),
        ],
    ])
}

drop.get("progress") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            [
                "year": 2017,
                "week": 3,
                "value_points": [
                    "overall": 882,
                    "brilliant": 342,
                    "kind": 227,
                    "hardworking": 313,
                ],
                ],
            [
                "year": 2017,
                "week": 2,
                "value_points": [
                    "overall": 682,
                    "brilliant": 342,
                    "kind": 227,
                    "hardworking": 113,
                ],
            ],
            [
                "year": 2017,
                "week": 1,
                "value_points": [
                    "overall": 782,
                    "brilliant": 442,
                    "kind": 227,
                    "hardworking": 113,
                ],
            ],
        ]
    ])
}

drop.post("/kudos") { req in
    guard let json = req.json else { throw Abort.badRequest }
    var kudo = try Kudo(node: json)
    try kudo.save()
    return kudo
}

drop.post("/reactions") { req in
    guard let json = req.json else { throw Abort.badRequest }
    var reaction = try Reaction(node: json)
    try reaction.save()
    return reaction
}


drop.run()
