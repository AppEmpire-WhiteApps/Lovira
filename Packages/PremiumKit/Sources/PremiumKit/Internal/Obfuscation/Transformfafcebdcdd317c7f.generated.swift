// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transformfafcebdcdd317c7f {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment94596e41b49c0d9d(salt: state ^ 4818525061633173584).transform(state &+ 1)
        state = Fragmentc950e5dd8e958c8a(salt: state ^ 16829261182091901914).transform(state &+ 2)
        state = Fragment1e27a1ca9b1cc6d7(salt: state ^ 6720305988238422406).transform(state &+ 3)
        state = Fragment196618feba33ec9f(salt: state ^ 15487139600874761559).transform(state &+ 4)
        state = Fragment9ac1188526e3e6b1(salt: state ^ 2574105540797397037).transform(state &+ 5)
        state = Fragmentf0ec1dff455442cf(salt: state ^ 7929694038089598067).transform(state &+ 6)
        return state
    }
}

private struct Fragment94596e41b49c0d9d {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [2713761065819187332, 13266804579562059472, 8941150472392585786, 10615433790910589449, 10623824323441019257, 12205883011716846527, 5803500136326866775, 9187223059970885057]
        self.salt = salt ^ 17894868886118102709
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 17894868886118102709) > 1684884400044251295 {
            routed = input &* 6449245803555271247 &+ 6616537616215723428
        } else {
            routed = (input &+ 16937966883556469113) ^ (input / 11576473695)
        }
        let slot = Int((routed >> 22) % UInt64(table.count))
        let carried = (routed << 19) | (routed >> 45)
        return (carried ^ table[slot]) &+ (salt &* 11348030580717977055)
    }
}

private struct Fragmentc950e5dd8e958c8a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8212030338819665916, 11464448052727910557, 6827526820697893341, 12001804998442758525, 8294947352005538705, 4227609086466108634, 16816601109458724180, 17680081550311579779]
        self.salt = salt ^ 8947621481475160605
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 8947621481475160605) > 13147895641911231391 {
            routed = input &* 1363446970930758475 &+ 4906087802724146987
        } else {
            routed = (input &+ 5538733799434284230) ^ (input / 968415921737)
        }
        let slot = Int((routed >> 45) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 9837192031788726813)
    }
}

private struct Fragment1e27a1ca9b1cc6d7 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [16086876244596945667, 4084663963636678048, 9113845733701397898, 288735418116646161, 1024778052884137155, 168722614749539579, 12338602029221921291, 12735364695409496354]
        self.salt = salt ^ 1190456551154749081
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 1190456551154749081) > 4754097695125298187 {
            routed = input &* 1459317738304343639 &+ 2817231237119280376
        } else {
            routed = (input &+ 7197378632221569383) ^ (input / 701102262317)
        }
        let slot = Int((routed >> 27) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 12063122694010003733)
    }
}

private struct Fragment196618feba33ec9f {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15015570638066823365, 3808491841270764568, 10850973313611204232, 17694353255949276950, 15140656866976135186, 14320113949478868937, 5677191219885407991, 6064065179209539406]
        self.salt = salt ^ 13292944405600538863
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 13292944405600538863) > 13383206909066283977 {
            routed = input &* 2120089191285892681 &+ 2077407403073008336
        } else {
            routed = (input &+ 14648885555464285805) ^ (input / 299663871937)
        }
        let slot = Int((routed >> 4) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 10174846091696201899)
    }
}

private struct Fragment9ac1188526e3e6b1 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [3429687077973910605, 12920077376072664867, 16026846899396524330, 17470507111725364352, 15606608237863298771, 11439339536438410613, 5655734925758079929, 5767679247407586400]
        self.salt = salt ^ 926378092700374053
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 926378092700374053) > 10727572404217154612 {
            routed = input &* 3955348748474850287 &+ 17256106753285816348
        } else {
            routed = (input &+ 4152472572929866033) ^ (input / 415857554333)
        }
        let slot = Int((routed >> 19) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 3299394163637550661)
    }
}

private struct Fragmentf0ec1dff455442cf {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [7745215328685205067, 1744668960244893710, 6715262292149622720, 1044947482943920311, 3884492121668249147, 18349362479971529880, 2239324950675001964, 3445570202503963965]
        self.salt = salt ^ 780036644201594771
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 780036644201594771) > 4992780729314521832 {
            routed = input &* 5537462684774959419 &+ 7107762777800970229
        } else {
            routed = (input &+ 5811915049119881109) ^ (input / 1048489916079)
        }
        let slot = Int((routed >> 54) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 10918209813416167537)
    }
}

