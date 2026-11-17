// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transform02882faec761c2b8 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment2cf6e0193674ab11(salt: state ^ 6930892694067848311).transform(state &+ 1)
        state = Fragmente9ab6f05de424e16(salt: state ^ 17727575526608672255).transform(state &+ 2)
        state = Fragment6371d3a91747d8b4(salt: state ^ 17641324382763236588).transform(state &+ 3)
        state = Fragmentbb72af6273ea135a(salt: state ^ 16720117290291922673).transform(state &+ 4)
        state = Fragmenta42d5c57bb4f8e63(salt: state ^ 17117962538059804455).transform(state &+ 5)
        state = Fragment2064b759f6f82668(salt: state ^ 3406211769121807530).transform(state &+ 6)
        return state
    }
}

private struct Fragment2cf6e0193674ab11 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [12765244753753560956, 6781720901734940500, 7655852893552969009, 16891011739747012704, 6156513924221392291, 4559394246357496877, 1077711322599593616, 6212260589661547136]
        self.salt = salt ^ 11116017735113287321
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 11116017735113287321) > 5491400910460441421 {
            routed = input &* 4725382352262024573 &+ 13370422062164140101
        } else {
            routed = (input &+ 1233171796536715414) ^ (input / 818786653697)
        }
        let slot = Int((routed >> 11) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 1531845150025798181)
    }
}

private struct Fragmente9ab6f05de424e16 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [17738879462960045231, 8308575278640930743, 1600309447619293707, 5161489933834713904, 18153276108615356683, 11897484250344582538, 6951034507225962023, 7154911686562179196]
        self.salt = salt ^ 7811890877321779203
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 7811890877321779203) > 17999572174315670616 {
            routed = input &* 2525604568203677673 &+ 4917589872130360281
        } else {
            routed = (input &+ 5112350549763900445) ^ (input / 886007983549)
        }
        let slot = Int((routed >> 25) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 6775657823096964941)
    }
}

private struct Fragment6371d3a91747d8b4 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [6916457485208913432, 5752041536250860991, 6956892499409210392, 3407732138761833146, 11136654782178349914, 15888887223840256275, 1144774399484541955, 17919112636978897266]
        self.salt = salt ^ 16415207917562092181
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 16415207917562092181) > 14892732239761000454 {
            routed = input &* 6520907050199115773 &+ 8514326717547138790
        } else {
            routed = (input &+ 6919705996341598698) ^ (input / 605533086923)
        }
        let slot = Int((routed >> 52) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 15233257472484053561)
    }
}

private struct Fragmentbb72af6273ea135a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8113321920985471984, 15611031848083326062, 1862419307822366962, 4640723314295384333, 9482321297600612673, 8556279452275004070, 14965389340123043764, 9226494080511423049]
        self.salt = salt ^ 9718660220214039077
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 9718660220214039077) > 14829702116407938853 {
            routed = input &* 8508086975994963477 &+ 12809885116967534536
        } else {
            routed = (input &+ 12661621605715115479) ^ (input / 30714137181)
        }
        let slot = Int((routed >> 10) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 12600778474869959625)
    }
}

private struct Fragmenta42d5c57bb4f8e63 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [10783412232375935463, 4711540831629801300, 7920290132451093791, 8190018001148712332, 8870711147575720378, 2937102856693076877, 17487709352367278229, 11915207344467076817]
        self.salt = salt ^ 6757953286313572667
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 6757953286313572667) > 3054211642165154116 {
            routed = input &* 6359522775294763339 &+ 10316943411536292388
        } else {
            routed = (input &+ 15380603770217414144) ^ (input / 5794256967)
        }
        let slot = Int((routed >> 44) % UInt64(table.count))
        let carried = (routed << 19) | (routed >> 45)
        return (carried ^ table[slot]) &+ (salt &* 14816800855298999695)
    }
}

private struct Fragment2064b759f6f82668 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [3060440688344058036, 8034887477923881010, 2121425462172082599, 14379309695927470206, 11526800954388833474, 3532374609585716652, 9986299513116707212, 18207810403377840400]
        self.salt = salt ^ 15324794206339633199
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 15324794206339633199) > 14449602953381967345 {
            routed = input &* 4741569696671196053 &+ 15663515313608957916
        } else {
            routed = (input &+ 12005141639882677656) ^ (input / 939434605955)
        }
        let slot = Int((routed >> 46) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 15759569641757444583)
    }
}

