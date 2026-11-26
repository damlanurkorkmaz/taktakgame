import GameKit
import UIKit

/// Game Center: sonsuz mod rekoru için sıralama.
///
/// App Store Connect > Uygulama > Game Center bölümünde bu kimlikle bir
/// "Klasik" sıralama oluştur: `taktak_endless` (büyük skor daha iyi).
final class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()
    static let leaderboardID = "taktak_endless"

    enum Status: Equatable {
        case unknown
        case signedIn(name: String)
        /// Giriş ekranı hazır; kullanıcı isterse gösterilir
        case needsLogin
        case unavailable(String)
    }

    @Published private(set) var status: Status = .unknown
    var isAuthenticated: Bool { GKLocalPlayer.local.isAuthenticated }

    private var loginController: UIViewController?
    private var handlerSet = false

    private override init() {
        super.init()
    }

    /// Uygulama açılırken bir kez çağrılır. Giriş ekranını hemen göstermez,
    /// kullanıcı kupaya basınca gösterilmek üzere saklar.
    func authenticate() {
        guard !handlerSet else { return }
        handlerSet = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let vc = viewController {
                    self.loginController = vc
                    self.status = .needsLogin
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.loginController = nil
                    self.status = .signedIn(name: GKLocalPlayer.local.displayName)
                } else if let error {
                    self.status = .unavailable(Self.describe(error))
                } else {
                    self.status = .unavailable("Game Center'a giriş yapılmadı.")
                }
            }
        }
    }

    func submit(score: Int) {
        guard GKLocalPlayer.local.isAuthenticated, score > 0 else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.leaderboardID]) { _ in }
    }

    /// Saklanan Game Center giriş ekranını gösterir.
    @discardableResult
    func presentLogin() -> Bool {
        guard let vc = loginController, let root = AdsManager.topViewController() else { return false }
        loginController = nil
        root.present(vc, animated: true)
        return true
    }

    /// Game Center sıralamasını gösterir. Giriş yoksa giriş ekranını açmayı dener.
    @discardableResult
    func showLeaderboard() -> Bool {
        guard GKLocalPlayer.local.isAuthenticated else {
            return presentLogin()
        }
        guard let root = AdsManager.topViewController() else { return false }
        let vc = GKGameCenterViewController(leaderboardID: Self.leaderboardID, playerScope: .global, timeScope: .allTime)
        vc.gameCenterDelegate = self
        root.present(vc, animated: true)
        return true
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }

    private static func describe(_ error: Error) -> String {
        let code = (error as NSError).code
        switch GKError.Code(rawValue: code) {
        case .notAuthenticated, .cancelled, .userDenied:
            return "Game Center'a giriş yapılmadı. iPhone Ayarlar > Game Center'dan giriş yapabilirsin."
        case .gameUnrecognized, .notSupported:
            return "Bu sürümde Game Center henüz etkin değil."
        case .communicationsFailure, .connectionTimeout:
            return "Game Center'a bağlanılamadı. İnterneti kontrol et."
        default:
            return "Game Center şu an kullanılamıyor."
        }
    }
}
