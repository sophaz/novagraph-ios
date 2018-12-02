//
//  Network.swift
//  Novagraph
//
//  Created by Sophie on 12/1/18.
//

import Foundation

public enum HTTPMethod {
    case get, post, delete
}

public struct NetworkRequest {

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

public protocol AccessToken {
    var tokenString: String { get }
}

public class Network {

    public static let shared = Network()

    public func send(request: NetworkRequest, token: AccessToken?, completion: ((Any?, Error?) -> Void)?) {
        var urlString = "\(request.domain)/\(request.path)"
        guard let accessToken = token else { return }

        var urlRequest: URLRequest
        if request.method == .get {
            urlString += "?"
            for (key, value) in request.params {
                if let array = value as? [Any] {
                    for element in array {
                        urlString += "&\(key)[]=\(element)"
                    }
                } else {
                    urlString += "&\(key)=\(value)"
                }
            }
            let url = URL(string: urlString)!
            urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
        } else {
            let url = URL(string: urlString)!
            urlRequest = URLRequest(url: url)
            if request.method == .delete {
                urlRequest.httpMethod = "DELETE"
            } else if request.method == .post {
                urlRequest.httpMethod = "POST"
            } else {
                fatalError("Unsupported HTTP Method!")
            }

            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            try! urlRequest.httpBody = JSONSerialization.data(withJSONObject: request.params,
                                                              options: JSONSerialization.WritingOptions.init(rawValue: 0))
        }

        urlRequest.setValue(accessToken.tokenString, forHTTPHeaderField: "X-Token")
        let task = URLSession.shared.dataTask(with: urlRequest) {
            (data, response, error) in
            if let data = data {
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data,
                                                                    options: .allowFragments)
                    DispatchQueue.main.async {
                        completion?(jsonData, error)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion?([:], error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion?(nil, error)
                }
            }
        }
        task.resume()
    }

    public class func fetchImage(urlString: String, completionHandler: @escaping ((UIImage?, Error?) -> Void)) {
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

