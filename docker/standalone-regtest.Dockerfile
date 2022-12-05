# syntax=docker/dockerfile:1

FROM node:16-bullseye as api-builder

ARG API_GIT_COMMIT=b28c74490e923a0e80f865ccfd6c16ac6f2e2dd8
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /api

# Fetch API repo
SHELL ["/bin/bash", "-ce"]
RUN <<EOF
  echo "Building stacks-blockchain-api from commit: https://github.com/hirosystems/stacks-blockchain-api/commit/$API_GIT_COMMIT"
  git init
  git remote add origin https://github.com/hirosystems/stacks-blockchain-api.git
  git -c protocol.version=2 fetch --depth=1 origin "$API_GIT_COMMIT"
  git reset --hard FETCH_HEAD
  git fetch --all --tags
EOF

# Build API
RUN rm ".env" && \
    git describe --tags --abbrev=0 || git -c user.name='user' -c user.email='email' tag vNext && \
    echo "GIT_TAG=$(git tag --points-at HEAD)" >> .env && \
    npm config set update-notifier false && \
    npm config set unsafe-perm true && \
    npm ci --audit=false && \
    npm run build && \
    npm prune --production

FROM rust:bullseye as blockchain-builder

ARG BLOCKCHAIN_GIT_COMMIT=748eff4a8ad01aa63611f530813f1f19fbbb25e5
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /stacks

SHELL ["/bin/bash", "-ce"]
RUN <<EOF
  echo "Building stacks-node from commit: https://github.com/stacks-network/stacks-blockchain/commit/$BLOCKCHAIN_GIT_COMMIT"
  git init
  git remote add origin https://github.com/stacks-network/stacks-blockchain.git
  git -c protocol.version=2 fetch --depth=1 origin "$BLOCKCHAIN_GIT_COMMIT"
  git reset --hard FETCH_HEAD
  CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build --package stacks-node --bin stacks-node --release
EOF

FROM debian:bullseye-backports

COPY --from=blockchain-builder /stacks/target/release/stacks-node /usr/local/bin/
COPY --from=api-builder /api /api
COPY --from=ruimarinho/bitcoin-core:0.21.1 /opt/bitcoin-*/bin /usr/local/bin

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y curl/bullseye-backports gettext-base jq gosu

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

RUN echo "deb http://apt.postgresql.org/pub/repos/apt `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && apt-get -y install postgresql-14

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /chainstate

# Stacks API
EXPOSE 3700
# Stacks-node RPC
EXPOSE 20443
# Bitcoind JSON-RPC
EXPOSE 18443
# Postgres
EXPOSE 5490

ENV STACKS_BLOCKCHAIN_API_PORT=3999
ENV STACKS_BLOCKCHAIN_API_HOST=0.0.0.0
ENV STACKS_CORE_EVENT_PORT=3700
ENV STACKS_CORE_EVENT_HOST=127.0.0.1
ENV STACKS_CORE_RPC_HOST=127.0.0.1
ENV STACKS_CORE_RPC_PORT=20443
ENV STACKS_CHAIN_ID=0x80000000
# Levels: error, warn, info, http, verbose, debug
ENV STACKS_API_LOG_LEVEL=http 
ENV NODE_ENVIRONMENT=production
ENV BTC_FAUCET_PK=9e446f6b0c6a96cf2190e54bcd5a8569c3e386f091605499464389b8d4e0bfc201

ENV PGDATA=/chainstate/postgres
ENV PG_DATABASE=postgres
ENV PG_HOST=127.0.0.1
ENV PG_PORT=5432
ENV PG_USER=postgres
ENV PG_PASSWORD=postgres

ENV BTC_ADDR=miEJtNKa3ASpA19v5ZhvbKTEieYjLpzCYT
ENV MINER_SEED=9e446f6b0c6a96cf2190e54bcd5a8569c3e386f091605499464389b8d4e0bfc201
ENV BITCOIN_PEER_HOST=localhost
ENV BITCOIN_PEER_PORT=18444
ENV BITCOIN_RPC_PORT=18443
ENV BITCOIN_RPC_USER=btc
ENV BITCOIN_RPC_PASS=btc

ENV STACKS_LOG_TRACE=0
ENV STACKS_LOG_DEBUG=0

ARG MINE_INTERVAL=0.5s
ENV MINE_INTERVAL=$MINE_INTERVAL

