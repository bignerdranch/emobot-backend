import Vapor
import VaporPostgreSQL

let drop = Droplet()
drop.preparations.append(Value.self)
drop.preparations.append(Kudo.self)

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)
} catch {
    preconditionFailure("Error adding provider: \(error)")
}

drop.middleware.insert(CORSMiddleware(), at: 0)

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
                    "user": "caitlin",
                    "points": 442,
                ],
                [
                    "rank": 2,
                    "user": "kristin",
                    "points": 327,
                    ],
                [
                    "rank": 3,
                    "user": "jjustice",
                    "points": 213,
                ],
            ],
            "brilliant": [
                [
                    "rank": 1,
                    "user": "kristin",
                    "points": 142,
                ],
                [
                    "rank": 2,
                    "user": "caitlin",
                    "points": 127,
                ],
                [
                    "rank": 3,
                    "user": "jjustice",
                    "points": 113,
                ],
            ],
            "kind": [
                [
                    "rank": 1,
                    "user": "caitlin",
                    "points": 142,
                ],
                [
                    "rank": 2,
                    "user": "kristin",
                    "points": 127,
                ],
                [
                    "rank": 3,
                    "user": "jjustice",
                    "points": 113,
                ],
            ],
            "hardworking": [
                [
                    "rank": 1,
                    "user": "jjustice",
                    "points": 142,
                ],
                [
                    "rank": 2,
                    "user": "caitlin",
                    "points": 127,
                ],
                [
                    "rank": 3,
                    "user": "kristin",
                    "points": 113,
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
