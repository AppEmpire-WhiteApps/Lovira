// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transform80b3788e8e67f2b6 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment6703d3f7bf273063(salt: state ^ 8296225433334318549).transform(state &+ 1)
        state = Fragment50b84e923a0e7a47(salt: state ^ 10598742179783565088).transform(state &+ 2)
        state = Fragmentdea5dfd7a1306f13(salt: state ^ 4095000586301513326).transform(state &+ 3)
        state = Fragmentd44d785725796894(salt: state ^ 15313961382493767276).transform(state &+ 4)
        state = Fragment1ecae1d7280c0717(salt: state ^ 15979567586090118029).transform(state &+ 5)
        state = Fragment87074c04ee0f3395(salt: state ^ 12356890310568326042).transform(state &+ 6)
        return state
    }
}

private struct Fragment6703d3f7bf273063 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [14511866502815035406, 17750714730973311679, 16177046257533867193, 14884315878548216095, 12571616695335893305, 16589759334688530419, 15573139086744816939, 1287725086345282731]
        self.salt = salt ^ 10973255034308469893
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 10973255034308469893) > 9549938812718645249 {
            routed = input &* 601522383546554789 &+ 6496017276471688966
        } else {
            routed = (input &+ 1146296871908584101) ^ (input / 509591719349)
        }
        let slot = Int((routed >> 26) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 17295995216216478355)
    }
}

private struct Fragment50b84e923a0e7a47 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [17909241434811950059, 12967263438370080089, 15959765382188834120, 9638781877222187048, 2853914411328326111, 11330381072006316893, 11314148297699205195, 13044855026220615524]
        self.salt = salt ^ 2506558595298368259
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2506558595298368259) > 4821967535420636225 {
            routed = input &* 8592479639937553589 &+ 4724036198560947535
        } else {
            routed = (input &+ 3133227644291456115) ^ (input / 680194539791)
        }
        let slot = Int((routed >> 37) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 14753672852514028363)
    }
}

private struct Fragmentdea5dfd7a1306f13 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [11451588681514905756, 105995428337259985, 16521131965143202282, 11816712987822091641, 5293787855032808626, 14927358428454634357, 15577347388930585076, 2769417094421113801]
        self.salt = salt ^ 13226428160919994881
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 13226428160919994881) > 7609045888989381625 {
            routed = input &* 17807590056190477993 &+ 9790293175961116799
        } else {
            routed = (input &+ 7899591276713678762) ^ (input / 203242110265)
        }
        let slot = Int((routed >> 54) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 13333995940002259067)
    }
}

private struct Fragmentd44d785725796894 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [4008632512944293571, 13675195256301233868, 5807195648925477501, 13508868181650330090, 899779616441224478, 8362129317706065785, 17918378020708018991, 9673435281753281642]
        self.salt = salt ^ 12453561552323683881
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 12453561552323683881) > 7623266243262253576 {
            routed = input &* 16911706561368206561 &+ 6604826319772050801
        } else {
            routed = (input &+ 11409962988279944906) ^ (input / 16854165503)
        }
        let slot = Int((routed >> 32) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 365701261149486969)
    }
}

private struct Fragment1ecae1d7280c0717 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8612513953938177754, 10183154446816007149, 528974556254412269, 5653278376960758101, 9736311688448574424, 4268445337018682948, 9964191984911694680, 11154126825723795457]
        self.salt = salt ^ 10916886129612837445
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 10916886129612837445) > 16381743117686683844 {
            routed = input &* 18273354927526283977 &+ 14160635452084108030
        } else {
            routed = (input &+ 17863563816446328052) ^ (input / 824469725561)
        }
        let slot = Int((routed >> 40) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 4310103308661454509)
    }
}

private struct Fragment87074c04ee0f3395 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [11902663102218067625, 11523511555781612183, 16684156379942360195, 10921761283924713523, 14843967995918900964, 16085593921631796018, 1870601910053276550, 9318594598930781573]
        self.salt = salt ^ 5794548104963044775
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 5794548104963044775) > 6171751075782268778 {
            routed = input &* 17383399568217692037 &+ 7643834955754976378
        } else {
            routed = (input &+ 14349997197885290319) ^ (input / 704309745107)
        }
        let slot = Int((routed >> 37) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 8470119690318989787)
    }
}

