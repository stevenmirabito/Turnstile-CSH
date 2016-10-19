import Turnstile
import Auth
import TurnstileWeb
import Foundation

public class CSH: OAuth2, Realm {
    static let baseURL = URL(string: "https://sso.csh.rit.edu/realms/csh/protocol/openid-connect")!
    
    /// Create a CSH object. Uses the Client ID and Client Secret from the Config
    public convenience init(clientID: String, clientSecret: String) {
        let tokenURL = CSH.baseURL.appendingPathComponent("token")
        let authorizationURL = CSH.baseURL.appendingPathComponent("auth")
        self.init(clientID: clientID, clientSecret: clientSecret,
                  authorizationURL: authorizationURL, tokenURL: tokenURL)
    }
    
    /// Authenticates a CSH access token.
    public func authenticate(credentials: Credentials) throws -> Account {
        switch credentials {
        case let credentials as CSHAccount:
            return credentials
        case let credentials as Identifier:
            guard case .string(let value) = credentials.id,
                let account = CSHAccount(uniqueID: value) else {
                throw UnsupportedCredentialsError()
            }
            return account
        case let credentials as AccessToken:
            let account: CSHAccount = try authenticate(credentials: credentials)
            return account
        default:
            throw UnsupportedCredentialsError()
        }
    }
    
    /// Authenticates a CSH access token.
    public func authenticate(credentials: AccessToken) throws -> CSHAccount {
        let url = CSH.baseURL.appendingPathComponent("userinfo")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.string)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        guard let data = (try? urlSession.executeRequest(request: request))?.0 else {
            throw APIConnectionError()
        }
        
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            throw InvalidAPIResponse()
        }
        
        guard let uuid = json["uuid"] as? String,
            let username = json["preferred_username"] as? String,
            let commonName = json["name"] as? String else {
                throw IncorrectCredentialsError()
        }
        return CSHAccount(uuid: uuid, username: username, commonName: commonName)
    }
}

public struct CSHAccount: Account, Credentials {
    public let uuid: String
    public let username: String
    public let commonName: String
    
    public var uniqueID: String {
        let dict: [String: String] = [
            "uuid": uuid,
            "username": username,
            "commonName": commonName
        ]
        let json = try! JSONSerialization.data(withJSONObject: dict, options: [])
        return json.base64EncodedString()
    }
    
    init(uuid: String, username: String, commonName: String) {
        self.uuid = uuid
        self.username = username
        self.commonName = commonName
    }
    
    init?(uniqueID: String) {
        guard let data = Data(base64Encoded: uniqueID) else { return nil }
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: String] else {
            return nil
        }
        guard
            let uuid = json["uuid"],
            let username = json["username"],
            let commonName = json["commonName"] else {
                return nil
        }
        self.init(uuid: uuid, username: username, commonName: commonName)
    }
}
