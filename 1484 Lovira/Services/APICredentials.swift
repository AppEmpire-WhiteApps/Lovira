import CryptoKit
import Foundation

/// LLMApps TOTP key, stored XOR-obfuscated so it never appears as plain text in the binary.
enum APICredentials {
    static let baseURL = URL(string: "https://llmapps.space")!

    static var totpKey: String {
        let bytes = zip(payload, mask).map { $0 ^ $1 }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static let payload: [UInt8] = [
        0x48, 0xF4, 0xC6, 0x7A, 0x72, 0xBC, 0x2B, 0xC4, 0x91, 0x42, 0x5E, 0x69,
        0x53, 0x94, 0xF6, 0x32, 0x70, 0xFD, 0x2E, 0xC8, 0xBE, 0x2E, 0xA0, 0x53,
        0x46, 0x0D, 0x32, 0x81, 0x62, 0xB9, 0xA8, 0xAA, 0x71, 0x87, 0x9C, 0x85,
        0x43, 0x14, 0x8C, 0x60, 0x5C, 0x24, 0xFF, 0x08, 0xC1, 0x6C, 0xBF, 0xD0,
        0xA2, 0xBD, 0xA5, 0xF6, 0xFC, 0xC5, 0xB7, 0xD0, 0x24, 0x68, 0x7C, 0x0A,
        0x7E, 0x9F, 0x81, 0x3A
    ]

    private static let mask: [UInt8] = [
        0x24, 0x98, 0xAB, 0x25, 0x06, 0xD3, 0x5F, 0xB4, 0xCE, 0x31, 0x0D, 0x19,
        0x6A, 0xC0, 0xB9, 0x03, 0x20, 0xA7, 0x1D, 0xA7, 0xE1, 0x4D, 0xD2, 0x19,
        0x0D, 0x3B, 0x53, 0xF2, 0x53, 0x94, 0xE2, 0x9C, 0x41, 0xB0, 0xE6, 0xD7,
        0x14, 0x58, 0xDB, 0x29, 0x2A, 0x6E, 0x87, 0x7B, 0xB8, 0x08, 0xF6, 0xA2,
        0xC3, 0xD9, 0xC9, 0xAE, 0x9E, 0x94, 0xCF, 0xAA, 0x72, 0x37, 0x1B, 0x53,
        0x14, 0xCD, 0xEE, 0x6F
    ]
}

enum TOTPTokenGenerator {
    /// Builds `llm_totp_{prefix}_{code}` where code = base64url(HMAC-SHA256(secret, minutes since epoch)).
    static func token(date: Date = .now) -> String {
        let key = APICredentials.totpKey
        let prefix = String(key.prefix(20))
        let secret = String(key.dropFirst(21))
        let minutes = UInt64(date.timeIntervalSince1970 / 60)
        let counter = withUnsafeBytes(of: minutes.bigEndian) { Data($0) }
        let secretData = Data(base64URLEncoded: secret) ?? Data()
        let code = HMAC<SHA256>.authenticationCode(for: counter, using: SymmetricKey(data: secretData))
        return "\(prefix)_\(Data(code).base64URLEncodedString())"
    }
}

extension Data {
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }
        self.init(base64Encoded: base64)
    }

    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
