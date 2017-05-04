import HTTP
import Fluent
import Models
import Transport
import Vapor
import VaporPostgreSQL

let config = try Config(prioritized: [.directory(root: workingDirectory + "Config/secrets"),
                                      .directory(root: workingDirectory + "Config/")])
guard let token = config["bot", "token"]?.string else { throw BotError.missingConfig }

let dbProvider = try VaporPostgreSQL.Provider(config: config)
let db = Database(dbProvider.driver)
Kudo.database = db

let bot = Bot(token: token)
try bot.run()
