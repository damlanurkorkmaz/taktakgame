import Foundation

/// Uygulama dili: cihaz (ya da Ayarlar > Tak Tak > Dil) Türkçe ise Türkçe, değilse İngilizce.
enum Lang {
    static let isTurkish: Bool = {
        for code in Locale.preferredLanguages {
            if code.hasPrefix("tr") { return true }
            if code.hasPrefix("en") { return false }
        }
        return false
    }()

    static var localeID: String { isTurkish ? "tr_TR" : "en_US" }
}

/// Metnin Türkçe ve İngilizce hâli; uygulama diline göre birini döndürür.
@inline(__always)
func L(_ tr: String, _ en: String) -> String {
    Lang.isTurkish ? tr : en
}

/// Destek ve gizlilik sayfaları (repo'daki docs/ klasörü, GitHub Pages)
enum AppLinks {
    private static let base = "https://damlanurkorkmaz.github.io/taktakgame/"
    private static var langQuery: String { Lang.isTurkish ? "?lang=tr" : "?lang=en" }
    static var support: URL { URL(string: base + "support.html" + langQuery)! }
    static var privacy: URL { URL(string: base + "privacy.html" + langQuery)! }
}
