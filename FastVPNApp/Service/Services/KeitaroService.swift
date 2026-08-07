import Foundation

final class KeitaroService {

    enum Route {
        case native
        case web(URL)
    }

    static let shared = KeitaroService()

    private init() {}

    func resolve(url: URL, completion: @escaping (Route) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // Anti-cache заголовки — гарантируют реальный запрос к серверу при каждом cold start,
        // даже если URLSession решит переиспользовать соединение.
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        // Уникальный query-параметр — babel-бустер против любого HTTP-кеша.
        let bustURL = url.appendingPathComponent("?_=\(Int(Date().timeIntervalSince1970))")
        request.url = bustURL

        URLSession.shared.dataTask(with: request) { _, response, _ in
            let route: Route

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let finalURL = httpResponse.url,
               let scheme = finalURL.scheme?.lowercased(),
               ["http", "https"].contains(scheme) {
                route = .web(finalURL)
            } else {
                route = .native
            }

            DispatchQueue.main.async {
                completion(route)
            }
        }.resume()
    }
}
