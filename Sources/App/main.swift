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
                if let avatar = member.object?["profile"]?.object?["image_original"]?.string {
                    fromAvatar = avatar
                }
            }
            if let name = member.object?["name"]?.string, name == kudo.toUser {
                if let avatar = member.object?["profile"]?.object?["image_original"]?.string {
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


drop.post("db/seed") { req in
    try ValueSeeder.seed()
    return "OK"
}

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.get("/leaderboard") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            "overall": [
                [
                    "rank": 1,
                    "user": [
                        "user_name": "caitlin",
                        "avatar": "https://cdn.example.com/caitlin_192.jpg",
                    ],
                    "points": 442,
                ],
                [
                    "rank": 2,
                    "user": [
                        "user_name": "kristin",
                        "avatar": "https://cdn.example.com/kristin_192.jpg",
                    ],
                    "points": 327,
                ],
                [
                    "rank": 3,
                    "user": [
                        "user_name": "jjustice",
                        "avatar": "https://cdn.example.com/jjustice_192.jpg",
                    ],
                    "points": 213,
                ],
            ],
            "brilliant": [
                [
                    "rank": 1,
                    "user": [
                        "user_name": "kristin",
                        "avatar": "https://cdn.example.com/kristin_192.jpg",
                    ],
                    "points": 142,
                ],
                [
                    "rank": 2,
                    "user": [
                        "user_name": "caitlin",
                        "avatar": "https://cdn.example.com/caitlin_192.jpg",
                    ],
                    "points": 127,
                ],
                [
                    "rank": 3,
                    "user": [
                        "user_name": "jjustice",
                        "avatar": "https://cdn.example.com/jjustice_192.jpg",
                    ],
                    "points": 113,
                ],
            ],
            "kind": [
                [
                    "rank": 1,
                    "user": [
                        "user_name": "caitlin",
                        "avatar": "https://cdn.example.com/caitlin_192.jpg",
                    ],
                    "points": 217,
                ],
                [
                    "rank": 2,
                    "user": [
                        "user_name": "kristin",
                        "avatar": "https://cdn.example.com/kristin_192.jpg",
                    ],
                    "points": 118,
                ],
                [
                    "rank": 3,
                    "user": [
                        "user_name": "jjustice",
                        "avatar": "https://cdn.example.com/jjustice_192.jpg",
                    ],
                    "points": 117,
                ],
            ],
            "hardworking": [
                [
                    "rank": 1,
                    "user": [
                        "user_name": "jjustice",
                        "avatar": "https://cdn.example.com/jjustice_192.jpg",
                    ],
                    "points": 101,
                ],
                [
                    "rank": 2,
                    "user": [
                        "name": "caitlin",
                        "avatar": "https://cdn.example.com/caitlin_192.jpg",
                    ],
                    "points": 97,
                ],
                [
                    "rank": 3,
                    "user": [
                        "user_name": "kristin",
                        "avatar": "https://cdn.example.com/kristin_192.jpg",
                    ],
                    "points": 88,
                ],
            ],
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
        "meta": ["static": true],
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
