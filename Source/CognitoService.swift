//
//  CognitoService.swift
//  Novagraph
//
//  Created by Christopher Wilson on 1/8/19.
//

import AWSCognito
import AWSCognitoIdentityProvider

public struct ServerConfigurationDetails {
    let region: AWSRegionType
    let clientID: String
    let clientSecret: String
    let poolID: String
    let poolKey: String

    public init(region: AWSRegionType,
                clientID: String, clientSecret: String,
                poolID: String, poolKey: String) {
        self.region = region
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.poolID = poolID
        self.poolKey = poolKey
    }
}

public class CognitoService {

    public static let shared = CognitoService()

    public let pool: AWSCognitoIdentityUserPool

    private static var CognitoClientID = ""
    private static var CognitoPoolID = ""
    private static var AWSRegion: AWSRegionType = .Unknown
    private static var CognitoClientSecret = ""
    private static var AWSCognitoPoolKey = ""

    private init() {
        let serviceConfig = AWSServiceConfiguration(region: CognitoService.AWSRegion, credentialsProvider: nil)
        let poolConfig = AWSCognitoIdentityUserPoolConfiguration(clientId: CognitoService.CognitoClientID,
                                                                 clientSecret: CognitoService.CognitoClientSecret,
                                                                 poolId: CognitoService.CognitoPoolID)
        AWSCognitoIdentityUserPool.register(with: serviceConfig,
                                            userPoolConfiguration: poolConfig,
                                            forKey: CognitoService.AWSCognitoPoolKey)
        self.pool = AWSCognitoIdentityUserPool(forKey: CognitoService.AWSCognitoPoolKey)
    }

    public class func configure(with serverConfigurationDetails: ServerConfigurationDetails) {
        CognitoService.CognitoClientID = serverConfigurationDetails.clientID
        CognitoService.CognitoPoolID = serverConfigurationDetails.poolID
        CognitoService.CognitoClientSecret = serverConfigurationDetails.clientSecret
        CognitoService.AWSCognitoPoolKey = serverConfigurationDetails.poolKey
        CognitoService.AWSRegion = serverConfigurationDetails.region
    }

    public func currentAccessToken(_ completionHandler: @escaping (AWSCognitoIdentityUserSessionToken?) -> Void) {
        if let session = self.pool.currentUser()?.getSession() {
            session.continueWith { (session) -> Any? in
                completionHandler(session.result?.accessToken)
            }
        }
    }

}
