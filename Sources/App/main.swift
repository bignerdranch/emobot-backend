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
    return JSON([
        "meta": ["static": true],
        "data": [
            "kudos": [
                "sent": [
                    [
                        "from": [
                            "user_name": "caitlin",
                            "avatar": "https://cdn.example.com/caitlin_192.jpg",
                        ],
                        "to": [
                            "user_name": "kristin",
                            "avatar": "https://cdn.example.com/kristin_192.jpg",
                        ],
                        "channel": "caption-call-internal",
                        "description": "great client call",
                        "value_points": [
                            "brilliant": 3,
                            "kind": 1,
                            "hardworking": 0,
                        ]
                    ],
                    [
                        "from": [
                            "user_name": "caitlin",
                            "avatar": "https://cdn.example.com/caitlin_192.jpg",
                        ],
                        "to": [
                            "user_name": "jjustice",
                            "avatar": "https://cdn.example.com/jjustice_192.jpg",
                        ],
                        "channel": "caption-call-internal",
                        "description": "great client call",
                        "value_points": [
                            "brilliant": 3,
                            "kind": 1,
                            "hardworking": 0,
                        ]
                    ],
                ],
                "received": [
                    [
                        "from": [
                            "user_name": "kristin",
                            "avatar": "https://cdn.example.com/kristin_192.jpg",
                        ],
                        "to": [
                            "user_name": "caitlin",
                            "avatar": "https://cdn.example.com/caitlin_192.jpg",
                        ],
                        "channel": "caption-call-internal",
                        "description": "great client call",
                        "value_points": [
                            "brilliant": 3,
                            "kind": 1,
                            "hardworking": 0,
                        ]
                    ],
                    [
                        "from": [
                            "user_name": "jjustice",
                            "avatar": "https://cdn.example.com/jjustice_192.jpg",
                        ],
                        "to": [
                            "user_name": "caitlin",
                            "avatar": "https://cdn.example.com/caitlin_192.jpg",
                        ],
                        "channel": "caption-call-internal",
                        "description": "great client call",
                        "value_points": [
                            "brilliant": 3,
                            "kind": 1,
                            "hardworking": 0,
                        ]
                    ],
                ],
            ],
        ],
    ])
}

drop.get("values", String.self) { req, valueSlug in
    // TODO: create a slug field
    // TODO: dynamic profile image field
    guard let value = try Value.query().filter("slug", valueSlug).first() else {
        return "KUDO NOT FOUND"
    }
    
    let kudos = try value.reactions().map({ try $0.kudo() })
    let kudoJSONs = try kudos.map({ (kudo: Kudo) -> JSON in
        
        var reactionCountsByValueSlug: [String: Int] = [:]
        for (value, count) in try kudo.reactionCountsByValue() {
            reactionCountsByValueSlug[value.slug] = count
        }
        
        return try JSON(node: [
            "from": [
                "user_name": kudo.fromUser.makeNode(),
                "avatar": "https://cdn.example.com/example_192.jpg",
            ],
            "to": [
                "user_name": kudo.toUser.makeNode(),
                "avatar": "https://cdn.example.com/example_192.jpg",
            ],
            "channel": kudo.channel.makeNode(),
            "description": kudo.description.makeNode(),
            "value_points": reactionCountsByValueSlug.makeNode(),
        ])
    })
    
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

drop.get("/kudos") { req in
    return JSON([
        "meta": ["static": false],
        "data": try Kudo.all().makeNode(),
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

drop.get("/kudos/stats/from") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            [
                "from": "jjustice",
                "value_points": [
                    "brilliant": 3,
                    "kind": 1,
                    "hardworking": 0,
                ]
            ]
        ]
    ])
}

drop.get("/kudos/stats/to") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            [
                "to": "jjustice",
                "value_points": [
                    "brilliant": 3,
                    "kind": 1,
                    "hardworking": 0,
                ]
            ]
        ]
        ])
}

drop.get("/kudos/stats/value") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            [
                "value": "brilliance",
                "points": 3,
            ]
        ]
        ])
}

drop.run()
