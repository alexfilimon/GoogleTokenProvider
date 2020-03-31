# GoogleTokenProvider

Library for accessing google API.

Library is an addition to [SwiftConnection](https://github.com/alexfilimon/SwiftConnection) library.

Credential file should be in format:

```json
{
    "client_id": "some_client_id",
    "authorize_url": "https://accounts.google.com/o/oauth2/auth",
    "token_url": "https://oauth2.googleapis.com/token",
    "client_secret": "client_secret",
    "callback": "/google/callback"
}
```
