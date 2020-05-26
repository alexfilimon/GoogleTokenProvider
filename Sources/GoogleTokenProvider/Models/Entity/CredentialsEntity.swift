//
//  CredentialsEntity.swift
//  
//
//  Created by Alexander Filimonov on 29/02/2020.
//

import SwiftHash

struct CredentialsEntity: Codable {

    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case authUrl = "authorize_url"
        case tokenUrl = "token_url"
        case callback = "callback"
    }

    // MARK: - Computed Properties

    /// Value that unique identify different credentials (equal credentials have equal hashValues)
    var hashValue: String {
        return MD5(clientId + clientSecret)
    }

    // MARK: - Properties

    let clientId: String
    let clientSecret: String
    let authUrl: String
    let tokenUrl: String
    let callback: String

}
