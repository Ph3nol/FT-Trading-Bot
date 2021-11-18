#!/bin/bash

BASE_CONFIGS_DIRECTORY="${PWD}/configs"
BASE_INSTANCES_DIRECTORY="${PWD}/instances"
BASE_TMP_DIRECTORY="${PWD}/.tmp"
if [ ! -d "${BASE_CONFIGS_DIRECTORY}" ] || [ ! -d "${BASE_INSTANCES_DIRECTORY}" ]; then
    echo "🔴 [ERROR] You are not into a Freqtrade Trading instances directory"
    exit 1
fi

prepare() {
    DOCKER_FREQTRADE_IMAGE="ph3nol/freqtrade:latest"
    DOCKER_FREQTRADE_UI_IMAGE="ph3nol/freqtrade-ui:latest"
    DOCKER_CONTAINER_BASE_PREFIX="freqtrade-bot"

    DOCKER_RUN="docker run --rm -it"
    DOCKER_RUN_WITH_RESTART="docker run -d --restart=always -it"
    DOCKER_KILL="docker kill"
    DOCKER_RM="docker rm"

    if [[ `uname -m` == 'arm64' ]]; then
        DOCKER_RUN="${DOCKER_RUN} --platform linux/amd64"
    fi

    docker network create freqtrade-bots > /dev/null 2>&1

    CONFIGS_PRIVATE_DIRECTORY="${BASE_CONFIGS_DIRECTORY}/private"
    if [ ! -d "${CONFIGS_PRIVATE_DIRECTORY}" ]; then mkdir ${CONFIGS_PRIVATE_DIRECTORY}; fi
    if [[ "$(ls ${CONFIGS_PRIVATE_DIRECTORY} | wc -l)" -eq "0" ]]; then
        cp -r ${PWD}/.stubs/configs/private/* ${CONFIGS_PRIVATE_DIRECTORY}/
    fi
}

instance_create() {
    if [ -d "${INSTANCE_DIRECTORY}" ] || [ -f "${INSTANCE_CONFIG_FILE}" ]; then
        echo "🔴 [ERROR] ${INSTANCE} instance already exists"
        exit 1
    fi

    echo "Creating..."

    cp ${PWD}/.stubs/instances/stub.sh ${INSTANCE_CONFIG_FILE}
    echo "$(sed "2s/.*/FT_INSTANCE_NAME=\""${INSTANCE}"\"/" ${INSTANCE_CONFIG_FILE})" > ${INSTANCE_CONFIG_FILE}

    mkdir -p ${INSTANCE_DIRECTORY} ${INSTANCE_DIRECTORY}/user_data
    touch ${INSTANCE_CONFIG_FILE} \
        ${INSTANCE_DIRECTORY}/tradesv3.sqlite \
        ${INSTANCE_DIRECTORY}/tradesv3.dryrun.sqlite
    chmod -R 777 ${INSTANCE_DIRECTORY}
}

instance_remove() {
    if [ ! -d "${INSTANCE_DIRECTORY}" ]; then
        echo "🔴 [ERROR] ${INSTANCE} instance does not exist"
        exit 1
    fi

    echo "Removing..."
    rm -rf ${INSTANCE_DIRECTORY} ${INSTANCE_CONFIG_FILE}
}

