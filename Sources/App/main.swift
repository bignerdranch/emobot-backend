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
                    "points": 142,
                ],
                [
                    "rank": 2,
                    "user": "kristin",
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
            "hardworking": [
                [
                    "rank": 1,
                    "user": [
                        "user_name": "jjustice",
                        "avatar": "https://cdn.example.com/jjustice_192.jpg",
                    ],
                    "points": 142,
                ],
                [
                    "rank": 2,
                    "user": [
                        "name": "caitlin",
                        "avatar": "https://cdn.example.com/caitlin_192.jpg",
                    ],
                    "points": 127,
                ],
                [
                    "rank": 3,
                    "user": [
                        "user_name": "kristin",
                        "avatar": "https://cdn.example.com/kristin_192.jpg",
                    ],
                    "points": 113,
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

drop.get("values", String.self) { req, value in
    return JSON([
        "meta": ["static": false],
        "data": [
            "name": "Kind",
            "emoji_character": "❤️",
            "emoji_alpha_code": "heart",
            "kudos": [
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
