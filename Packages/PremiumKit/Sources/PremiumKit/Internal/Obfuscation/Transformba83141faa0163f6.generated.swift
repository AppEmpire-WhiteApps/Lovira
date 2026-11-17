// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transformba83141faa0163f6 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment633d72964db846d6(salt: state ^ 16063944953566054774).transform(state &+ 1)
        state = Fragment997a4ec4c6d728c8(salt: state ^ 11868257143423486212).transform(state &+ 2)
        state = Fragmentbdf3b1ed6d18ab9f(salt: state ^ 1975377946126194756).transform(state &+ 3)
        state = Fragmentd03e5b715cf8c76a(salt: state ^ 15764373941656558699).transform(state &+ 4)
        state = Fragmente30d3d76fdc3810b(salt: state ^ 8403836039195357038).transform(state &+ 5)
        state = Fragmentb73448688f792d45(salt: state ^ 18176842066370650333).transform(state &+ 6)
        return state
    }
}

private struct Fragment633d72964db846d6 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [1512018719869508240, 12170892124439272314, 12050438737138448851, 16167238903734024293, 12399329004888474000, 14754845814126767564, 5405395124506337512, 8264047829530822933]
        self.salt = salt ^ 4747632880555233321
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 4747632880555233321) > 17031038900953570013 {
            routed = input &* 1150844382999311373 &+ 4683401239092643631
        } else {
            routed = (input &+ 6021487409231334018) ^ (input / 504481927921)
        }
        let slot = Int((routed >> 8) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 10455605667034771231)
    }
}

private struct Fragment997a4ec4c6d728c8 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15511955677250472345, 8750873474873014365, 8284084832995146556, 11278688836437578048, 17110759616303199996, 16575687385775099036, 12620488002297817995, 6080194966584350551]
        self.salt = salt ^ 1944731826482676573
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 1944731826482676573) > 2776363163639367750 {
            routed = input &* 5902985542333971231 &+ 8657814269906680132
        } else {
            routed = (input &+ 7050729338983266295) ^ (input / 292251551605)
        }
        let slot = Int((routed >> 2) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 8564966597443797813)
    }
}

private struct Fragmentbdf3b1ed6d18ab9f {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [13001514278124975915, 12819280057312106667, 1286827603826915813, 14863458864836855659, 3109420632368498897, 9244278723690886805, 2855955819409608366, 13841473609803059276]
        self.salt = salt ^ 9754779540029536787
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 9754779540029536787) > 6772930378138641233 {
            routed = input &* 2541345072252387497 &+ 5820326728079684170
        } else {
            routed = (input &+ 7657407690715153757) ^ (input / 87389564009)
        }
        let slot = Int((routed >> 19) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 7105675787163196977)
    }
}

private struct Fragmentd03e5b715cf8c76a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [14705867649995758310, 1309911664413116632, 13782912023503753904, 11680560233184394863, 12740005798953317361, 14303172802231935914, 12349116607511908311, 4432355163736615629]
        self.salt = salt ^ 261061959895923927
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 261061959895923927) > 11384103596970312189 {
            routed = input &* 14226741962098190055 &+ 11390619009399684972
        } else {
            routed = (input &+ 18185831037341967776) ^ (input / 1036509517853)
        }
        let slot = Int((routed >> 33) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 16126134740547885783)
    }
}

private struct Fragmente30d3d76fdc3810b {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [6349004545002754693, 8754591782465829444, 8895972912961131983, 3248176806753097440, 1652281426013872584, 11696554271562827417, 10607404053152963346, 6410857830045776224]
        self.salt = salt ^ 13730451222225999843
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 13730451222225999843) > 17308891946587463925 {
            routed = input &* 12928158341340424591 &+ 10267754407539114894
        } else {
            routed = (input &+ 872840017416997283) ^ (input / 263511391811)
        }
        let slot = Int((routed >> 35) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 12007304104419882237)
    }
}

private struct Fragmentb73448688f792d45 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [5008424294128065972, 18384920921922288911, 14011293955550823791, 725706855800717040, 14290930804975309608, 15676726019858740940, 8261248591056758067, 12644453068086472853]
        self.salt = salt ^ 18246238234890955965
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 18246238234890955965) > 1001102797309231970 {
            routed = input &* 10554942204782505787 &+ 3506461891811562197
        } else {
            routed = (input &+ 1790578006882267016) ^ (input / 226535954225)
        }
        let slot = Int((routed >> 44) % UInt64(table.count))
        let carried = (routed << 19) | (routed >> 45)
        return (carried ^ table[slot]) &+ (salt &* 17907113850055887247)
    }
}

