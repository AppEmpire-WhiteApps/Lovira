// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transform4887abda346812f1 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragmentb0f382cdca716363(salt: state ^ 5137305251530926560).transform(state &+ 1)
        state = Fragmentd7d670504725f33d(salt: state ^ 13068104480439104155).transform(state &+ 2)
        state = Fragment131451d03f7b752f(salt: state ^ 6005185790873195161).transform(state &+ 3)
        state = Fragmentde04431e52294b7f(salt: state ^ 2358747014757292702).transform(state &+ 4)
        state = Fragment800f1a153d3bc10f(salt: state ^ 18019667110095895582).transform(state &+ 5)
        state = Fragmente673b23778db4e2a(salt: state ^ 7635133336486969023).transform(state &+ 6)
        return state
    }
}

private struct Fragmentb0f382cdca716363 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15988256150895410505, 15069637087330434329, 12222123666211866324, 17709323999582182574, 41861369339696010, 17478243547444567575, 1264785261248995466, 15230396353909654507]
        self.salt = salt ^ 17129568432360379253
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 17129568432360379253) > 1264457695886092910 {
            routed = input &* 1151037824868585059 &+ 9025143070891998884
        } else {
            routed = (input &+ 11988285363014283215) ^ (input / 677444229675)
        }
        let slot = Int((routed >> 11) % UInt64(table.count))
        let carried = (routed << 7) | (routed >> 57)
        return (carried ^ table[slot]) &+ (salt &* 12405679952488205371)
    }
}

private struct Fragmentd7d670504725f33d {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8570293673213771739, 16257628185593917816, 11130426884066572053, 11222496774890476091, 1261187990257677777, 8690422284093073480, 15689539169292375304, 10547229554923604134]
        self.salt = salt ^ 9901642843338953537
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 9901642843338953537) > 4171725279527275208 {
            routed = input &* 7935694190171523607 &+ 10241156662566198390
        } else {
            routed = (input &+ 4672757633912099098) ^ (input / 163503912011)
        }
        let slot = Int((routed >> 5) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 7621862953731191167)
    }
}

private struct Fragment131451d03f7b752f {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [17625557479764872847, 9487650104960057304, 5011776367512911817, 11626713078854485482, 9954315065897341629, 16906113534640266534, 2654276926987567750, 6249025799518150604]
        self.salt = salt ^ 2017364657411672137
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2017364657411672137) > 14246798023594516796 {
            routed = input &* 18153315179204156117 &+ 14029113309937372781
        } else {
            routed = (input &+ 2677753057339662473) ^ (input / 1020005786731)
        }
        let slot = Int((routed >> 21) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 9278718808361543765)
    }
}

private struct Fragmentde04431e52294b7f {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [7800233469811740240, 7687583177311595143, 517986684899063200, 11276090553833604443, 6829233343581311911, 18402057580623389183, 17974325811262705996, 1070775803087031251]
        self.salt = salt ^ 8305195893027585457
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 8305195893027585457) > 449064617002037687 {
            routed = input &* 4548064078321573279 &+ 14703783327753209947
        } else {
            routed = (input &+ 13430908679640396662) ^ (input / 290577377249)
        }
        let slot = Int((routed >> 23) % UInt64(table.count))
        let carried = (routed << 19) | (routed >> 45)
        return (carried ^ table[slot]) &+ (salt &* 888434096576979229)
    }
}

private struct Fragment800f1a153d3bc10f {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [7603079569522598249, 761150819418625665, 16495782562494437936, 14039896565038122406, 830922656758060383, 16107931271691223057, 8369386705756438022, 11744814988776807735]
        self.salt = salt ^ 4327974575444685913
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 4327974575444685913) > 17417055261927568844 {
            routed = input &* 14319752749752215581 &+ 4844322528195070137
        } else {
            routed = (input &+ 17175417249825861677) ^ (input / 182417817777)
        }
        let slot = Int((routed >> 5) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 12637554228707617519)
    }
}

private struct Fragmente673b23778db4e2a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [7395740308374187377, 13049424829625824100, 4649675343139170810, 7078772158018688718, 7438596092582231135, 1517707207070286699, 18342864786556874560, 15751837162844429476]
        self.salt = salt ^ 2540884784746282477
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2540884784746282477) > 14669293873836903812 {
            routed = input &* 12544028552236188291 &+ 2427872432696321845
        } else {
            routed = (input &+ 6655440416112934348) ^ (input / 127886170043)
        }
        let slot = Int((routed >> 27) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 10785791283050148145)
    }
}

