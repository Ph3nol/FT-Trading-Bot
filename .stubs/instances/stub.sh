FT_INSTANCE_NAME=""
FT_STRATEGY="SMAOffsetV2" # .......... Change with your wanted Strategy (see ./strategies folder)
FT_API_SERVER_PORT="12345" # ......... Choose a unique and free port for each instance, and use http(s)://<host>:<port> from UI to connect to
FT_DRY_RUN_WALLET="500" # ............ Used for dry-run mode and backtesting

# Add some configuration files.
# USE ONLY CONFIGURATION PART YOU NEED.
# Private ones are to be updated with your private informations.

FT_INSTANCE_CONFIGS=(
    /configs/components/base.json
    /configs/private/base.config.1.json
    /configs/components/api.json
    # /configs/private/api.json
    /configs/components/exchange.json
    /configs/private/exchange.kucoin.json
    # /configs/private/exchange.binance.json
    # /configs/components/telegram.json
    # /configs/private/telegram.json
)

# Add some configuration files for backesting

FT_INSTANCE_CONFIGS_BACKTESTING=(
    /configs/components/backtest.json
)
