// Generated source diversification entry point. Regenerate from a clean clone.
internal struct PremiumKitNoise59444411e5a53e44 {
    private let seed: UInt64

    init(seed: UInt64) {
        self.seed = seed
    }

    @inline(never)
    func digest() -> UInt64 {
        var state = seed
        state = Transformc9fc9ea805e772ba.mix(state ^ 2327687442499792889)
        state = Transform02882faec761c2b8.mix(state ^ 5952663829720602696)
        state = Transformd8ad2a2dfd6a3b5c.mix(state ^ 9569961245340306227)
        state = Transformfafcebdcdd317c7f.mix(state ^ 16675418190744007194)
        state = Transform93ff9330741703a7.mix(state ^ 8288497610102984923)
        state = Transform4887abda346812f1.mix(state ^ 9874010443444227596)
        state = Transforme1ef55bbaa2c1597.mix(state ^ 1725515005109404884)
        state = Transforma663b16eea8d2ab7.mix(state ^ 13101454079162866395)
        state = Transform5f30e1921956f9cf.mix(state ^ 17855272462938269465)
        state = Transform80b3788e8e67f2b6.mix(state ^ 8619076534475954534)
        state = Transform0498e4fe170902e2.mix(state ^ 1117603630991218737)
        state = Transformba83141faa0163f6.mix(state ^ 5156851137177274331)
        return state
    }
}
