# serv00-nezha
serv00 install nezha and nezha agent

## nezha-agent

### 交互安装

```shell
bash -c "$(curl -sL https://raw.githubusercontent.com/muyiacc/serv00-nezha/main/nezha-agent.sh)" \
-- install
```

### 无交互安装
```shell
PANEL_ADDRESS="example:8008" \
SERVER_KEY="iK3Snw4Ev78MzM" \
ENABLE_TLS=false \
bash -c "$(curl -sL https://raw.githubusercontent.com/muyiacc/serv00-nezha/main/nezha-agent.sh)" \
-- install
```

指定 UUID

```shell
PANEL_ADDRESS="example:8008" \
SERVER_KEY="iK3Snw4Ev78MzM" \
ENABLE_TLS=false \
UUID="6c3fe883-055b-11f0-8047-3cecef19f58c" \
bash -c "$(curl -sL https://raw.githubusercontent.com/muyiacc/serv00-nezha/main/nezha-agent.sh)" \
-- install
```
