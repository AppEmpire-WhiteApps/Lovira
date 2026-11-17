// Generated authenticated fallback decoder. Regenerate from a clean clone.
import CryptoKit
import Foundation

internal enum PremiumKitFallbackDecoder31536c10dc83d59e {
    private static let headerBytes = 16
    private static let positions: [Int] = [24, 27, 21, 14, 9, 18, 29, 7, 15, 5, 1, 2, 13, 31, 16, 4, 30, 3, 25, 28, 0, 6, 26, 17, 20, 19, 23, 22, 8, 12, 11, 10]
    private static let orders: [[Int]] = [[29, 22, 18, 6, 26, 2, 4, 19, 23, 12, 30, 25, 27, 3, 8, 24, 11, 21, 20, 16, 28, 31, 9, 14, 5, 1, 15, 17, 0, 10, 13, 7], [23, 20, 3, 18, 14, 30, 17, 10, 5, 29, 15, 21, 27, 0, 8, 25, 19, 26, 22, 11, 4, 7, 31, 9, 28, 1, 2, 6, 12, 13, 16, 24], [13, 4, 7, 5, 10, 2, 25, 6, 30, 20, 29, 0, 21, 9, 12, 15, 1, 14, 17, 8, 28, 11, 19, 31, 18, 3, 27, 26, 22, 16, 24, 23], [27, 11, 0, 12, 19, 28, 6, 20, 23, 26, 31, 5, 30, 15, 18, 25, 10, 7, 9, 8, 2, 3, 29, 22, 21, 4, 24, 1, 13, 16, 17, 14], [11, 31, 14, 3, 1, 8, 2, 15, 12, 27, 9, 20, 7, 29, 26, 17, 4, 24, 21, 18, 25, 30, 13, 10, 28, 22, 6, 0, 19, 23, 16, 5], [28, 14, 17, 2, 24, 26, 19, 10, 31, 6, 27, 9, 25, 7, 13, 11, 0, 30, 20, 5, 22, 16, 3, 18, 23, 8, 21, 1, 15, 4, 29, 12], [8, 16, 15, 30, 26, 6, 19, 24, 3, 13, 5, 0, 17, 1, 12, 18, 22, 25, 21, 10, 9, 11, 23, 28, 4, 7, 31, 20, 29, 2, 27, 14], [24, 31, 3, 8, 18, 15, 25, 12, 16, 26, 22, 6, 28, 27, 29, 17, 19, 23, 4, 14, 13, 11, 9, 30, 21, 2, 20, 7, 10, 0, 5, 1]]

    static func decrypt(_ encryptedData: Data) -> Data? {
        guard encryptedData.count > headerBytes else { return nil }
        let payload = encryptedData.subdata(in: headerBytes..<encryptedData.count)
        let fragments: [[UInt8]] = [Segmentf6d69df2854da3fe.nibbles, Segment91fb117c02c10344.nibbles, Segmentbc20265d200de03c.nibbles, Segmentdcb8d4985b5c9f1f.nibbles, Segmentd6a63dbb521739f9.nibbles, Segmentcfc632e063ccd424.nibbles, Segmente4669a25c9305371.nibbles, Segment9a05583e8bfc9441.nibbles]
        guard fragments.count == orders.count,
              fragments.allSatisfy({ $0.count == positions.count }) else { return nil }
        var permuted = [UInt8](repeating: 0, count: positions.count)
        for pair in stride(from: 0, to: fragments.count, by: 2) {
            var share = [UInt8](repeating: 0, count: positions.count)
            for slot in 0..<positions.count {
                share[orders[pair][slot]] = fragments[pair][slot] << 4
            }
            for slot in 0..<positions.count {
                share[orders[pair + 1][slot]] |= fragments[pair + 1][slot]
            }
            for index in share.indices {
                permuted[index] ^= share[index]
            }
        }
        var keyBytes = [UInt8](repeating: 0, count: positions.count)
        for (position, originalIndex) in positions.enumerated() {
            guard keyBytes.indices.contains(originalIndex) else { return nil }
            keyBytes[originalIndex] = permuted[position]
        }
        let key = SymmetricKey(data: Data(keyBytes))
        guard let sealedBox = try? AES.GCM.SealedBox(combined: payload) else { return nil }
        return try? AES.GCM.open(sealedBox, using: key)
    }
}
