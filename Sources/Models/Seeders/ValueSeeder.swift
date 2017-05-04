public class ValueSeeder {
    
    public static func seed() throws {
        guard try Value.all().count == 0 else {
            print("Values already exist in database - not seeding")
            return
        }
        
        var brilliant = Value(name: "Brilliant", emojiCharacter: "🎓", emojiAlphaCode: "mortar_board")
        try brilliant.save()
        
        var kind = Value(name: "Kind", emojiCharacter: "❤️", emojiAlphaCode: "heart")
        try kind.save()
        
        var hardworking = Value(name: "Hardworking", emojiCharacter: "💪", emojiAlphaCode: "muscle")
        try hardworking.save()
    }
    
}
