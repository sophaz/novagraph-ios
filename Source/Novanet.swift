//
//  Novanet.swift
//  Novagraph
//
//  Created by Christopher Wilson on 1/10/19.
//

import Alamofire

public struct NovaRequest {
    let method: HTTPMethod
    let path: String
    let domain: String
    let requiresAuth: Bool
    let encoding: ParameterEncoding

    public var headers: HTTPHeaders
    public var params: Parameters

    public static var defaultDomain: String = ""

    public init(method: HTTPMethod,
         path: String,
         params: Parameters = [:],
         domain: String = NovaRequest.defaultDomain,
         headers: HTTPHeaders = ["Content-Type": "application/json"],
         requiresAuth: Bool = true) {
        self.method = method
        self.path = path
        self.params = params
        self.domain = domain
        self.requiresAuth = requiresAuth
        self.headers = headers
        self.encoding = method == .get ? URLEncoding.default : JSONEncoding.default
    }
}

public class Novanet {
    public static let shared = Novanet()

    public func send(request: NovaRequest, completion: ((Any?, Error?) -> Void)?) {
        var request = request
        if request.requiresAuth {
            CognitoService.shared?.currentAccessToken({ (token) in
                guard let accessToken = token else {
                    completion?(nil, NSError())
                    return
                }
                request.headers["X-Token"] = accessToken.tokenString
                self.sendAlamo(request: request, completion: { (value, error) in
                    completion?(value, error)
                })
            })
        } else {
            self.sendAlamo(request: request, completion: { (value, error) in
                completion?(value, error)
            })
        }
    }

    private func sendAlamo(request: NovaRequest, completion: ((Any?, Error?) -> Void)?) {
        let urlString = "\(request.domain)/\(request.path)"
        Alamofire.request(urlString,
                          method: request.method,
                          parameters: request.params,
                          encoding: request.encoding,
                          headers: request.headers).responseJSON { response in
                            completion?(response.result.value, response.error)
        }
    }
}
