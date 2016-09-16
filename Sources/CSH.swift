import Turnstile
import TurnstileWeb
import Foundation

public class CSH: OAuth2, Realm {
  static let baseURL = URL(string: "https://sso.csh.rit.edu/auth/realms/csh/protocol/openid-connect")!
  
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
    case let credentials as AccessToken:
      return try authenticate(credentials: credentials)
    default:
      throw UnsupportedCredentialsError()
    }
  }
  
  /// Authenticates a CSH access token.
  public func authenticate(credentials: AccessToken) throws -> CSHAccount {
    let url = CSH.baseURL.appendingPathComponent("userinfo")
    var request = URLRequest(url: url)
    request.setValue("Bearer: \(credentials.string)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    guard let data = (try? urlSession.executeRequest(request: request))?.0 else {
      throw APIConnectionError()
    }
    
    guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
      throw InvalidAPIResponse()
    }
    
    guard let uuid = json["sub"] as? String,
          let username = json["preferred_username"] as? String,
          let commonName = json["name"] as? String else {
        throw IncorrectCredentialsError()
    }
    return CSHAccount(uuid: uuid, username: username, commonName: commonName)
  }
}

public struct CSHAccount {
  public let uuid: String
  public let username: String
  public let commonName: String
}
