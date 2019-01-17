//
//  CognitoService.swift
//  Novagraph
//
//  Created by Christopher Wilson on 1/8/19.
//

import AWSCognito
import AWSCognitoAuth
import AWSCognitoIdentityProvider

public struct ServerConfigurationDetails {
    let AWSRegion: AWSRegionType
    let CognitoClientID: String
    let CognitoClientSecret: String
    let CognitoPoolID: String
    let AWSCognitoPoolKey: String

    public init(AWSRegion: AWSRegionType,
                CognitoClientID: String, CognitoClientSecret: String,
                CognitoPoolID: String, AWSCognitoPoolKey: String) {
        self.AWSRegion = AWSRegion
        self.CognitoClientID = CognitoClientID
        self.CognitoClientSecret = CognitoClientSecret
        self.CognitoPoolID = CognitoPoolID
        self.AWSCognitoPoolKey = AWSCognitoPoolKey
    }
}

public struct AuthConfigurationDetails {
    let scopes: Set<String>
    let signInRedirectUri: String
    let signOutRedirectUri: String
    let webDomain: String
    let AWSCognitoAuthKey: String

    public init(scopes: Set<String>, signInRedirectUri: String, signOutRedirectUri: String,
                webDomain: String, AWSCognitoAuthKey: String) {
        self.scopes = scopes
        self.signInRedirectUri = signInRedirectUri
        self.signOutRedirectUri = signOutRedirectUri
        self.webDomain = webDomain
        self.AWSCognitoAuthKey = AWSCognitoAuthKey
    }
}

public class CognitoService {
    public static let shared = CognitoService()

    public let pool: AWSCognitoIdentityUserPool

    public var fbAuth: AWSCognitoAuth?
    public var googleAuth: AWSCognitoAuth?

    // User must set these before accessing the singleton to configure pool
    public static var serverConfigDetails: ServerConfigurationDetails?
    // User can optionally set these to configure FB/Google auth
    public static var fbConfigDetails: AuthConfigurationDetails?
    public static var googleConfigDetails: AuthConfigurationDetails?

    private init?() {
        guard let serverDetails = CognitoService.serverConfigDetails else { return nil }

        let serviceConfig = AWSServiceConfiguration(region: serverDetails.AWSRegion, credentialsProvider: nil)
        let poolConfig = AWSCognitoIdentityUserPoolConfiguration(clientId: serverDetails.CognitoClientID,
                                                                 clientSecret: serverDetails.CognitoClientSecret,
                                                                 poolId: serverDetails.CognitoPoolID)
        AWSCognitoIdentityUserPool.register(with: serviceConfig,
                                            userPoolConfiguration: poolConfig,
                                            forKey: serverDetails.AWSCognitoPoolKey)
        self.pool = AWSCognitoIdentityUserPool(forKey: serverDetails.AWSCognitoPoolKey)

        if let fbDetails = CognitoService.fbConfigDetails {
            let fbConfig = AWSCognitoAuthConfiguration(appClientId: serverDetails.CognitoClientID,
                                                            appClientSecret: serverDetails.CognitoClientSecret,
                                                            scopes: fbDetails.scopes,
                                                            signInRedirectUri: fbDetails.signInRedirectUri,
                                                            signOutRedirectUri: fbDetails.signOutRedirectUri,
                                                            webDomain: fbDetails.webDomain,
                                                            identityProvider: "Facebook",
                                                            idpIdentifier: nil,
                                                            userPoolIdForEnablingASF: serverDetails.CognitoPoolID)
            AWSCognitoAuth.registerCognitoAuth(with: fbConfig, forKey: fbDetails.AWSCognitoAuthKey)
            self.fbAuth = AWSCognitoAuth(forKey: fbDetails.AWSCognitoAuthKey)
        }

        if let googleDetails = CognitoService.googleConfigDetails {
            let config = AWSCognitoAuthConfiguration(appClientId: serverDetails.CognitoClientID,
                                                       appClientSecret: serverDetails.CognitoClientSecret,
                                                       scopes: googleDetails.scopes,
                                                       signInRedirectUri: googleDetails.signInRedirectUri,
                                                       signOutRedirectUri: googleDetails.signOutRedirectUri,
                                                       webDomain: googleDetails.webDomain,
                                                       identityProvider: "Google",
                                                       idpIdentifier: nil,
                                                       userPoolIdForEnablingASF: serverDetails.CognitoPoolID)
            AWSCognitoAuth.registerCognitoAuth(with: config, forKey: googleDetails.AWSCognitoAuthKey)
            self.fbAuth = AWSCognitoAuth(forKey: googleDetails.AWSCognitoAuthKey)
        }
    }

    public func currentAccessToken(_ completionHandler: @escaping (AWSCognitoIdentityUserSessionToken?) -> Void) {
        if let session = self.pool.currentUser()?.getSession() {
            session.continueWith { (session) -> Any? in
                completionHandler(session.result?.accessToken)
            }
        }
    }
}
