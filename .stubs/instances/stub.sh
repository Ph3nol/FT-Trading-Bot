FT_DRY_RUN="true"
FT_INSTANCE_NAME=""
FT_STRATEGY="Example" # .......... Change with your wanted Strategy (must be into ./strategies folder, just give the name)
FT_API_SERVER_PORT="12345" # ......... Choose a unique and free port for each instance, and use http(s)://<host>:<port> from UI to connect to
FT_DRY_RUN_WALLET="500" # ............ Used for dry-run mode and backtesting

# Add some configuration files.
# USE ONLY CONFIGURATION PART YOU NEED.
# Private ones are to be updated with your private informations.

FT_INSTANCE_CONFIGS=(
    /configs/private/base.config.1.json
    # /configs/components/protections.json
    # /configs/private/strategy.params.json
    /configs/components/api.json
    # /configs/private/api.cors.json
    # /configs/private/api.json
    /configs/components/exchange.json
    /configs/private/exchange.binance.json # or other
    # /configs/components/exchange.pairs.volumes.binance.usdt.json # or other
    # /configs/components/telegram.json
    # /configs/private/telegram.json
    # /configs/components/do-not-run-at-start.json
)

# Add some configuration files for backesting

FT_INSTANCE_CONFIGS_BACKTESTING=(
    /configs/components/backtest.json
)
