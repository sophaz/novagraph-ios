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
    func getLoginDict(completionHandler: @escaping (([String: String]?) -> Void))
}

/* This class represents a Cognito Identity Pool containing all of the
 different login providers we support */
public class CognitoService {
    public private(set) static var shared: CognitoService!

    private let identityProvider: IdentityProviderProtocol
    private let credentialsProvider: AWSCognitoCredentialsProvider
    private let serverConfiguration: CognitoConfigurationProtocol
    private let identity: AWSCognitoIdentity
    private static let IdentityPoolUserIDKey = "IDENTITY_POOL_USER_ID_KEY"
    private static let IdentityPoolOpenIDIDKey = "IDENTITY_POOL_OPENID_ID_KEY"

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

    public func signInToIdentityPool(completionHandler: @escaping (String?, Error?) -> Void) {
        credentialsProvider.clearKeychain()
        self.getIDInput { (input) in
            self.identity.getId(input).continueWith { (response) -> Any? in
                UserDefaults.standard.set(response.result?.identityId, forKey: CognitoService.IdentityPoolUserIDKey)
                self.currentAccessToken({ (tokenString, error) in
                    completionHandler(tokenString, error)
                })
                return nil
            }
        }
    }

    public func currentAccessToken(_ completionHandler: @escaping (String?, Error?) -> Void) {
        if let identityId = UserDefaults.standard.string(forKey: CognitoService.IdentityPoolUserIDKey) {
            if let openID = self.getValidOpenIDInputOrNil() {
                completionHandler(openID, nil)
            } else {
                self.openIdInput(identityId: identityId) { openIdInput in
                    self.identity.getOpenIdToken(openIdInput).continueWith(block: { (response) -> Any? in
                        if let result = response.result {
                            UserDefaults.standard.set(result.token, forKey: CognitoService.IdentityPoolOpenIDIDKey)
                            completionHandler(result.token, response.error)
                        } else {
                            completionHandler(nil, response.error)
                        }
                        return nil
                    })
                }
            }
        } else {
            completionHandler(nil, nil)
        }
    }

    public func signout() {
        UserDefaults.standard.setValue(nil, forKey: CognitoService.IdentityPoolUserIDKey)
        UserDefaults.standard.setValue(nil, forKey: CognitoService.IdentityPoolOpenIDIDKey)
    }

    // MARK: - Private

    private func getIDInput(completionHandler: @escaping ((AWSCognitoIdentityGetIdInput) -> Void)) {
        identityProvider.getLoginDict { (loginDict) in
            let idInput = AWSCognitoIdentityGetIdInput()!
            idInput.accountId = self.serverConfiguration.AWSAccountID
            idInput.identityPoolId = self.serverConfiguration.IdentityPoolID
            idInput.logins = loginDict
            completionHandler(idInput)
        }
    }

    private func openIdInput(identityId: String,
                             completionHandler: @escaping ((AWSCognitoIdentityGetOpenIdTokenInput) -> Void)) {
        identityProvider.getLoginDict { (loginDict) in
            let openIDInput = AWSCognitoIdentityGetOpenIdTokenInput()!
            openIDInput.identityId = identityId
            openIDInput.logins = loginDict
            completionHandler(openIDInput)
        }
    }

    private func getValidOpenIDInputOrNil() -> String? {
        if let cachedOpenId = UserDefaults.standard.string(forKey: CognitoService.IdentityPoolOpenIDIDKey) {
            if let jsonData = cachedOpenId.convertFromOpenIdToData(),
                let exp = jsonData["exp"] as? Double {
                let expirationDate = Date(timeIntervalSince1970: exp)
                let oneMinuteFromNow = Date().addingTimeInterval(60)
                if expirationDate > oneMinuteFromNow {
                    return cachedOpenId
                }
            }
        }
        return nil
    }
}
