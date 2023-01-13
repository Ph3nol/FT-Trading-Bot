FT_DRY_RUN="true"
FT_INSTANCE_NAME=""
FT_STRATEGY="Example" # .......... Change with your wanted Strategy (must be into ./strategies folder, just give the name)
FT_API_SERVER_PORT="12345" # ......... Choose a unique and free port for each instance, and use http(s)://<host>:<port> from UI to connect to
FT_DRY_RUN_WALLET="500" # ............ Used for dry-run mode and backtesting

# Add some configuration files

FT_INSTANCE_CONFIGS=(
    /configs/private/main.json
    /configs/private/pairs.json
    # /configs/private/protections.json
    /configs/components/exchanges/binance/main.json # adapt to yours from `/configs/components/exchanges`
    /configs/components/exchanges/binance/blacklist.json # adapt to yours from `/configs/components/exchanges`
    /configs/components/exchanges/binance/pairlist.dynamic.busd.json # adapt to yours from `/configs/components/exchanges`
    /configs/private/exchange.json
    # /configs/private/api.json
    # /configs/private/telegram.json
    # /configs/private/strategies/example.json # put your strategies configs into `/configs/private/strategies`
    # /configs/components/settings/do-not-run-at-start.json
    # /configs/components/settings/enable-force-buy.json
)

# Add some configuration files for backesting

FT_INSTANCE_CONFIGS_BACKTESTING=(
    /configs/components/backtest.json
)