instance_init() {
    echo "Initializing..."

    TMP_CONFIG_EXCHANGE_PAIRSLIST_FILE_NAME="${INSTANCE}.config.exchange.pairs.json"
    TMP_CONFIG_EXCHANGE_PAIRSLIST_FILE="${BASE_TMP_DIRECTORY}/${TMP_CONFIG_EXCHANGE_PAIRSLIST_FILE_NAME}"

    if [ ! -d "${INSTANCE_DIRECTORY}" ] || [ ! -f "${INSTANCE_CONFIG_FILE}" ]; then
        instance_create
    fi

    . ${INSTANCE_CONFIG_FILE}

    FT_CONFIGS_ARGS=""
    for CONFIG_FILE in "${FT_INSTANCE_CONFIGS[@]}"; do FT_CONFIGS_ARGS+="--config ${CONFIG_FILE} "; done

    VOLUMES=(
        "/etc/localtime:/etc/localtime:ro"
        "${BASE_CONFIGS_DIRECTORY}:/configs:ro"
        "${BASE_TMP_DIRECTORY}:/.tmp:ro"
        "${INSTANCE_DIRECTORY}/tradesv3.sqlite:/freqtrade/tradesv3.sqlite:rw"
        "${INSTANCE_DIRECTORY}/tradesv3.dryrun.sqlite:/freqtrade/tradesv3.dryrun.sqlite:rw"
        "${INSTANCE_DIRECTORY}/user_data:/freqtrade/user_data:rw"
        "${PWD}/strategies:/freqtrade/user_data/strategies:rw"
    )
    VOLUMES_ARGS=""
    for VOLUME in "${VOLUMES[@]}"; do VOLUMES_ARGS+="-v ${VOLUME} "; done

    ENVS=(
        "FREQTRADE__BOT_NAME=${FT_INSTANCE_NAME}"
        "FREQTRADE__DRY_RUN=${FT_DRY_RUN}"
        "FREQTRADE__DRY_RUN_WALLET=${FT_DRY_RUN_WALLET}"
    )
    ENVS_ARGS=""
    for ENV in "${ENVS[@]}"; do ENVS_ARGS+="-e ${ENV} "; done

    DOCKER_CONTAINER_BASE_NAME="${DOCKER_CONTAINER_BASE_PREFIX}-${INSTANCE}"
    DOCKER_CONTAINER_NAME="${DOCKER_CONTAINER_BASE_NAME}-${ACTION}"
}

