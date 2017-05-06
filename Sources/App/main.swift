import Foundation
import Models
import Vapor
import VaporPostgreSQL

let drop = Droplet()
drop.preparations.append(Value.self)
drop.preparations.append(Emoji.self)
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

var userAvatarCache: [String: String] = [:]

func userAvatar(for userName: String, users: JSON?) -> String {
    if let avatar = userAvatarCache[userName] {
        return avatar
    }
    
    if let users = users {
        let memberArray = users["members"]?.array!
        for member in memberArray! {
            if let name = member.object?["name"]?.string, name == userName {
                if let avatar = member.object?["profile"]?.object?["image_512"]?.string {
                    userAvatarCache[userName] = avatar
                    return avatar
                }
            }
        }
    }

    return ""
}

func convertKudoToJSON(_ kudo: Kudo, users: JSON?) throws -> JSON {
    let fromAvatar = userAvatar(for: kudo.fromUser, users: users)
    let toAvatar = userAvatar(for: kudo.toUser, users: users)
    
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
        "value_points": kudo.reactionCountsByValue().makeNode(),
    ])
}


drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

func formatLeaderboardResults(_ results: Node, users: JSON) throws -> [JSON] {
    let resultsArray: [Polymorphic] = results.array!
    
    var formattedResults: [JSON] = []
    for (i, row) in resultsArray.enumerated() {
        let rowObject = row.object!
        
        let userName = rowObject["to_user"]!.string!
        let avatar = userAvatar(for: userName, users: users)
        
        let result = try JSON(node: [
            "rank": i + 1,
            "user": try JSON(node: [
                "user_name": userName,
                "avatar": avatar,
                ]),
            "points": rowObject["points"]!.int!,
            ])
        formattedResults.append(result)
    }
    return formattedResults
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
    
    let totalsResults = try pg.raw("SELECT 'overall' AS value, COUNT(*) AS points FROM reactions AS points UNION SELECT v.slug AS value, COUNT(*) AS points FROM kudos k JOIN reactions r ON k.id = r.kudo_id JOIN values v ON r.value_id = v.id GROUP BY v.slug")
    var totals: [String: Int] = [:]
    for row in totalsResults.array! {
        if let valueSlug = row.object?["value"]?.string,
            let points = row.object?["points"]?.int
        {
            totals[valueSlug] = points
        }
    }
    
    return JSON([
        "meta": ["static": false],
        "data": [
            "totals": try totals.makeNode(),
            "kudos": try allResults.makeNode(),
        ]
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
    let kudos = try value.kudos()
    let kudoJSONs = try kudos.map({ try convertKudoToJSON($0, users: users) })
    
    let emojiJSONs = try value.emoji().map({ emoji -> JSON in
        return try JSON(node: [
            "character": emoji.character,
            "alpha_code": emoji.alphaCode,
        ])
    })
    
    return JSON([
        "meta": ["static": false],
        "data": [
            "name": value.name.makeNode(),
            "slug": value.slug.makeNode(),
            "emoji": try emojiJSONs.makeNode(),
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
