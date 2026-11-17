// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transforme1ef55bbaa2c1597 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment9335eb03d03cbc9c(salt: state ^ 17354708932506007523).transform(state &+ 1)
        state = Fragment97e1534b57520ea3(salt: state ^ 6696581645343052324).transform(state &+ 2)
        state = Fragmenta3159c2376a4b909(salt: state ^ 15385677642421443447).transform(state &+ 3)
        state = Fragmentf4ffc83169c5e078(salt: state ^ 680003559653866061).transform(state &+ 4)
        state = Fragmentd1e3e690acb4684e(salt: state ^ 8599626660276356817).transform(state &+ 5)
        state = Fragment720189f2efb2747a(salt: state ^ 728445795414635642).transform(state &+ 6)
        return state
    }
}

private struct Fragment9335eb03d03cbc9c {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [7916411327474589337, 18162022652781821949, 8723990032037575179, 9197037397623006784, 9652335019035681252, 2835277736366925981, 3322957614302806686, 8672327961311597223]
        self.salt = salt ^ 12097242146173583855
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 12097242146173583855) > 16709067293290807810 {
            routed = input &* 11742022416328882749 &+ 4582336812029473358
        } else {
            routed = (input &+ 14022309418115474995) ^ (input / 891489122023)
        }
        let slot = Int((routed >> 11) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 5442321814230822609)
    }
}

private struct Fragment97e1534b57520ea3 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [91090819276317538, 3514640874942267333, 5776435037388976191, 17758653788393160775, 12728767919008004081, 4378519044217074384, 9146128794699392496, 17562201663680697222]
        self.salt = salt ^ 3060587177766742549
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 3060587177766742549) > 2922210084992768706 {
            routed = input &* 8245520937923430911 &+ 10690322129274552610
        } else {
            routed = (input &+ 5234003920560571957) ^ (input / 475617273797)
        }
        let slot = Int((routed >> 8) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 7189024019735927249)
    }
}

private struct Fragmenta3159c2376a4b909 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [12494543876350861825, 12639360893233002899, 2758323061018095609, 8369795451268556203, 6767850638691969218, 1328888541126921546, 14663712761327981557, 5348113022953519766]
        self.salt = salt ^ 13619194678753333257
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 13619194678753333257) > 8802976111912107795 {
            routed = input &* 12246420929478147793 &+ 7223878471103794995
        } else {
            routed = (input &+ 13324657591054450222) ^ (input / 823317630453)
        }
        let slot = Int((routed >> 52) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 4440966871976984465)
    }
}

private struct Fragmentf4ffc83169c5e078 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8610222879662435128, 12087136935410774123, 718503558317332928, 14844807198591700350, 12031045565607523293, 11559963991888543566, 11984511388538134869, 8263785871594372956]
        self.salt = salt ^ 13113714016364587357
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 13113714016364587357) > 3765676829893802881 {
            routed = input &* 15527329568671566481 &+ 6225041148313138253
        } else {
            routed = (input &+ 6942146541037646661) ^ (input / 935692021063)
        }
        let slot = Int((routed >> 4) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 14931709720289338191)
    }
}

private struct Fragmentd1e3e690acb4684e {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [10451210001091449047, 4970706228041954862, 817255909776527165, 2157096418336147645, 2488989828203257929, 14863623553735621319, 12128373990012351975, 8026296443817637458]
        self.salt = salt ^ 14904444151605467603
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 14904444151605467603) > 204031944433154711 {
            routed = input &* 18232485193910565521 &+ 8454831325881670177
        } else {
            routed = (input &+ 9128067196629080334) ^ (input / 437460301459)
        }
        let slot = Int((routed >> 4) % UInt64(table.count))
        let carried = (routed << 19) | (routed >> 45)
        return (carried ^ table[slot]) &+ (salt &* 4563619010774388693)
    }
}

private struct Fragment720189f2efb2747a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [2768427512127623628, 15869341766619752562, 10285880593883586939, 13263472712752996322, 5585330573936809108, 15626742404194008965, 12942070750107728358, 16381034557518574115]
        self.salt = salt ^ 2384292239552189335
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 2384292239552189335) > 10996927492840315602 {
            routed = input &* 16347064620631555751 &+ 12231247827632999148
        } else {
            routed = (input &+ 12969188440842354635) ^ (input / 1069397867443)
        }
        let slot = Int((routed >> 53) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 9859676676683200543)
    }
}

