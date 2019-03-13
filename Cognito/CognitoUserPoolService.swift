//
//  CognitoUserPoolService.swift
//  Alamofire
//
//  Created by Sophie on 3/12/19.
//

import UIKit
import AWSCognito
import AWSCognitoAuth
import AWSCognitoIdentityProvider

public protocol CognitoUserPoolConfigurationProtocol {
    var UserPoolID: String { get }
    var UserPoolClientID: String { get }
    var UserPoolClientSecret: String { get }
    var AWSAccountID: String { get }
    var AWSCognitoKey: String { get }
    var AWSRegion: AWSRegionType { get }
}

public class CognitoUserPoolService: NSObject {
    public private(set) static var shared: CognitoUserPoolService!
    public let pool: AWSCognitoIdentityUserPool
    public let credentialsProvider: AWSCredentialsProvider

    public static func setup(with configuration: CognitoUserPoolConfigurationProtocol) {
        CognitoUserPoolService.shared = CognitoUserPoolService(with: configuration)
    }

    init(with configuration: CognitoUserPoolConfigurationProtocol) {
        let serviceConfig = AWSServiceConfiguration(region: configuration.AWSRegion, credentialsProvider: nil)
        let poolConfig = AWSCognitoIdentityUserPoolConfiguration(clientId: configuration.UserPoolClientID,
                                                                 clientSecret: configuration.UserPoolClientSecret,
                                                                 poolId: configuration.UserPoolID)
        let poolKey = configuration.AWSCognitoKey + "UserPool"
        AWSCognitoIdentityUserPool.register(with: serviceConfig,
                                            userPoolConfiguration: poolConfig,
                                            forKey: poolKey)
        self.pool = AWSCognitoIdentityUserPool(forKey: poolKey)
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: configuration.AWSRegion,
                                                                 identityPoolId: configuration.UserPoolID,
                                                                 identityProviderManager: self.pool)
    }
}
