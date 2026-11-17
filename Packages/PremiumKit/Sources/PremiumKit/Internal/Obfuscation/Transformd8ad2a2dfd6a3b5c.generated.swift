// Generated source diversification. Regenerate from a clean clone; do not edit.
internal enum Transformd8ad2a2dfd6a3b5c {
    @inline(never)
    static func mix(_ input: UInt64) -> UInt64 {
        var state = input
        state = Fragmentd4945b52c0d24219(salt: state ^ 7382365043055744308).transform(state &+ 1)
        state = Fragment86a2068017cf24f7(salt: state ^ 10127285196122317933).transform(state &+ 2)
        state = Fragmentbda56c69109fbe1c(salt: state ^ 14064076323388522703).transform(state &+ 3)
        state = Fragmentaab2918e93127dea(salt: state ^ 18371764165613970530).transform(state &+ 4)
        state = Fragmenta5760879093abeb9(salt: state ^ 11392514833024368457).transform(state &+ 5)
        state = Fragment6b7cb5c3796819dc(salt: state ^ 5685610137696708673).transform(state &+ 6)
        return state
    }
}

private struct Fragmentd4945b52c0d24219 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8721201609830123476, 7778890017421928182, 17746225092765723771, 3748193123386548433, 5746821418639088825, 3092721391068136517, 160806183637766914, 16145631619880086931]
        self.salt = salt ^ 15411756791904034005
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 15411756791904034005) > 12358707380294428708 {
            routed = input &* 8217499783101221829 &+ 247346364287156792
        } else {
            routed = (input &+ 14415131916292653735) ^ (input / 792563409469)
        }
        let slot = Int((routed >> 34) % UInt64(table.count))
        let carried = (routed << 19) | (routed >> 45)
        return (carried ^ table[slot]) &+ (salt &* 6452773916117294063)
    }
}

private struct Fragment86a2068017cf24f7 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [11644216979055252120, 12303198347128724492, 10235489711132355254, 13493237036455983900, 4438892393801809090, 857521789162664444, 13805811852525975188, 2103889659687355571]
        self.salt = salt ^ 15362790226924045645
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 15362790226924045645) > 14953028396442569203 {
            routed = input &* 15751894613423980043 &+ 762914191615845153
        } else {
            routed = (input &+ 1468361143019144918) ^ (input / 856539516809)
        }
        let slot = Int((routed >> 13) % UInt64(table.count))
        let carried = (routed << 7) | (routed >> 57)
        return (carried ^ table[slot]) &+ (salt &* 16295865071869133571)
    }
}

private struct Fragmentbda56c69109fbe1c {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [8963995741933863533, 1304541496367361315, 17564878618212985126, 17437592591800413673, 16477083876215963098, 7891617743913705155, 2747952322960523949, 2889561372915756255]
        self.salt = salt ^ 16959329488421894505
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 16959329488421894505) > 13646306224348903041 {
            routed = input &* 6754551884432573557 &+ 18063949966993687142
        } else {
            routed = (input &+ 7659274703080501696) ^ (input / 383482861059)
        }
        let slot = Int((routed >> 40) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 2841849728736272699)
    }
}

private struct Fragmentaab2918e93127dea {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [15771228831226771694, 3211156226337597154, 4972467116942535828, 15137575856628350117, 10289246973448321854, 2671598633375485230, 10287766734005937088, 17882397533060945999]
        self.salt = salt ^ 4722211383595571593
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 4722211383595571593) > 4083138682823362754 {
            routed = input &* 14359178076475979751 &+ 14035602149139578972
        } else {
            routed = (input &+ 7717428235477267896) ^ (input / 56234306617)
        }
        let slot = Int((routed >> 28) % UInt64(table.count))
        let carried = (routed << 23) | (routed >> 41)
        return (carried ^ table[slot]) &+ (salt &* 10093103360274282395)
    }
}

private struct Fragmenta5760879093abeb9 {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [6455938479797855609, 3756032125778407360, 17587576371538950947, 149014428126370275, 6268443620852673750, 18382875117627997712, 1495467679392119990, 17621392876465409801]
        self.salt = salt ^ 621975340478313193
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 621975340478313193) > 12322595393551328581 {
            routed = input &* 8578331268515900967 &+ 6570821992508489792
        } else {
            routed = (input &+ 9270013342985431694) ^ (input / 210750304827)
        }
        let slot = Int((routed >> 47) % UInt64(table.count))
        let carried = (routed << 31) | (routed >> 33)
        return (carried ^ table[slot]) &+ (salt &* 15005003320279351601)
    }
}

private struct Fragment6b7cb5c3796819dc {
    private let table: [UInt64]
    private let salt: UInt64

    init(salt: UInt64) {
        table = [10212822746697921634, 2481220912979126575, 9905117809764731444, 10446330989283530168, 3713567564801025084, 12021558892364562344, 3248852067252826784, 7747203054039251801]
        self.salt = salt ^ 12841910776844317299
    }

    @inline(never)
    func transform(_ input: UInt64) -> UInt64 {
        let routed: UInt64
        if (input & 12841910776844317299) > 10158779270393006286 {
            routed = input &* 6428138609699604299 &+ 16232232717005215125
        } else {
            routed = (input &+ 5032660774194717990) ^ (input / 52517740695)
        }
        let slot = Int((routed >> 41) % UInt64(table.count))
        let carried = (routed << 17) | (routed >> 47)
        return (carried ^ table[slot]) &+ (salt &* 8893514108809139057)
    }
}

