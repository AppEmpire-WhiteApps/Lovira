// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transform93ff9330741703a7 {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragment3ef561a30872b603(salt: state ^ 11579589500739034810).transform(state &+ 1)
        state = Fragmentf2d092cde0d83972(salt: state ^ 17762640530687980157).transform(state &+ 2)
        state = Fragment6ab5e65683c6e952(salt: state ^ 5802502942053782583).transform(state &+ 3)
        state = Fragment1518ea8bb4a7a943(salt: state ^ 71474806502481247).transform(state &+ 4)
        state = Fragment552dc6a898dc112a(salt: state ^ 17202454601967314722).transform(state &+ 5)
        state = Fragment7c28845ca77b9c59(salt: state ^ 16077222584857850789).transform(state &+ 6)
        return state
    }
}

private struct Fragment3ef561a30872b603 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [16091268284876329030, 13933524810384977071, 2365205971487855550, 14294920527202970412, 5177718743812088158, 10868488589364587589, 6414938539334605084, 2086810482779120107]
        self.salt = salt ^ 18295465444917958443
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 18295465444917958443) > 15930028625541739951 {
            routed = input &* 2264466929573120511 &+ 12725962591949755425
        } else {
            routed = (input &+ 13719497699138153119) ^ (input / 530520845353)
        }
        let slot = Int((routed >> 49) % UInt64(table.count))
        let carried = (routed << 11) | (routed >> 53)
        return (carried ^ table[slot]) &+ (salt &* 11864586119464643603)
    }
}

private struct Fragmentf2d092cde0d83972 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [4356946700238204379, 5711263088435042589, 14645743910555606803, 15745150072745632147, 8479408718407194185, 2123632247677126275, 15347923752645708700, 17624536397390810608]
        self.salt = salt ^ 12494168163087607935
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 12494168163087607935) > 14862002968103147573 {
            routed = input &* 1695039310829735481 &+ 2085549954431611302
        } else {
            routed = (input &+ 5203425635307599910) ^ (input / 594901115651)
        }
        let slot = Int((routed >> 33) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 17578545097906104979)
    }
}

private struct Fragment6ab5e65683c6e952 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [2162928006077063494, 11239934134997515235, 2283174073500686121, 4595711165084511317, 2331086104951852675, 123915396622930088, 8855270045113383631, 17185154631069269083]
        self.salt = salt ^ 4976757520460069173
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 4976757520460069173) > 14292420228883361574 {
            routed = input &* 5947718894094238667 &+ 17527392486645823719
        } else {
            routed = (input &+ 5643698572008440143) ^ (input / 876756590599)
        }
        let slot = Int((routed >> 15) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 2295548395305402983)
    }
}

private struct Fragment1518ea8bb4a7a943 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [16332592996026140121, 2497695610035811970, 13076485406765147736, 8331377894961676456, 11148646863657589698, 10294497398040844340, 6104599761410605564, 3412876870263969990]
        self.salt = salt ^ 7004539805103124981
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 7004539805103124981) > 17378984828154690347 {
            routed = input &* 4388202368551810163 &+ 2889288826460243257
        } else {
            routed = (input &+ 13200685699992584287) ^ (input / 167793350339)
        }
        let slot = Int((routed >> 2) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 616261787946662589)
    }
}

private struct Fragment552dc6a898dc112a {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [16381436869820015819, 3500567082413650960, 13844344638242349717, 17887285496165533745, 251435050907427887, 1889379570875343137, 50238829142046675, 14415294612000662249]
        self.salt = salt ^ 3358148773212175797
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 3358148773212175797) > 15024933735968340105 {
            routed = input &* 16474335186491128729 &+ 11395871089923467725
        } else {
            routed = (input &+ 16472959674374264191) ^ (input / 543950132153)
        }
        let slot = Int((routed >> 15) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 11533887902103817019)
    }
}

private struct Fragment7c28845ca77b9c59 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [12501259737821375695, 6970966964601545948, 7954365284912532, 5008984092966918043, 8616514908669698792, 4129119112697983525, 1644120392835784238, 330981487074448981]
        self.salt = salt ^ 6286821223707503491
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 6286821223707503491) > 512885948328279902 {
            routed = input &* 5754376515050119977 &+ 8026895102758701640
        } else {
            routed = (input &+ 7423624684250145322) ^ (input / 52949903259)
        }
        let slot = Int((routed >> 48) % UInt64(table.count))
        let carried = (routed << 7) | (routed >> 57)
        return (carried ^ table[slot]) &+ (salt &* 8506835096679781447)
    }
}

