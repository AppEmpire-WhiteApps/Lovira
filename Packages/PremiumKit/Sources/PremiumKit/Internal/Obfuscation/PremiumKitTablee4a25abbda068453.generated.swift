// Generated placement table. Regenerate from a clean clone; do not edit.
internal enum PremiumKitTablee4a25abbda068453 {
    private static let stream: [UInt8] = [42, 4, 94, 190, 161, 240, 212, 183, 93, 181, 207, 57, 34, 131, 39]
    private static let rows: [[UInt8]] = [[69, 106, 60, 209, 192, 130, 176, 222, 51, 210], [71, 101, 55, 208], [73, 107, 48, 205, 212, 157, 181, 213, 49, 208], [72, 101, 48, 208, 196, 130]]

    @inline(never)
    static func placement(_ index: Int) -> String {
        guard rows.indices.contains(index) else { return "" }
        let row = rows[index]
        let bytes = row.enumerated().map { offset, value in
            value ^ stream[offset % stream.count]
        }
        return String(decoding: bytes, as: UTF8.self)
    }
}
