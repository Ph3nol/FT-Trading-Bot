# Cryptocurrencies Trading Bot - Freqtrade Manager

This automated Trading Bot is based on the amazing [Freqtrade](https://www.freqtrade.io/en/latest/) one.
It allows you to manage many Freqtrade fully Dockerized instances and UI with ease.

## Features

* **Fast & easy deploy** 🚀
* Generate a new ready instance with 1 command line only
* Unlimited instances configurations from 1 file
* Many available public strategies, grabbed from multiple sources (Github, Discord, etc.)
* Many more is coming!

## DISCLAIMER

Do not risk money which you are afraid to lose. **USE THIS APPLICATION AT YOUR OWN RISK.** THE AUTHORS AND ALL AFFILIATES ASSUME NO RESPONSIBILITY ABOUT YOUR TRADING RESULTS.

## Installation

### Requirements

* A cryptocurrency exchange account, like [Binance](https://www.binance.com/fr/register?ref=69525434) or [Kucoin](https://www.kucoin.com/ucenter/signup?rcode=rJ4U44Y)
* [Docker](https://www.docker.com/) #CaptainObvious

### Get this Trading Bot

```
mkdir fq-trading-bot && cd fq-trading-bot
git clone https://github.com/Ph3nol/FT-Trading-Bot.git .
./b
```

### Configure & Customize

* Adapt basic private generated files into `./configs/private` — **of course you can add yours!**
* Use or add your best strategies into `./strategies` —  **feel free to open Pull Requests with your best ones!**

### Create and configure your first instance

Suppose you want to create an instance named `unicorn01`.

```
./b i unicorn01 create
```

* Configure your instance parameters from `./instances/unicorn01.sh`

## Usage

Just use `./b` from your Trading Bot directory.

## Thanks

![Thanks](https://media.giphy.com/media/PoImMjCPa8QaiBWJd0/giphy.gif)

You want to support this project?
You are using this project and you want to contribute?
Feeling generous?

* **BTC** -> `1MksZdEXqFwqNhEiPT5sLhgWijuCH42r9c`
* **ETH** (ERC20) -> `0x3167ddc7a6b47a0af1ce5270e067a70b997fd313`
* **BSC - Binance Smart Chain** (BEP20) -> `0x3167ddc7a6b47a0af1ce5270e067a70b997fd313`
* **Solana** (SOL) -> `DsftXATN6aQe5ppjByzQyJAQ2fJkZcN9UDF8HDiUY7iH`
* **TRX** (TRC20) -> `TVurVvbyXDzqTKhVXj1eq3U2T8UfVD4KsD`

## Development

![Development](https://media.giphy.com/media/fQZX2aoRC1Tqw/giphy.gif)

### (Re)Build reference Docker images

```
docker pull freqtradeorg/freqtrade:stable
docker buildx build --no-cache --push --platform linux/amd64 \
    --file .docker/freqtrade/Dockerfile \
    --tag ph3nol/freqtrade:latest .

# Update .docker/freqtrade-ui/Dockerfile UI archive version before building Docker image
docker buildx build --no-cache --push --platform linux/amd64 \
    --file .docker/freqtrade-ui/Dockerfile \
    --tag ph3nol/freqtrade-ui:latest .
```
