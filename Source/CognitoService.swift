//
//  CognitoService.swift
//  Novagraph
//
//  Created by Christopher Wilson on 1/8/19.
//

import AWSCognito
import AWSCognitoAuth
import AWSCognitoIdentityProvider

public protocol CognitoConfigurationProtocol {
    var IdentityPoolID: String { get }
    var AWSAccountID: String { get }
    var AWSCognitoKey: String { get }
    var AWSRegion: AWSRegionType { get }
}

public protocol IdentityProviderProtocol: AWSIdentityProviderManager {
    func loginDict() -> [String: String]?
}

public class CognitoService {
    public private(set) static var shared: CognitoService!

    private let identityProvider: IdentityProviderProtocol
    private let credentialsProvider: AWSCognitoCredentialsProvider
    private let serverConfiguration: CognitoConfigurationProtocol
    private let identity: AWSCognitoIdentity
    private static let IdentityPoolUserIDKey = "IDENTITY_POOL_USER_ID_KEY"

    public static func setup(with identityProvider: IdentityProviderProtocol,
                             serverConfiguration: CognitoConfigurationProtocol) {
        CognitoService.shared = CognitoService(identityProvider: identityProvider,
                                               serverConfiguration: serverConfiguration)
    }

    private init?(identityProvider: IdentityProviderProtocol,
                  serverConfiguration: CognitoConfigurationProtocol) {
        self.identityProvider = identityProvider
        self.serverConfiguration = serverConfiguration
        credentialsProvider = AWSCognitoCredentialsProvider(regionType: serverConfiguration.AWSRegion,
                                                            identityPoolId: serverConfiguration.IdentityPoolID,
                                                            identityProviderManager: identityProvider)
        let identityConfiguration = AWSServiceConfiguration(region: serverConfiguration.AWSRegion,
                                                            credentialsProvider: credentialsProvider)!
        AWSCognitoIdentity.register(with: identityConfiguration, forKey: serverConfiguration.AWSCognitoKey)
        identity = AWSCognitoIdentity(forKey: serverConfiguration.AWSCognitoKey)
    }

    public func currentAccessToken(_ completionHandler: @escaping (String?, Error?) -> Void) {
        if let identityId = UserDefaults.standard.string(forKey: CognitoService.IdentityPoolUserIDKey) {
            let openIdInput = self.openIdInput(identityId: identityId)
            self.identity.getOpenIdToken(openIdInput).continueWith(block: { (response) -> Any? in
                if let result = response.result {
                    completionHandler(result.token, response.error)
                } else {
                    completionHandler(nil, response.error)
                }
                return nil
            })
        } else {
            completionHandler(nil, nil)
        }
    }

    // MARK: - Private

    private func idInput() -> AWSCognitoIdentityGetIdInput {
        let idInput = AWSCognitoIdentityGetIdInput()!
        idInput.accountId = serverConfiguration.AWSAccountID
        idInput.identityPoolId = serverConfiguration.IdentityPoolID
        idInput.logins = identityProvider.loginDict()
        return idInput
    }

    private func openIdInput(identityId: String) -> AWSCognitoIdentityGetOpenIdTokenInput {
        let openIDInput = AWSCognitoIdentityGetOpenIdTokenInput()!
        openIDInput.identityId = identityId
        openIDInput.logins = identityProvider.loginDict()
        return openIDInput
    }
}
