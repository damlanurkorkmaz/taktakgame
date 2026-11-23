import GoogleMobileAds
import UIKit

/// Ödüllü reklamlar (Google AdMob).
///
/// Kimlikler:
/// - Uygulama kimliği: `GADApplicationIdentifier` (TakTak-Info.plist)
/// - Ödüllü reklam birimi: `liveRewardedUnitID` (bu dosya)
///
/// Geliştirme (Debug) ve TestFlight derlemelerinde Google'ın test reklam birimi kullanılır:
/// kendi gerçek reklamlarına tıklamak AdMob hesabının askıya alınmasına yol açabilir.
/// Gerçek reklamlar yalnızca App Store'dan indirilen sürümde gösterilir.
final class AdsManager: NSObject, ObservableObject, GADFullScreenContentDelegate {
    static let shared = AdsManager()

    /// Gerçek ödüllü reklam birimi (AdMob > Tak Tak > Reklam birimleri)
    static let liveRewardedUnitID = "ca-app-pub-5668432995057749/8773502690"
    /// Google'ın test ödüllü reklam birimi
    static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// Debug ya da TestFlight ise test birimi, App Store sürümünde gerçek birim.
    static var rewardedUnitID: String {
        #if DEBUG
        return testRewardedUnitID
        #else
        return isTestFlight ? testRewardedUnitID : liveRewardedUnitID
        #endif
    }

    /// TestFlight derlemelerinin makbuzu "sandboxReceipt" adını taşır.
    private static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    @Published private(set) var isReady = false

    private var rewardedAd: GADRewardedAd?
    private var isLoading = false
    private var earned = false
    private var completion: ((Bool) -> Void)?
    private var started = false

    private override init() {
        super.init()
    }

    /// Uygulama açılırken çağrılır.
    func start() {
        guard !started else { return }
        started = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        load()
    }

    func load() {
        guard !isLoading, rewardedAd == nil else { return }
        isLoading = true
        GADRewardedAd.load(withAdUnitID: Self.rewardedUnitID, request: GADRequest()) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                if error != nil {
                    self.rewardedAd = nil
                    self.isReady = false
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isReady = ad != nil
            }
        }
    }

    /// Ödüllü reklam gösterir. Reklam izlenip ödül kazanıldıysa completion(true).
    /// Reklam hazır değilse completion(false) hemen çağrılır ve yeni reklam yüklenir.
    func showRewarded(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, let root = Self.topViewController() else {
            completion(false)
            load()
            return
        }
        earned = false
        self.completion = completion
        MusicPlayer.shared.duck(true)
        ad.present(fromRootViewController: root) { [weak self] in
            self?.earned = true
        }
    }

    // MARK: - GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        finish()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        earned = false
        finish()
    }

    private func finish() {
        MusicPlayer.shared.duck(false)
        let result = earned
        let done = completion
        completion = nil
        rewardedAd = nil
        isReady = false
        load()
        DispatchQueue.main.async { done?(result) }
    }

    // MARK: - Yardımcı

    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
