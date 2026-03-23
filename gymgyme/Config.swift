import Foundation

enum Config {
    // proxy URL - set this after deploying the Cloudflare Worker
    // format: https://gymgyme-usda-proxy.<subdomain>.workers.dev
    static let usdaProxyURL: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["USDA_PROXY_URL"] as? String, !url.isEmpty else {
            // fallback to direct API with demo key (development only)
            return ""
        }
        return url
    }()

    static let usdaAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["USDA_API_KEY"] as? String else {
            return "DEMO_KEY"
        }
        return key
    }()

    static func usdaSearchURL(query: String, pageSize: Int = 15) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if !usdaProxyURL.isEmpty {
            // use proxy - key never leaves server
            return "\(usdaProxyURL)/search?query=\(encoded)&pageSize=\(pageSize)"
        } else {
            // direct API - development fallback only
            return "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encoded)&pageSize=\(pageSize)&api_key=\(usdaAPIKey)"
        }
    }
}
