# WiltCollector

[![Build Status](https://travis-ci.org/oliveroneill/WiltCollector.svg?branch=master)](https://travis-ci.org/oliveroneill/WiltCollector)
[![Platform](https://img.shields.io/badge/Swift-4.1-orange.svg)](https://img.shields.io/badge/Swift-4.1-orange.svg)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)


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
You'll need to set environment variables `BIGQUERY_PROJECT_ID`,
`SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` in the Lambda console.

### DynamoDB
You'll need to create two tables, one for user's play histories and
the other for a user's Spotify token info.

### Table Columns
play_history (BigQuery): user_id, date, artists, name, primary_artist, track_id

WiltUsers (DynamoDB): access_token, expires_at, refresh_token

## Dependency Issues
Unfortunately a number of dependencies don't seem to build on Linux
anymore. To solve this, I've used `swift package edit` and checked in
my changes.
- ProrsumNet: has an [open pull request](https://github.com/noppoMan/ProrsumNet)
to solve an issue with ambiguous subscripts.
- BigInt: The spaces in filenames caused the clang linker to break. Seems to be
an LLVM bug, see [here](https://forums.swift.org/t/no-spaces-allowed-during-building/15599).
