//
//  Network.swift
//  Novagraph
//
//  Created by Sophie on 12/1/18.
//

import Foundation

enum HTTPMethod {
    case get, post, delete
}

struct NetworkRequest {

    let method: HTTPMethod
    let path: String
    let params: [String: Any]

    static var ClientId = ""

    var domain: String = ""

    init(method: HTTPMethod, path: String, params: [String: Any] = [:]) {
        self.method = method
        self.path = path
        self.params = params
    }

}

class Network {

    static let shared = Network()

    func send(request: NetworkRequest, completion: ((Any?, Error?) -> Void)?) {
    }

    class func fetchImage(urlString: String, completionHandler: @escaping ((UIImage?, Error?) -> Void)) {
        guard let url = URL(string: urlString) else {
            return
        }
        let request = URLRequest(url: url)
        if let response = URLCache.shared.cachedResponse(for: request) {
            let image = UIImage(data: response.data)
            completionHandler(image, nil)
        } else {
            let task = URLSession.shared.dataTask(with: url) { (fetchedData, response, error) in
                if let data = fetchedData {
                    if let response = response {
                        let cachedResponse = CachedURLResponse(response: response, data: data)
                        URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                    }
                    let image = UIImage(data: data)
                    completionHandler(image, nil)
                } else {
                    completionHandler(nil, error)
                }
            }
            task.resume()
        }
    }

}

