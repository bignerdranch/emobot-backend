web: App --env=production --workdir="./"
web: App --env=production --workdir=./ --config:servers.default.port=$PORT --config:postgresql.url=$DATABASE_URL --config:slack.token=$SLACK_TOKEN
bot: Bot --env=development --workdir="./"
bot: Bot --env=development --workdir=./ --config:postgresql.url=$DATABASE_URL --config:slack.token=$SLACK_TOKEN
