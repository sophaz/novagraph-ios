//
//  Novanet.swift
//  Novagraph
//
//  Created by Christopher Wilson on 1/10/19.
//

import Alamofire

struct NetworkRequest {
    let method: HTTPMethod
    let path: String
    let params: [String: Any]
    let domain: String

    static var defaultDomain: String = ""

    init(method: HTTPMethod, path: String, params: [String: Any] = [:], domain: String = NetworkRequest.defaultDomain) {
        self.method = method
        self.path = path
        self.params = params
        self.domain = domain
    }
}

class Novanet {
    func send(request: NetworkRequest, completion: ((Any?, Error?) -> Void)?) {
        let urlString = "\(request.domain)/\(request.path)"
        CognitoService.shared?.currentAccessToken({ (token) in
            guard let accessToken = token else {
                completion?(nil, NSError())
                return
            }
            let header: HTTPHeaders = ["X-Token": accessToken.tokenString, "Content-Type": "application/json"]
            let queryDict = request.params
            Alamofire.request(urlString, method: request.method, parameters: queryDict,
                encoding: JSONEncoding.default, headers: header).responseJSON { response in
                    completion?(response.result.value, response.error)
            }
        })
    }
}
