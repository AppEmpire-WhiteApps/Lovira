// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transform0498e4fe170902e2 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragmentf334f754ad5e1914(salt: state ^ 2379911207873566400).transform(state &+ 1)
        state = Fragmentb6f795df58efb810(salt: state ^ 4219155089499469825).transform(state &+ 2)
        state = Fragmente1d4f9bb894083df(salt: state ^ 17028554311610921825).transform(state &+ 3)
        state = Fragment490cd1dcfd93e555(salt: state ^ 15226939549720691831).transform(state &+ 4)
        state = Fragmentf63b600993a23efc(salt: state ^ 8173222550512209988).transform(state &+ 5)
        state = Fragment0f632a0cf96fcb82(salt: state ^ 1499073422088557222).transform(state &+ 6)
        return state
    }
}

private struct Fragmentf334f754ad5e1914 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [5428535361425564305, 198338903908018987, 2771690749599159853, 15090843959047182813, 7537825229587779456, 11910152044936038965, 4478697831762840519, 11950563302495052382]
        self.salt = salt ^ 2580513399351609279
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2580513399351609279) > 12859149119837872782 {
            routed = input &* 13640251737790780039 &+ 13117358991940871201
        } else {
            routed = (input &+ 10702609498383588108) ^ (input / 124289926097)
        }
        let slot = Int((routed >> 28) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 1997848158729805743)
    }
}

private struct Fragmentb6f795df58efb810 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [12197722865688712087, 95854903902087061, 5213591932983055420, 16616706490573535768, 5881783453548543515, 3976191476535870001, 3243674240021312616, 1406999622764832814]
        self.salt = salt ^ 2897960911825759243
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2897960911825759243) > 3181885150565296768 {
            routed = input &* 14792567019656877547 &+ 14776476437614414138
        } else {
            routed = (input &+ 5007863191868814821) ^ (input / 1077457461165)
        }
        let slot = Int((routed >> 7) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 17437417866345201213)
    }
}

private struct Fragmente1d4f9bb894083df {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [4938601967179250776, 8682998286448992982, 18414512705322100235, 15026679688282491533, 7077765966316404558, 5012323741325893995, 16955057563330791566, 15907998397297255136]
        self.salt = salt ^ 11425262598488637345
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 11425262598488637345) > 1619049484061993548 {
            routed = input &* 875487402543233709 &+ 13390973160782039179
        } else {
            routed = (input &+ 9099323946839674429) ^ (input / 887783551945)
        }
        let slot = Int((routed >> 39) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 6248640663802381701)
    }
}

private struct Fragment490cd1dcfd93e555 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [11748384382881634466, 13953907386621657819, 9783617967372577627, 2303098573304188284, 15781216923290179059, 11965161155086118947, 4050446225434881215, 11735931356474822515]
        self.salt = salt ^ 6183979100080662427
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 6183979100080662427) > 15172222540870959406 {
            routed = input &* 11233405054344088385 &+ 12912640315831103551
        } else {
            routed = (input &+ 7137261772910674786) ^ (input / 840570099241)
        }
        let slot = Int((routed >> 32) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 16438164185226708689)
    }
}

private struct Fragmentf63b600993a23efc {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [18335531645671493048, 10871509031858597988, 849401561352324037, 1913598506771846187, 12439237960538449373, 7720920082908503927, 5468912647053143282, 8663470137992399927]
        self.salt = salt ^ 2178707414804995251
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2178707414804995251) > 17709905232968687637 {
            routed = input &* 14588102261105215471 &+ 2338917749483843168
        } else {
            routed = (input &+ 15428962701876789380) ^ (input / 348447265561)
        }
        let slot = Int((routed >> 40) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 13538324480215052591)
    }
}

private struct Fragment0f632a0cf96fcb82 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [5371050977498743285, 16693163392839660952, 16615397888759166985, 5204247321609993138, 8713688689172779533, 14926055240669082725, 16069290901621917940, 17004497428070971308]
        self.salt = salt ^ 4329465815096381975
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 4329465815096381975) > 9120064058502102555 {
            routed = input &* 14826068683412029907 &+ 10942059719799774670
        } else {
            routed = (input &+ 7574298945727468663) ^ (input / 883495018249)
        }
        let slot = Int((routed >> 3) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 1996236168653257981)
    }
}