ARG STACKS_20_HEIGHT=100
ENV STACKS_20_HEIGHT=$STACKS_20_HEIGHT

ARG STACKS_2_05_HEIGHT=101
ENV STACKS_2_05_HEIGHT=$STACKS_2_05_HEIGHT

ARG STACKS_21_HEIGHT=102
ENV STACKS_21_HEIGHT=$STACKS_21_HEIGHT

ARG STACKS_POX2_HEIGHT=102
ENV STACKS_POX2_HEIGHT=$STACKS_POX2_HEIGHT

# priv: 6ad9cadb42d4edbfbe0c5bfb3b8a4125ddced021c4174f829b714ccbf527f02001
# ARG REWARD_RECIPIENT=STQM73RQC4EX0A07KWG1J5ECZJYBZS4SJ4ERC6WN
ARG REWARD_RECIPIENT
ENV REWARD_RECIPIENT=$REWARD_RECIPIENT

COPY <<EOF /root/.bitcoin/bitcoin.conf
regtest=1 #chain=regtest
[regtest]
printtoconsole=1
disablewallet=0
txindex=1
coinstatsindex=1
blocksdir=/chainstate/bitcoin-data
datadir=/chainstate/bitcoin-data
discover=0
dns=0
dnsseed=0
listenonion=0
rpcserialversion=0
server=1
rest=1
rpcbind=0.0.0.0:18443
rpcallowip=0.0.0.0/0
rpcallowip=::/0
rpcuser=btc
rpcpassword=btc
addresstype=legacy
changetype=legacy
EOF

COPY <<EOF /root/config.toml.in
[node]
name = "krypton-node"
rpc_bind = "0.0.0.0:20443"
p2p_bind = "0.0.0.0:20444"
working_dir = "/chainstate/stacks-blockchain-data"
seed = "$MINER_SEED"
local_peer_seed = "$MINER_SEED"
miner = true
use_test_genesis_chainstate = true
pox_sync_sample_secs = 0
wait_time_for_blocks = 0
wait_time_for_microblocks = 50
microblock_frequency = 1000
[miner]
first_attempt_time_ms = 5000
subsequent_attempt_time_ms = 5000
$REWARD_RECIPIENT_CONF
[connection_options]
disable_block_download = true
disable_inbound_handshakes = true
disable_inbound_walks = true
public_ip_address = "1.1.1.1:1234"
[burnchain]
chain = "bitcoin"
mode = "krypton"
poll_time_secs = 1
pox_2_activation = $STACKS_POX2_HEIGHT
peer_host = "$BITCOIN_PEER_HOST"
peer_port = $BITCOIN_PEER_PORT
rpc_port = $BITCOIN_RPC_PORT
rpc_ssl = false
username = "$BITCOIN_RPC_USER"
password = "$BITCOIN_RPC_PASS"
timeout = 30
[[burnchain.epochs]]
epoch_name = "1.0"
start_height = 0
[[burnchain.epochs]]
epoch_name = "2.0"
start_height = $STACKS_20_HEIGHT
[[burnchain.epochs]]
epoch_name = "2.05"
start_height = $STACKS_2_05_HEIGHT
[[burnchain.epochs]]
epoch_name = "2.1"
start_height = $STACKS_21_HEIGHT
[[ustx_balance]]
address = "STB44HYPYAT2BB2QE513NSP81HTMYWBJP02HPGK6" # cb3df38053d132895220b9ce471f6b676db5b9bf0b4adefb55f2118ece2478df01
amount = 10000000000000000
[[ustx_balance]]
address = "ST11NJTTKGVT6D1HY4NJRVQWMQM7TVAR091EJ8P2Y" # 21d43d2ae0da1d9d04cfcaac7d397a33733881081f0b2cd038062cf0ccbb752601
amount = 10000000000000000
[[ustx_balance]]
address = "ST1HB1T8WRNBYB0Y3T7WXZS38NKKPTBR3EG9EPJKR" # c71700b07d520a8c9731e4d0f095aa6efb91e16e25fb27ce2b72e7b698f8127a01
amount = 10000000000000000
[[ustx_balance]]
address = "STRYYQQ9M8KAF4NS7WNZQYY59X93XEKR31JP64CP" # e75dcb66f84287eaf347955e94fa04337298dbd95aa0dbb985771104ef1913db01
amount = 10000000000000000
[[ustx_balance]]
address = "STF9B75ADQAVXQHNEQ6KGHXTG7JP305J2GRWF3A2" # ce109fee08860bb16337c76647dcbc02df0c06b455dd69bcf30af74d4eedd19301
amount = 10000000000000000
[[ustx_balance]]
address = "ST18MDW2PDTBSCR1ACXYRJP2JX70FWNM6YY2VX4SS" # 08c14a1eada0dd42b667b40f59f7c8dedb12113613448dc04980aea20b268ddb01
amount = 10000000000000000
EOF

