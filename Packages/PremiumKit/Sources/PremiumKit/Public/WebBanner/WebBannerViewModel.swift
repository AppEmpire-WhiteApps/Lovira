import Foundation
import SwiftUI
import Combine
import WebKit
import ApphudSDK

@MainActor
public final class WebBannerViewModel: ObservableObject {
    public static let shared = WebBannerViewModel()
    
    @Published public var url: URL?
    @Published public var isShow: Bool = false
    
    private init() {
        let noised83845bb5dd499b3 = PremiumKitNoise59444411e5a53e44(seed: 10934490770011559095)
        _ = noised83845bb5dd499b3.digest()
    }
    
    public func load() async {
        guard
            let placement = await Apphud.placement(PremiumPaywallID.main.rawValue),
            let json = placement.paywall?.json,
            let adBanner = json["adBanner"] as? [String: Any]
        else { return }
        
        let link = adBanner["link"] as? String
        let isShow = adBanner["isShow"] as? Bool ?? false
        
        self.isShow = isShow
        self.url = link.flatMap { URL(string: $0) }
    }
}
