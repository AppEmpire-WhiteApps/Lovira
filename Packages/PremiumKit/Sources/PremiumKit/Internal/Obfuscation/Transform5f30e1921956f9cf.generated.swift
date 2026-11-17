// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transform5f30e1921956f9cf {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragmente17e90a0c0f304bb(salt: state ^ 10025355037210818221).transform(state &+ 1)
        state = Fragmentf209450df1fc4353(salt: state ^ 3028189201109127544).transform(state &+ 2)
        state = Fragment6a3d1c0955e8adf9(salt: state ^ 13661106028730403597).transform(state &+ 3)
        state = Fragmente25096525a96df84(salt: state ^ 3261711055173498406).transform(state &+ 4)
        state = Fragment97d6414d9a5e606f(salt: state ^ 1930697141423466040).transform(state &+ 5)
        state = Fragment2ab91a36c7282058(salt: state ^ 10036065126217529355).transform(state &+ 6)
        return state
    }
}

private struct Fragmente17e90a0c0f304bb {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [11281603438823565877, 11021921362789727931, 14269369926711508230, 1803421064435284191, 8729850234798040056, 7196094308154542747, 5431722829946386580, 5504751436279966916]
        self.salt = salt ^ 2205943784133845227
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2205943784133845227) > 12180986957629802653 {
            routed = input &* 5402530029084176761 &+ 7707839448013454245
        } else {
            routed = (input &+ 8636840627897015872) ^ (input / 539533013167)
        }
        let slot = Int((routed >> 22) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 2501661008065648705)
    }
}

private struct Fragmentf209450df1fc4353 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [4892882494451372910, 14995277014858122154, 12721047294413111916, 14265994189248984855, 7934779595383842079, 3164930820031154135, 15425013410404095260, 8493851175028053035]
        self.salt = salt ^ 14158528797743033063
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 14158528797743033063) > 8234095363464175982 {
            routed = input &* 9927499406398056591 &+ 283370013624469663
        } else {
            routed = (input &+ 10724451495009249424) ^ (input / 1055142964347)
        }
        let slot = Int((routed >> 17) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 14058978471525924987)
    }
}

private struct Fragment6a3d1c0955e8adf9 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [186973422099501930, 17534656889485230651, 12443043181679058282, 12860985985476886553, 15324323513326783093, 15382466981485536541, 7695683439859728531, 17870228450469914286]
        self.salt = salt ^ 2043534696915185581
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2043534696915185581) > 8211194035768579787 {
            routed = input &* 3577141988561615851 &+ 18008457550661806565
        } else {
            routed = (input &+ 18012256384639981576) ^ (input / 88811422559)
        }
        let slot = Int((routed >> 11) % UInt64(table.count))
        let carried = (routed << 7) | (routed >> 57)
        return (carried ^ table[slot]) &+ (salt &* 8527844616987139813)
    }
}

private struct Fragmente25096525a96df84 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15991970058822512046, 14386008690127541305, 13540917365104248200, 792064477983510647, 16833135812796770871, 15685323641654857146, 12707494326018701467, 1719300108363387]
        self.salt = salt ^ 1602734512271486697
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 1602734512271486697) > 2205278643677548927 {
            routed = input &* 13044932260024986825 &+ 17458534338684365615
        } else {
            routed = (input &+ 995673658491820243) ^ (input / 925087692629)
        }
        let slot = Int((routed >> 3) % UInt64(table.count))
        let carried = (routed << 7) | (routed >> 57)
        return (carried ^ table[slot]) &+ (salt &* 7495595511158316427)
    }
}

private struct Fragment97d6414d9a5e606f {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [6963571235008557358, 5788930622237712546, 17980537510862558075, 7217013626109760796, 3256220368476799658, 1158459009891646186, 11615834879857448042, 13859846087826579611]
        self.salt = salt ^ 3259615964547485751
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 3259615964547485751) > 5118637734591020472 {
            routed = input &* 1330836187244722291 &+ 16511167536331063318
        } else {
            routed = (input &+ 7369593813154858672) ^ (input / 647609397945)
        }
        let slot = Int((routed >> 53) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 6570941502848416273)
    }
}

private struct Fragment2ab91a36c7282058 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15680721362034185174, 979722466222654086, 13832163631533969880, 11829302752163109750, 14379702683907281614, 3666132528289895777, 8250689441868817539, 10387383433949539444]
        self.salt = salt ^ 14385023306287268257
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 14385023306287268257) > 5862260361841532546 {
            routed = input &* 432043490280605671 &+ 3077593926872639991
        } else {
            routed = (input &+ 13232046411801225110) ^ (input / 252092883317)
        }
        let slot = Int((routed >> 16) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 6776691332293952427)
    }
}

