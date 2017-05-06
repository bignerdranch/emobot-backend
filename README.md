# Emobot Backend

Slack bot and API for Nerd Cred.

## Installation

- Install [Vapor Toolbox](https://vapor.github.io/documentation/getting-started/install-toolbox.html) and [Postgres](https://www.postgresql.org/download/).
- [Create a new bot user](https://my.slack.com/services/new/bot) in your Slack team account and write down the token.
- Add configuration files:

**config/secrets/postgresql.json**

```json
{
    "host": "127.0.0.1",
    "port": 5432,
    "user": "postgres",
    "password": "",
    "database": "your_database_name_here"
}
```

**config/secrets/slack.json**

```json
{
    "token": "YOUR_SLACK_TOKEN_HERE"
}
```

- Run `vapor xcode -y`
- Prepare the database by either:
    1. Running the `App` target (running the `Bot` target won't populate the database).
    2. Running `vapor build && vapor run prepare` from the command line
- If you like, populate your database with sample data using [emobot-seeder](https://github.com/stickybandits/emobot-seeder).

## Usage
- From within Xcode, select the `App` or `Bot` project and run.
- Invite your bot to one or more Slack channels.

## Notes

- If you're planning on deploying to Linux (and you are) be aware that the Swift Foundation APIs on Linux aren't currently identical to Mac. You may want to run in [Vagrant](https://www.vagrantup.com/) or [Docker](https://github.com/vapor-community/docker) to be able to test builds in Ubuntu locally.
