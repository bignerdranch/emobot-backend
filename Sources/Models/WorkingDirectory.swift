/*
 Helps solve issue of working directories in Xcode
 */

#if os(Linux)
public let workingDirectory = "./"
#else
public let workingDirectory: String = {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../" // needs to be directly under App
    return path
}()
#endif


