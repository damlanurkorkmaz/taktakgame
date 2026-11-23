import GameKit
import UIKit

/// Game Center: sonsuz mod rekoru için sıralama.
///
/// App Store Connect > Uygulama > Game Center bölümünde bu kimlikle bir
/// "Klasik" sıralama oluştur: `taktak_endless` (büyük skor daha iyi).
final class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()
    static let leaderboardID = "taktak_endless"

    @Published private(set) var isAuthenticated = false

    private override init() {
        super.init()
    }

    /// Uygulama açılırken çağrılır; gerekirse Game Center giriş ekranını gösterir.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            DispatchQueue.main.async {
                if let vc = viewController, let root = AdsManager.topViewController() {
                    root.present(vc, animated: true)
                    return
                }
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    func submit(score: Int) {
        guard GKLocalPlayer.local.isAuthenticated, score > 0 else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.leaderboardID]) { _ in }
    }

    /// Sıralamayı gösterir. Giriş yapılmamışsa false döner.
    @discardableResult
    func showLeaderboard() -> Bool {
        guard GKLocalPlayer.local.isAuthenticated, let root = AdsManager.topViewController() else {
            authenticate()
            return false
        }
        let vc = GKGameCenterViewController(leaderboardID: Self.leaderboardID, playerScope: .global, timeScope: .allTime)
        vc.gameCenterDelegate = self
        root.present(vc, animated: true)
        return true
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
