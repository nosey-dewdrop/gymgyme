import Foundation

enum Config {
    static let usdaAPIKey: String = {
        // reads from Config.plist (gitignored)
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["USDA_API_KEY"] as? String else {
            return "DEMO_KEY"
        }
        return key
    }()
}