instance_update_backtesting_pairlists() {
    echo "Updating backtesting pairlists..."

    PAIRS_LIST=$(
        ${DOCKER_RUN} --name ${DOCKER_CONTAINER_NAME}-update-backtesting-pairslist --network freqtrade-bots \
            ${VOLUMES_ARGS} ${ENVS_ARGS} \
            ${DOCKER_FREQTRADE_IMAGE} test-pairlist ${FT_CONFIGS_ARGS} --print-json
    )

    PAIRS_LIST=${PAIRS_LIST##*$'\n'}

cat << EOF > ${TMP_CONFIG_EXCHANGE_PAIRSLIST_FILE}
{
    "exchange": {
        "pair_whitelist": ${PAIRS_LIST}
    }
}
EOF
}

instance_stop() {
    echo "Stopping..."

    ${DOCKER_KILL} "${DOCKER_CONTAINER_BASE_NAME}-data-update-backtesting-pairslist" > /dev/null 2>&1
    ${DOCKER_RM} "${DOCKER_CONTAINER_BASE_NAME}-data-update-backtesting-pairslist" > /dev/null 2>&1
    ${DOCKER_KILL} "${DOCKER_CONTAINER_BASE_NAME}-pairs" > /dev/null 2>&1
    ${DOCKER_RM} "${DOCKER_CONTAINER_BASE_NAME}-pairs" > /dev/null 2>&1
    ${DOCKER_KILL} "${DOCKER_CONTAINER_BASE_NAME}-trade" > /dev/null 2>&1
    ${DOCKER_RM} "${DOCKER_CONTAINER_BASE_NAME}-trade" > /dev/null 2>&1
    ${DOCKER_KILL} "${DOCKER_CONTAINER_BASE_NAME}-data" > /dev/null 2>&1
    ${DOCKER_RM} "${DOCKER_CONTAINER_BASE_NAME}-data" > /dev/null 2>&1
    ${DOCKER_KILL} "${DOCKER_CONTAINER_BASE_NAME}-backtesting" > /dev/null 2>&1
    ${DOCKER_RM} "${DOCKER_CONTAINER_BASE_NAME}-backtesting" > /dev/null 2>&1
}

instance_init_backtesting() {
    echo "Initializing backtesting..."

    for CONFIG_BACKTEST_FILE in "${FT_INSTANCE_CONFIGS_BACKTESTING[@]}"; do FT_CONFIGS_ARGS+="--config ${CONFIG_BACKTEST_FILE} "; done

    if [ -f "${TMP_CONFIG_EXCHANGE_PAIRSLIST_FILE}" ]; then
        FT_CONFIGS_ARGS+="--config /.tmp/${TMP_CONFIG_EXCHANGE_PAIRSLIST_FILE_NAME} "
    fi
}

instance_display_informations() {
    echo ""

    if [[ ${FT_DRY_RUN} = "true" ]]; then
        DISPLAYED_MODE="😴 [DRY-RUN]"
    else
        DISPLAYED_MODE="🚀 [LIVE]"
    fi

    echo "${DISPLAYED_MODE} ${FT_INSTANCE_NAME} @ Port ${FT_API_SERVER_PORT}"
    echo "    • Strategy .................. ${FT_STRATEGY}"
    echo "    • Port ...................... ${FT_API_SERVER_PORT}"
    if [[ ${FT_DRY_RUN} -eq "true" ]]; then
    echo "    • Dry-run Wallet ............ ${FT_DRY_RUN_WALLET}"
    fi
}

ui_init() {
    echo "Initializing..."

    VOLUMES=(
        "/etc/localtime:/etc/localtime:ro"
    )
    VOLUMES_ARGS=""

    ENVS_ARGS=""

    DOCKER_CONTAINER_NAME="freqtrade-bot-ui"

    UI_PUBLIC_PORT="${ACTION_ARGS[0]:-22222}"
}

display_help() {
    echo "🤙 Trading Bot command usage:"
    echo ""
    echo "    ./`basename ${0}` instance <instance-name> create ...................... Create/Init an instance"
    echo "    ./`basename ${0}` instance <instance-name> trade ....................... Trade"
    echo "    ./`basename ${0}` instance <instance-name> pairs <quote> ............... List available exchange pairs"
    echo "    ./`basename ${0}` instance <instance-name> data <days-count> ........... Download data for backtests"
    echo "    ./`basename ${0}` instance <instance-name> backtesting <from-date> ..... Run backtest (<from-date> format: 20211102)"
    echo "    ./`basename ${0}` instance <instance-name> reset ....................... Reset instance data"
    echo "    ./`basename ${0}` instance <instance-name> remove ...................... Remove instance"
    echo ""
    echo "    ./`basename ${0}` ui start ............................................. Start UI"
    echo "    ./`basename ${0}` ui stop .............................................. Stop UI"
    echo ""
    echo "    — Note that you can use './`basename ${0}` i <...>' as an alias for './`basename ${0}` instance <...>'"
}

handle_instance() {
    case ${ACTION} in
        create)
            instance_create
            exit 0
            ;;
        remove)
            instance_remove
            exit 0
            ;;
        reset)
            instance_remove && instance_create
            exit 0
            ;;
        pairs)
            instance_init

            echo "Loading pairs..."
            ${DOCKER_RUN} --name ${DOCKER_CONTAINER_NAME} --network freqtrade-bots \
                ${VOLUMES_ARGS} ${ENVS_ARGS} \
                ${DOCKER_FREQTRADE_IMAGE} list-pairs ${FT_CONFIGS_ARGS} --quote ${ACTION_ARGS[0]} --print-json
            exit 0
            ;;
        trade)
            instance_init
            instance_stop > /dev/null 2>&1

            echo "Trading..."
            ${DOCKER_RUN_WITH_RESTART} --name ${DOCKER_CONTAINER_NAME} --network freqtrade-bots \
                ${VOLUMES_ARGS} ${ENVS_ARGS} -p ${FT_API_SERVER_PORT}:8080 \
                ${DOCKER_FREQTRADE_IMAGE} trade --strategy ${FT_STRATEGY} ${FT_CONFIGS_ARGS} \
                    > /dev/null 2>&1
            instance_display_informations
            exit 0
            ;;
        data)
            instance_init

            if [ "${ACTION_ARGS[1]}" = "" ]; then
                instance_update_backtesting_pairlists
            fi

            instance_init_backtesting

            echo "Downloading data..."

            if [ ! "${ACTION_ARGS[1]}" = "" ]; then
                ${DOCKER_RUN} --name ${DOCKER_CONTAINER_NAME} --network freqtrade-bots \
                    ${VOLUMES_ARGS} ${ENVS_ARGS} \
                    ${DOCKER_FREQTRADE_IMAGE} download-data ${FT_CONFIGS_ARGS} --days ${ACTION_ARGS[0]} -t {1m,5m,15m,1h,4h,1d} \
                        --pairs ${ACTION_ARGS[1]}
            else
                ${DOCKER_RUN} --name ${DOCKER_CONTAINER_NAME} --network freqtrade-bots \
                    ${VOLUMES_ARGS} ${ENVS_ARGS} \
                    ${DOCKER_FREQTRADE_IMAGE} download-data ${FT_CONFIGS_ARGS} --days ${ACTION_ARGS[0]} -t {1m,5m,15m,1h,4h,1d} \
                        --erase
            fi
            exit 0
            ;;
        backtesting)
            instance_init && instance_init_backtesting

            echo "Backtesting..."
            ${DOCKER_RUN} --name ${DOCKER_CONTAINER_NAME} --network freqtrade-bots \
                ${VOLUMES_ARGS} ${ENVS_ARGS} \
                ${DOCKER_FREQTRADE_IMAGE} backtesting --enable-protections --strategy ${FT_STRATEGY} ${FT_CONFIGS_ARGS}
            exit 0
            ;;
        stop)
            instance_init && instance_stop
            exit 0
            ;;
    *)
            display_help
            exit 1
            ;;
    esac
}

