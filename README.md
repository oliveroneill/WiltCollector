# WiltCollector

A program for periodically updating Wilt user's play histories.

This is intended to run on AWS Lambda using CloudWatch to trigger updates.

## Running tests
```bash
swift test
```

## Deploying
To build a packaged zip that contains the built program, run:
```bash
./deploy.sh
```
This will create a zip called `WiltCollector.zip` in `deploy/`.
This can then be uploaded to S3 and connected to Lambda. `index.js` is the
Lambda handler and currently logs all output from the Swift program and the
handler returns an empty string on completion.

The `deploy/` directory can be deleted at any time, it contains temporary
build items to make the S3 package.

## AWS Setup
### Lambda
You'll need to set environment variables `SPOTIFY_CLIENT_ID` and
`SPOTIFY_CLIENT_SECRET` in the Lambda console.

### DynamoDB
You'll need to create two tables, one for user's play histories and
the other for a user's Spotify token info.

### Table Columns
SpotifyHistory: user_id, date, artists, name, primary_artist, track_id

WiltUsers: access_token, expires_at, refresh_token
