import HTTP
import Transport
import Vapor

let config = try Config(prioritized: [.directory(root: workingDirectory + "Config/secrets"),
                                      .directory(root: workingDirectory + "Config/")])
guard let token = config["bot", "token"]?.string else { throw BotError.missingConfig }

let bot = Bot(token: token)
try bot.run()
