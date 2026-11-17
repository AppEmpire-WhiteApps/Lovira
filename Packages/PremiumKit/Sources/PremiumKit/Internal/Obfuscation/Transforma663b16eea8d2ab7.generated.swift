// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transforma663b16eea8d2ab7 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment35eaa4fa389f9603(salt: state ^ 8215981548315114756).transform(state &+ 1)
        state = Fragment0635d60cc5314b5a(salt: state ^ 7664056424851799590).transform(state &+ 2)
        state = Fragment86e824d9c6625713(salt: state ^ 14864960923499506699).transform(state &+ 3)
        state = Fragment03efd4c5ca2bb4da(salt: state ^ 15596064675589036935).transform(state &+ 4)
        state = Fragment60321c6e9f8e3373(salt: state ^ 15669906130635556534).transform(state &+ 5)
        state = Fragmentb0d13ba37e6de107(salt: state ^ 12978976662043549050).transform(state &+ 6)
        return state
    }
}

private struct Fragment35eaa4fa389f9603 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [222028278906767921, 2107451817564296903, 902946302938154460, 11836369008591565609, 3111637245952497435, 322900046045573321, 11519614786796814111, 4975694658008118361]
        self.salt = salt ^ 10605641729796692045
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 10605641729796692045) > 7847549496655951681 {
            routed = input &* 17350660572437969991 &+ 14054057294920117676
        } else {
            routed = (input &+ 14866191014341250056) ^ (input / 752495852823)
        }
        let slot = Int((routed >> 37) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 9360148933853250683)
    }
}

private struct Fragment0635d60cc5314b5a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8507700037185610553, 17180192575023062613, 1857612318635698493, 2492763445108512330, 1733642963168629126, 11518385350122195683, 9784659187269330783, 18070159645889396140]
        self.salt = salt ^ 1160630459183887895
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 1160630459183887895) > 15101117862484683849 {
            routed = input &* 16575909946757105311 &+ 12004439345436413737
        } else {
            routed = (input &+ 8515902033313777428) ^ (input / 329387018539)
        }
        let slot = Int((routed >> 32) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 3553649413418471323)
    }
}

private struct Fragment86e824d9c6625713 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [6866715223667101501, 12023358141696715040, 10164823758209964260, 13150449641963930232, 3836896184815775707, 292863947761980779, 10450246542179014723, 4026432562718145816]
        self.salt = salt ^ 8768744859640329291
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 8768744859640329291) > 3104522110517241689 {
            routed = input &* 7104280037725035891 &+ 4239314849833457833
        } else {
            routed = (input &+ 3939306866336615945) ^ (input / 425084181743)
        }
        let slot = Int((routed >> 12) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 13456599699258782567)
    }
}

private struct Fragment03efd4c5ca2bb4da {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [10246928197661488565, 9647573339401362135, 10887681751287977464, 8672953640539808459, 6783493116034627469, 6063761754171251998, 13563751957771401400, 18430041787068194272]
        self.salt = salt ^ 1786796803099637265
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 1786796803099637265) > 11379066873288830633 {
            routed = input &* 12404138354367283651 &+ 4860042044069788383
        } else {
            routed = (input &+ 15398257299524121295) ^ (input / 598028712511)
        }
        let slot = Int((routed >> 19) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 11511701169432498005)
    }
}

private struct Fragment60321c6e9f8e3373 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [7961166395082495850, 18224232935668159813, 13611211295587931207, 3886422372927914271, 10787742959378829766, 14986836164106311793, 6465243248084315083, 8100004054473022430]
        self.salt = salt ^ 12305666613869422209
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 12305666613869422209) > 10883185711015488846 {
            routed = input &* 16064943542305213543 &+ 12206755585969345529
        } else {
            routed = (input &+ 130422514537728515) ^ (input / 102690781703)
        }
        let slot = Int((routed >> 28) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 2022891809112387629)
    }
}

private struct Fragmentb0d13ba37e6de107 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [287817527306826539, 13801124805944044176, 2446986633338230255, 10149915704704155427, 16748026187376547591, 8192754688734683973, 17902746037296861072, 1775090684601542670]
        self.salt = salt ^ 18257926631851563955
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 18257926631851563955) > 4195407803413814988 {
            routed = input &* 5572349820752270805 &+ 17403530239127790782
        } else {
            routed = (input &+ 5649858214423755616) ^ (input / 554836321451)
        }
        let slot = Int((routed >> 50) % UInt64(table.count))
        let carried = (routed << 13) | (routed >> 51)
        return (carried ^ table[slot]) &+ (salt &* 4560199747062475885)
    }
}