WORKDIR /root

# Setup postgres
SHELL ["/bin/bash", "-ce"]
RUN <<EOF
  mkdir -p "$PGDATA"
  chown -R postgres:postgres "$PGDATA"
  gosu postgres /usr/lib/postgresql/14/bin/pg_ctl init -D "$PGDATA"
EOF

# Bootstrap chainstates
SHELL ["/bin/bash", "-ce"]
RUN <<EOF
  mkdir -p /chainstate/bitcoin-data
  bitcoind &
  BTCD_PID=$!
  bitcoin-cli -rpcwait getmininginfo
  bitcoin-cli createwallet ""
  bitcoin-cli importaddress $BTC_ADDR "" false
  bitcoin-cli generatetoaddress 99 $BTC_ADDR

  mkdir -p /chainstate/stacks-blockchain-data
  envsubst < config.toml.in > config.toml
  stacks-node start --config=config.toml &
  STACKS_PID=$!

  while true; do
    HEIGHT=$(curl -s localhost:20443/v2/info | jq '.burn_block_height')
    if [ "$HEIGHT" = "99" ]; then
      echo "Stacks node caught up to block 99"
      break
    fi
    sleep 0.5s
  done

  kill $STACKS_PID
  wait $STACKS_PID

  bitcoin-cli stop
  wait $BTCD_PID
EOF

# Create run script
RUN <<EOF
cat > run.sh <<'EOM'
#!/bin/bash -e
  if [[ ! -z "${REWARD_RECIPIENT}" ]]; then
    export REWARD_RECIPIENT_CONF="block_reward_recipient = \"$REWARD_RECIPIENT\""
  fi

  bitcoind &
  BTCD_PID=$!

  bitcoin-cli -rpcwait getmininginfo
  bitcoin-cli generatetoaddress 2 $BTC_ADDR

  export STACKS_EVENT_OBSERVER="127.0.0.1:3700"
  envsubst < config.toml.in > config.toml
  stacks-node start --config=config.toml &
  STACKS_PID=$!

  gosu postgres /usr/lib/postgresql/14/bin/pg_ctl start -W -D "$PGDATA"

  pushd /api
  node ./lib/index.js &
  API_PID=$!
  popd

  function start_miner() {
    while true; do
      TX=$(bitcoin-cli listtransactions '*' 1 0 true)
      CONFS=$(echo "$TX" | jq '.[].confirmations')
      if [ "$CONFS" = "0" ]; then
        echo "Detected Stacks mining mempool tx, mining btc block..."
        bitcoin-cli generatetoaddress 1 $BTC_ADDR
      fi
      sleep $MINE_INTERVAL
    done
  }
  start_miner &

  function cleanup() {
    echo "Exiting, signal: $1"
    kill $STACKS_PID 2>/dev/null && echo "Stacks exiting.."
    wait $STACKS_PID 2>/dev/null && echo "Stacks exited"
    kill $BTCD_PID 2>/dev/null && echo "Bitcoind exiting.."
    wait $BTCD_PID 2>/dev/null && echo "Bitcoind exited"
    kill $API_PID 2>/dev/null && echo "API exiting.."
    wait $API_PID 2>/dev/null && echo "API exited"
    echo "Postgres exiting.."
    gosu postgres /usr/lib/postgresql/14/bin/pg_ctl stop -W -D "$PGDATA" 2>/dev/null && echo "Postgres exited"
  }
  trap "cleanup SIGTERM" SIGTERM
  trap "cleanup SIGINT" SIGINT
  trap "cleanup SIGHUP" SIGHUP
  trap "cleanup EXIT" EXIT

  wait
EOM
chmod +x run.sh
EOF

CMD ["/root/run.sh"]
