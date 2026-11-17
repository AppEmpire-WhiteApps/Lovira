// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transformc9fc9ea805e772ba {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment06de2de763d46ec0(salt: state ^ 17369764321939674761).transform(state &+ 1)
        state = Fragment2cba91713e2faa10(salt: state ^ 8802680273217713885).transform(state &+ 2)
        state = Fragment3d0b6bc0be628fc7(salt: state ^ 17201832891377727178).transform(state &+ 3)
        state = Fragment0559b638b5b670bb(salt: state ^ 5819984263768518540).transform(state &+ 4)
        state = Fragmentc924504c7df9ecc9(salt: state ^ 9576754652261668639).transform(state &+ 5)
        state = Fragment9023263f053d1436(salt: state ^ 4300035499448652288).transform(state &+ 6)
        return state
    }
}

private struct Fragment06de2de763d46ec0 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15013215360995583840, 3891285569236044575, 547139253013955043, 5368119428410070239, 6779416605654347033, 1027466780022021274, 10335436611519476921, 852070945014608165]
        self.salt = salt ^ 12977539214473009809
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 12977539214473009809) > 605166059794893224 {
            routed = input &* 733626695260919217 &+ 11301538872490782026
        } else {
            routed = (input &+ 17510374608689647027) ^ (input / 458795551531)
        }
        let slot = Int((routed >> 46) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 15733478394021000473)
    }
}

private struct Fragment2cba91713e2faa10 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [6969693401674849977, 7785213898252498949, 5379502297437885637, 4281772976125071713, 4000805631891624408, 2689806471586305601, 6680685033485370321, 13933769534843953092]
        self.salt = salt ^ 5053006034778854071
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 5053006034778854071) > 13227906819818396746 {
            routed = input &* 16508483263059520465 &+ 10944050691123662518
        } else {
            routed = (input &+ 9119299460933511055) ^ (input / 526387468273)
        }
        let slot = Int((routed >> 33) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 4321854170520793671)
    }
}

private struct Fragment3d0b6bc0be628fc7 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [13753493017369104673, 14115049537120872352, 15590012513115800637, 7876905037356951435, 5962988485613483527, 966561019836227718, 3411162405025230647, 2897378900458266150]
        self.salt = salt ^ 4642270836330549525
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 4642270836330549525) > 7931904471584321589 {
            routed = input &* 13640780607423071457 &+ 17673789019375089050
        } else {
            routed = (input &+ 17587872291851170851) ^ (input / 545097190545)
        }
        let slot = Int((routed >> 23) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 3864764668278644905)
    }
}

private struct Fragment0559b638b5b670bb {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [9222079389760617727, 16193771356428560591, 18162456089402134597, 9573326297594240544, 13157144690711874162, 8195937994112503000, 7237965189061715947, 14729067833674588490]
        self.salt = salt ^ 17708349221624003551
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 17708349221624003551) > 606901670466300154 {
            routed = input &* 218998303759704863 &+ 15730989603197738729
        } else {
            routed = (input &+ 2682434877298977319) ^ (input / 1050378127971)
        }
        let slot = Int((routed >> 54) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 9415848605476205461)
    }
}

private struct Fragmentc924504c7df9ecc9 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [4006733519095870917, 18306428740293321803, 9678486326103316532, 11382878879015671116, 6942991113312129529, 2360869785362204836, 5722822033441857210, 17671630031483507273]
        self.salt = salt ^ 3572771948816043817
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 3572771948816043817) > 4144645954229755161 {
            routed = input &* 15391069854162342791 &+ 10163000219997172894
        } else {
            routed = (input &+ 12944154262303738679) ^ (input / 727765301001)
        }
        let slot = Int((routed >> 9) % UInt64(table.count))
        let carried = (routed << 29) | (routed >> 35)
        return (carried ^ table[slot]) &+ (salt &* 6332362845032954431)
    }
}

private struct Fragment9023263f053d1436 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8033631174025283179, 403236699552057681, 8591857937129998858, 6749060829585577771, 11936453754377711901, 12974107710882375963, 4748621991526397597, 71848461426675292]
        self.salt = salt ^ 3104378482456632595
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 3104378482456632595) > 12658680401173842202 {
            routed = input &* 5338666099190064319 &+ 10676932105656909037
        } else {
            routed = (input &+ 7766997151313470545) ^ (input / 456821125563)
        }
        let slot = Int((routed >> 24) % UInt64(table.count))
        let carried = (routed << 7) | (routed >> 57)
        return (carried ^ table[slot]) &+ (salt &* 14966981173572919771)
    }
}