ui_start() {
    echo "Starting..."

    ${DOCKER_RUN_WITH_RESTART} --name ${DOCKER_CONTAINER_NAME} \
        ${VOLUMES_ARGS} ${ENVS_ARGS} -p ${UI_PUBLIC_PORT}:80 \
        ${DOCKER_FREQTRADE_UI_IMAGE} \
         > /dev/null 2>&1

    echo "Note: UI is available from http(s)://<your-ip-or-host>:${UI_PUBLIC_PORT}"
}

ui_stop() {
    echo "Stopping..."

    ${DOCKER_KILL} ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1
    ${DOCKER_RM} ${DOCKER_CONTAINER_NAME} > /dev/null 2>&1
}

handle_ui() {
    case ${ACTION} in
        start)
            ui_init && ui_start
            exit 0
            ;;
        stop)
            ui_init && ui_stop
            exit 0
            ;;
        *)
            display_help
            exit 1
            ;;
    esac
}

handle_list() {
    INSTANCES=$(docker ps --no-trunc -f "name=${DOCKER_CONTAINER_BASE_PREFIX}" | sed "1 d")
    # @todo To be continued
}

prepare

COMMAND="${1}"

case ${COMMAND} in
    list)
        handle_list
        exit 0
        ;;
    i | instance)
        INSTANCE="${2}"
        ACTION="${3}"
        ACTION_ARGS=(${@:4})
        if [ -z "${INSTANCE}" ] || [ -z "${ACTION}" ]; then
            display_help
            exit 1
        fi

        INSTANCE_DIRECTORY="${BASE_INSTANCES_DIRECTORY}/${INSTANCE}"
        INSTANCE_CONFIG_FILE="${BASE_INSTANCES_DIRECTORY}/${INSTANCE}.sh"

        handle_instance
        exit 0
        ;;
    ui)
        ACTION="${2}"
        ACTION_ARGS=(${@:3})
        if [ -z "${ACTION}" ]; then
            display_help
            exit 1
        fi

        handle_ui
        exit 0
        ;;
    help)
        display_help
        exit 0
        ;;
    *)
        display_help
        exit 1
        ;;
esac
