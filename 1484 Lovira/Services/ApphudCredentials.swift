import Foundation

enum ApphudCredentials {
    private static let encoded: [UInt8] = [
        198, 215, 215, 248, 150, 223, 254, 158, 211, 254, 229, 212, 196, 235, 202, 240, 240, 201, 159, 159, 146, 237,
        235, 224, 230, 227, 247, 234, 197, 204, 243, 147, 149, 243,
    ]

    static var apiKey: String {
        String(decoding: encoded.map { $0 ^ 167 }, as: UTF8.self)
    }
}
