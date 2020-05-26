//
//  GoogleTokenProvider.swift
//  
//
//  Created by Alexander Filimonov on 14/02/2020.
//

import Foundation
import Dispatch
import PathKit
import Swifter
import SwiftConnection

/// Class for authorizing through google OAuth 2.0
public final class GoogleTokenProvider: TokenProvider {

    // MARK: - Constants

    private enum Constants {
        static let folderName = ".googleTokenProvider"
        static let tokenFileName = "token_info.json"
        static let serverPort = 8080
        static let localServerUrl = "http://localhost"

        static func getFullLocalServerUrlString(callbackPath: String) -> String {
            return localServerUrl + ":" + String(serverPort) + callbackPath
        }
    }

    // MARK: - Private Properties

    private let scopes: [String]
    private let credentialFilePath: Path
    private let shouldLog: Bool

    // MARK: - Initialization

    /// Base initialization
    /// - Parameters:
    ///   - scopes: array of scropes fpr auth
    ///   - credentialFilePath: path to file with credentials (must be valid path)
    ///   - shouldLog: if need log to console
    public init(scopes: [String],
                credentialFilePath: Path,
                shouldLog: Bool = false) throws {
        guard credentialFilePath.isFile else {
            throw GoogleTokenProviderError.couldntFindCredentials
        }
        self.scopes = scopes
        self.credentialFilePath = credentialFilePath
        self.shouldLog = shouldLog
    }

    // MARK: - TokenProvider

    /// Method for getting access token,
    /// - if there is no token, method requests auth from user
    /// - method loads token from local file and refreshes token if needed
    public func getToken() throws -> Token {
        // load credentials from path
        let credentials = try FileService<CredentialsEntity>(filePath: credentialFilePath).load()

        // load token from file
        guard let tokenEntity = try? getTokenFileService(credentials: credentials).load() else {
            // there is no token file -> first launch

            logIfNeeded(string: "File with tokens not found")

            // 1. auth app
            // 2. exchange token
            // 3. save token to file
            // 4. return success with access token

            logIfNeeded(string: "Starting auth app")

            let code = try authApp(credentials: credentials)
            let token = TokenEntity(from: try exchange(credentials: credentials, code: code))
            try getTokenFileService(credentials: credentials).save(content: token)

            logIfNeeded(string: "Successfully loaded token: \(token.tokenType) \(token.accessToken)")

            return .init(tokenType: token.tokenType,
                         accessToken: token.accessToken)
        }

        // token file exists

        logIfNeeded(string: "File with tokens exists")

        // 1. check is token valid
        // 2. if token is invalid
        //      - refresh
        //      - save new token in file
        // 3. return result to user

        let tokenValidator = TokenValidator(dateCreated: tokenEntity.creationTime,
                                            expiresSeconds: tokenEntity.expiresIn)
        if tokenValidator.isTokenValid() {
            logIfNeeded(string: "Token valid: \(tokenEntity.tokenType) \(tokenEntity.accessToken)")
            return .init(tokenType: tokenEntity.tokenType,
                         accessToken: tokenEntity.accessToken)
        } else {
            logIfNeeded(string: "Token is not valid")
            logIfNeeded(string: "Starting refreshing token")
            let newToken = TokenEntity(from: try refreshToken(token: tokenEntity,
                                                              credentials: credentials),
                                       refreshToken: tokenEntity.refreshToken)
            try getTokenFileService(credentials: credentials).save(content: newToken)
            logIfNeeded(string: "Token refreshed successfully: \(tokenEntity.tokenType) \(tokenEntity.accessToken)")
            return .init(tokenType: newToken.tokenType,
                         accessToken: newToken.accessToken)
        }

    }
    
}

// MARK: - Private Methods

private extension GoogleTokenProvider {

    /// Method for getting service for token file
    func getTokenFileService(credentials: CredentialsEntity) -> FileService<TokenEntity> {
        let tokenFileName = Path(String(credentials.hashValue) + "." + Constants.tokenFileName)
        let pathToTokenFile = Path.home + Constants.folderName + tokenFileName
        return FileService<TokenEntity>(filePath: pathToTokenFile)
    }

    /// Method for first auth application (open link in browser). Returns authorization code
    /// - Parameter credentials: credentials entity
    func authApp(credentials: CredentialsEntity) throws -> String {
        guard var urlComponents = URLComponents(string: credentials.authUrl) else {
            throw GoogleTokenProviderError.couldntCreateUrl
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: credentials.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Constants.getFullLocalServerUrlString(callbackPath: credentials.callback)),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "show_dialog", value: "false"),
            URLQueryItem(name: "access_type", value: "offline")
        ]
        let sm = DispatchSemaphore(value: 0)
        var code: CodeEntry?
        let server = try startServer(callbackName: credentials.callback) { codeEntry in
            sm.signal()
            code = codeEntry
        }
        openURL(urlComponents.url!)
        _ = sm.wait(timeout: .distantFuture)
        stopServer(server: server)

        // process error response entry
        if let error = code?.error {
            throw GoogleTokenProviderError.errorWhileGettingAuthCode(error)
        }
        guard let authCode = code?.code else {
            throw GoogleTokenProviderError.unknownErrorWhileGettingAuthCode
        }
        return authCode
    }

    /// Method for getting tokenEntry
    /// - Parameters:
    ///   - credentials: credentials entity
    ///   - code: authorization code
    func exchange(credentials: CredentialsEntity, code: String) throws -> TokenEntry {
        let params: [String: String] = [
            "client_id": credentials.clientId,
            "client_secret": credentials.clientSecret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": Constants.getFullLocalServerUrlString(callbackPath: credentials.callback)
        ]
        return try Connection(shouldLog: shouldLog)
            .performRequest(urlString: credentials.tokenUrl,
                            method: .post,
                            params: params)
    }

    /// Method for refreshing access token
    /// - Parameters:
    ///   - token: token entity
    ///   - credentials: credentials entity
    func refreshToken(token: TokenEntity, credentials: CredentialsEntity) throws -> TokenEntry {
        guard let refresh = token.refreshToken else {
            throw GoogleTokenProviderError.noRefreshToken
        }
        let params: [String: String] = [
            "client_id": credentials.clientId,
            "client_secret": credentials.clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": refresh
        ]
        return try Connection(shouldLog: shouldLog)
            .performRequest(urlString: credentials.tokenUrl,
                            method: .post,
                            params: params)
    }

    /// Method for starting local server
    /// - Parameters:
    ///   - callbackName: callback name to handle
    ///   - onCode: completion closure with code entry
    func startServer(callbackName: String, onCode: ((CodeEntry) -> Void)?) throws -> HttpServer {
        let server = HttpServer()
        server[callbackName] = { request in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
               onCode?(CodeEntry(queryParams: request.queryParams))
            }

            return HttpResponse.ok(.text("Success. You may close this page."))
        }
        try server.start(UInt16(Constants.serverPort))
        return server
    }

    /// Method for stopping server
    /// - Parameter server: server object
    func stopServer(server: HttpServer) {
        server.stop()
    }

    func logIfNeeded(string: String) {
        guard shouldLog else { return }
        print("\(Date()) [GoogleTokenProvider]: \(string)")
    }

}
