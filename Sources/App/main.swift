import Vapor

let drop = Droplet()

drop.middleware.insert(CORSMiddleware(), at: 0)

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.get("/kudos") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            [
                "from": "jjustice",
                "to": "caitlin",
                "description": "for client wrangling",
                "channel": "caption-call-internal",
                "date": "2015-03-25T12:00:00Z",
                "value_points": [
                    "brilliant": 3,
                    "kind": 1,
                    "hardworking": 0,
                ],
            ],
        ],
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
