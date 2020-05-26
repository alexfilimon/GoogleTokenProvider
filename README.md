# GoogleTokenProvider

Library for accessing google API.

Library is a Google OAuth 2.0 realization of `TokenProvider` for [SwiftConnection](https://github.com/alexfilimon/SwiftConnection).

## Integration

1. Install `GoogleTokenProvider` via SPM

```swift
.package(url: "https://github.com/alexfilimon/GoogleTokenProvider"),
```

2. Get Google credentials from cloud console and fill credentials file (uncommented file you can find in [attachments](#Credentials)):

```json
{
    // your data from cloud console
    "client_id": "some_client_id",
    "client_secret": "client_secret",

    // constants
    "authorize_url": "https://accounts.google.com/o/oauth2/auth", // url for auth in google
    "token_url": "https://oauth2.googleapis.com/token", // url for getting access token
    "callback": "/google/callback" // callback for local server
}
```

3. Pass `GoogleTokenProvider` in `Connection` initialization

```swift
import GoogleTokenProvider

let googleTokenProvider = try GoogleTokenProvider(
    scopes: ["https://www.googleapis.com/auth/drive"],
    credentialFilePath: "path_to_cred_path"
)
let connection = Connection(tokenProvider: googleTokenProvider)
// ...
```

## Resources

### Credentials

```json
{
    "client_id": "some_client_id",
    "client_secret": "client_secret",
    "authorize_url": "https://accounts.google.com/o/oauth2/auth",
    "token_url": "https://oauth2.googleapis.com/token",
    "callback": "/google/callback"
}
```
