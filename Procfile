web: Api --env=production --workdir="./"
web: Api --env=production --workdir=./ --config:servers.default.port=$PORT --config:postgresql.url=$DATABASE_URL
bot: Bot --env=production --workdir="./"
bot: Bot --env=production --workdir=./ --config:postgresql.url=$DATABASE_URL --config:bot.token=$SLACK_TOKEN
