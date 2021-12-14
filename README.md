<img src="https://raw.githubusercontent.com/tardis-dev/mango-bowl/master/logo.svg">

[![Version](https://img.shields.io/npm/v/mango-bowl.svg?color=05aac5)](https://www.npmjs.org/package/mango-bowl)
[![Docker version](https://img.shields.io/docker/v/tardisdev/mango-bowl/latest?label=Docker&color=05aac5)](https://hub.docker.com/r/tardisdev/mango-bowl)

# mango-bowl: real-time WS market data API for Mango DEX

<br/>

## Why?

- **familiar experience for centralized exchanges APIs users**

  - **WebSocket API with Pub/Sub flow** - subscribe to selected channels and markets and receive real-time data as easy to parse JSON messages that can be consumed from any language supporting WebSocket protocol

  - **incremental L2 order book updates** - instead of decoding Mango market `asks` and `bids` accounts for each account change in order to detect order book updates, receive [initial L2 snapshot](#l2snapshot) and [incremental updates](#l2update) as JSON messages real-time over WebSocket connection

  - **tick-by-tick trades** - instead of decoding `eventQueue` account data which is quite large and in practice it's hard to consume real-time directly from Solana RPC node due to it's size, receive individual [`trade`](#trade) messages real-time over WebSocket connection

  - **real-time L3 data** - receive the most granular updates on individual order level: [`open`](#open), [`change`](#change), [`fill`](#fill) and [`done`](#done) messages for every order that Mango DEX processes

- **decreased load and bandwidth consumption for Solana RPC nodes hosts** - by providing real-time market data API via mango-bowl server instead of RPC node directly, hosts can decrease substantially both CPU load and bandwidth requirements as only mango-bowl will be direct consumer of RPC API when it comes to market data accounts changes and will efficiently normalize and broadcast small JSON messages to all connected clients

## What about placing/cancelling orders endpoints?

mango-bowl provides real-time market data only and does not include endpoints for placing/canceling or tracking own orders as that requires handling private keys which is currently out of scope of this project.

Both [microwavedcola1/mango-v3-service](https://github.com/microwavedcola1/mango-v3-service) and [@blockworks-foundation/mango-client](https://github.com/blockworks-foundation/mango-client-v3) provide such functionality and are recommended alternatives.

<br/>
<br/>

## Getting started

Run the code snippet below in the browser Dev Tools directly or in Node.js (requires installation of `ws` lib, [see](https://runkit.com/thad/mango-bowl-node-js-sample)).

```js
// connect to hosted demo server
const ws = new WebSocket('wss://api.mango-bowl.com/v1/ws')
// if connecting to mango-bowl server running locally
// const ws = new WebSocket('ws://localhost:8010/v1/ws')

ws.onmessage = (message) => {
  console.log(JSON.parse(message.data))
}

ws.onopen = () => {
  // subscribe both to trades and level2 real-time channels
  const subscribeTrades = {
    op: 'subscribe',
    channel: 'trades',
    markets: ['MNGO-PERP', 'SOL-PERP']
  }

  const subscribeL2 = {
    op: 'subscribe',
    channel: 'level2',
    markets: ['MNGO-PERP', 'SOL-PERP']
  }

  ws.send(JSON.stringify(subscribeTrades))
  ws.send(JSON.stringify(subscribeL2))
}
```

[![Try this code live on RunKit](https://img.shields.io/badge/-Try%20this%20code%20live%20on%20RunKit-c?color=05aac5)](https://runkit.com/thad/mango-bowl-node-js-sample)

<br/>
<br/>

## Using public hosted server

Mango-bowl public hosted WebSocket server (backed by Project Serum RPC node) is available at:

<br/>

[wss://api.mango-bowl.com/v1/ws](wss://api.mango-bowl.com/v1/ws)

<br/>
<br/>

## Installation

---

# IMPORTANT NOTE

For the best mango-bowl data reliability it's advised to [set up a dedicated Solana RPC node](https://docs.solana.com/running-validator) and connect `mango-bowl` to it instead of default `https://solana-api.projectserum.com` which may rate limit or frequently restart Websocket RPC connections since it's a public node used by many.

---

<br/>
<br/>

### npx <sub>(requires Node.js >= 15 and git installed on host machine)</sub>

Installs and starts mango-bowl server running on port `8000`.

```sh
npx mango-bowl
```

If you'd like to switch to different Solana RPC node endpoint like for example local one, change port or run with debug logs enabled, just add one of the available CLI options.

```sh
npx mango-bowl --endpoint http://localhost:8090 --ws-endpoint-port 8899 --log-level debug --port 8900
```

Alternatively you can install mango-bowl globally.

```sh
npm install -g mango-bowl
mango-bowl
```

<br/>

#### CLI options

| &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; name &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | default                             | description                                                                                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `port`                                                                                                                                                                                                                                                                                                  | 8010                                | Port to bind server on                                                                                                                                                                             |
| `endpoint`                                                                                                                                                                                                                                                                                              | https://solana-api.projectserum.com | Solana RPC node endpoint that mango-bowl uses as a data source                                                                                                                                     |
| `ws-endpoint-port`                                                                                                                                                                                                                                                                                      | -                                   | Optional Solana RPC WS node endpoint port that mango-bowl uses as a data source (if different than REST endpoint port) source                                                                      |
| `log-level`                                                                                                                                                                                                                                                                                             | info                                | Log level, available options: debug, info, warn and error                                                                                                                                          |
| `minions-count`                                                                                                                                                                                                                                                                                         | 1                                   | [Minions worker threads](#architecture) count that are responsible for broadcasting normalized WS messages to connected clients                                                                    |
| `commitment`                                                                                                                                                                                                                                                                                            | confirmed                           | [Solana commitment level](https://docs.solana.com/developing/clients/jsonrpc-api#configuring-state-commitment) to use when communicating with RPC node, available options: confirmed and processed |
| `group-name`                                                                                                                                                                                                                                                                                            | mainnet.1                           | Config group name to load Mango perp markets from                                                                                                                                                  |

<br/>

Run `npx mango-bowl --help` to see all available startup options.

<br/>
<br/>

### Docker

Pulls and runs latest version of [`tardisdev/mango-bowl` Docker Image](https://hub.docker.com/r/tardisdev/mango-bowl) on port `8010`.

```sh
docker run -p 8010:8010 -d tardisdev/mango-bowl:latest
```

If you'd like to switch to different Solana RPC node endpoint, change port or run with debug logs enabled, just specify those via one of the available env variables.

```sh
docker run -p 8010:8010 -e "MB_LOG_LEVEL=debug" -d tardisdev/mango-bowl:latest
```

<br/>

#### ENV Variables

| &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; name &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | default                             | description                                                                                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MB_PORT`                                                                                                                                                                                                                                                                                               | 8010                                | Port to bind server on                                                                                                                                                                             |
| `MB_ENDPOINT`                                                                                                                                                                                                                                                                                           | https://solana-api.projectserum.com | Solana RPC node endpoint that mango-bowl uses as a data source                                                                                                                                     |
| `MB_WS_ENDPOINT_PORT`                                                                                                                                                                                                                                                                                   | -                                   | Optional Solana RPC WS node endpoint port that mango-bowl uses as a data source (if different than REST endpoint port) source                                                                      |
| `MB_LOG_LEVEL`                                                                                                                                                                                                                                                                                          | info                                | Log level, available options: debug, info, warn and error                                                                                                                                          |
| `MB_MINIONS_COUNT`                                                                                                                                                                                                                                                                                      | 1                                   | [Minions worker threads](#architecture) count that are responsible for broadcasting normalized WS messages to connected clients                                                                    |
| `MB_COMMITMENT`                                                                                                                                                                                                                                                                                         | confirmed                           | [Solana commitment level](https://docs.solana.com/developing/clients/jsonrpc-api#configuring-state-commitment) to use when communicating with RPC node, available options: confirmed and processed |
| `MB_GROUP_NAME`                                                                                                                                                                                                                                                                                         | mainnet.1                           | Config group name to load Mango perp markets from                                                                                                                                                  |

<br/>
<br/>

### SSL/TLS Support

Mango-bowl supports [SSL/TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) but it's not enabled by default. In order to enable it you need to set `CERT_FILE_NAME` env var pointing to the certificate file and `KEY_FILE_NAME` pointing to private key of that certificate.

<br/>
<br/>

## WebSocket API

WebSocket API provides real-time market data feeds of Mango Markets DEX and uses a bidirectional protocol which encodes all messages as JSON objects.

<br/>

### Endpoint URL

- **[ws://localhost:8010/v1/ws](ws://localhost:8010/v1/ws)** - assuming mango-bowl runs locally on default port without SSL enabled

- **[wss://api.mango-bowl.dev/v1/ws](wss://api.mango-bowl.dev/v1/ws)** - demo mango-bowl server endpoint

<br/>

### Subscribing to data feeds

To begin receiving real-time market data feed messages, you must first send a subscribe message to the server indicating [channels](#supported-channels--corresponding-message-types) and [markets](#supported-markets) for which you want the data for.

If you want to unsubscribe from channel and markets, send an unsubscribe message. The structure is equivalent to subscribe messages except `op` field which should be set to `"op": "unsubscribe"`.

```js
const ws = new WebSocket('ws://localhost:8010/v1/ws')

ws.onopen = () => {
  const subscribeL2 = {
    op: 'subscribe',
    channel: 'trades',
    markets: ['SOL-PERP', 'MNGO-PERP']
  }

  ws.send(JSON.stringify(subscribeL2))
}
```

<br/>

#### Subscribe/unsubscribe message format

- see [supported channels & corresponding data messages types](#supported-channels--corresponding-message-types)
- see [supported markets](#supported-markets)

```ts
{
  "op": "subscribe" | "unsubscribe",
  "channel": "level3" | "level2" | "level1" | "trades",
  "markets": string[]
}
```

##### sample `subscribe` message

```json
{
  "op": "subscribe",
  "channel": "level2",
  "markets": ["SOL-PERP", "MNGO-PERP"]
}
```

<br/>

#### Subscription confirmation message format

Once a subscription (or unsubscription) request is processed by the server, it will push `subscribed` (or `unsubscribed`) confirmation message or `error` if received request message was invalid.

```ts
{
"type": "subscribed" | "unsubscribed",
"channel": "level3" | "level2" | "level1" | "trades",
"markets": string[],
"timestamp": string
}
```

##### sample `subscribed` confirmation message

```json
{
  "type": "subscribed",
  "channel": "level2",
  "markets": ["SOL-PERP"],
  "timestamp": "2021-12-14T11:06:30.010Z"
}
```

<br/>

#### Error message format

Error message is pushed for invalid subscribe/unsubscribe messages - non existing market, invalid channel name etc.

```ts
{
  "type": "error",
  "message": "string,
  "timestamp": "string
}
```

##### sample `error` message

```json
{
  "type": "error",
  "message": "Invalid channel provided: 'levels1'.",
  "timestamp": "2021-12-14T07:12:11.110Z"
}
```

<br/>
<br/>

### Supported channels & corresponding message types

When subscribed to the channel, server will push the data messages as specified below.

- `trades`

  - [`recent_trades`](#recent_trades)
  - [`trade`](#trade)

- `level1`

  - [`quote`](#quote)

- `level2`

  - [`l2snapshot`](#l2snapshot)
  - [`l2update`](#l2update)

- `level3`

  - [`l3snapshot`](#l3snapshot)
  - [`open`](#open)
  - [`fill`](#fill)
  - [`change`](#change)
  - [`done`](#done)

<br/>
<br/>

### Supported markets

Markets supported by mango-bowl server can be queried via [`GET /markets`](#get-markets) HTTP endpoint (`[].name` field).

<br/>
<br/>

### Data messages

- `type` is determining message's data type so it can be handled appropriately

- `timestamp` when message has been received from node RPC API in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format with milliseconds, for example: "2021-12-14T07:03:03.994Z"

- `slot` is a [Solana's slot](https://docs.solana.com/terminology#slot) number for which message has produced

- `version` of Serum DEX program layout (DEX version)

- `price` and `size` are provided as strings to preserve precision

- `eventTimestamp` is a timestamp of event provided by DEX (with seconds precision) in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601), for example: "2021-12-14T07:03:03.000Z"

<br/>
