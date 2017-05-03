import Vapor

let drop = Droplet()

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.get("/kudos") { req in
    return JSON([
        "meta": ["static": true],
        "data": [
            "from": "jjustice",
            "to": "caitlin",
            "description": "for client wrangling",
            "channel": "caption-call-internal",
            "date": "2015-03-25T12:00:00Z",
            "value-points": [
                "brilliant": 3,
                "kind": 1,
                "hardworking": 0,
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
                "value-points": [
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
                "value-points": [
                    "brilliant": 3,
                    "kind": 1,
                    "hardworking": 0,
                ]
            ]
        ]
        ])
}

drop.run()
