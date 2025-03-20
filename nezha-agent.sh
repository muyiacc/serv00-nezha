#!/bin/sh

NEZHA_DIR="${NEZHA_DIR:-$HOME/.nezha}"
NEZHA_TMP_DIR="$NEZHA_DIR/tmp"

NEZHA_AGENT_DIR="$NEZHA_DIR/agent"
NEZHA_AGENT_EXECUTABLE="$NEZHA_AGENT_DIR/nezha-agent"
NEZHA_AGENT_START_SCRIPT="$NEZHA_AGENT_DIR/start.sh"
NEZHA_AGENT_LOG_FILE="$NEZHA_AGENT_DIR/nezha-agent.log"
NEZHA_AGENT_DEFAULT_VERSION="v1.9.6"

install_nezha_agent() {
    echo "正在安装哪吒探针agent..."

    get_platform() {
        case "$1" in
        "Linux") echo "linux" ;;
        "FreeBSD") echo "freebsd" ;;
        *) echo "" ;;
        esac
    }

    get_arch() {
        case "$1" in
        "x86_64") echo "amd64" ;;
        "amd64") echo "amd64" ;;
        "aarch64") echo "arm64" ;;
        "armv7l") echo "armv7" ;;
        *) echo "" ;;
        esac
    }

    OS=$(uname -s)
    ARCH=$(uname -m)
    platform=$(get_platform "$OS")
    arch=$(get_arch "$ARCH")

    if [ -z "$platform" ]; then
        echo "不支持的操作系统: $OS"
        exit 1
    fi

    if [ -z "$arch" ]; then
        echo "不支持的架构: $ARCH"
        exit 1
    fi

    NEZHA_AGENT_VERSION="${NEZHA_AGENT_VERSION:-$NEZHA_AGENT_DEFAULT_VERSION}"
    PANEL_ADDRESS="${PANEL_ADDRESS:-}"
    SERVER_KEY="${SERVER_KEY:-}"
    ENABLE_TLS="${ENABLE_TLS:-false}"
    UUID="${UUID:-$(uuidgen)}"

    if [ -z "$NEZHA_AGENT_VERSION" ]; then
        read -p "请输入nezha-agent版本(default: $NEZHA_AGENT_DEFAULT_VERSION): " input_version
        NEZHA_AGENT_VERSION="${input_version:-$NEZHA_AGENT_DEFAULT_VERSION}"
    fi

    if [ -z "$PANEL_ADDRESS" ]; then
        read -p "请输入服务地址 (your_domain_or_ip:port): " input_panel_address
        PANEL_ADDRESS="${input_panel_address:-}"
    fi

    if [ -z "$SERVER_KEY" ]; then
        read -p "请输入服务密钥（注意：将明文显示）：" input_server_key
        SERVER_KEY="${input_server_key:-}"
    fi

    if [ -z "$ENABLE_TLS" ]; then
        read -p "是否使用tls连接(true|false): " input_enable_tls
        ENABLE_TLS="${input_enable_tls:-false}"
    fi

    case "$ENABLE_TLS" in
    "true"|"TURE"|"True")
        ENABLE_TLS="true"
        ;;
    *)
        ENABLE_TLS="false"
        ;;
    esac

    AGENT_URL="https://github.com/nezhahq/agent/releases/download/${NEZHA_AGENT_VERSION}/nezha-agent_${platform}_${arch}.zip"

    mkdir -p "$NEZHA_AGENT_DIR"
    mkdir -p "$NEZHA_TMP_DIR"

    NEZHA_AGENT_NAME="$NEZHA_TMP_DIR/nezha-agent_${platform}_${arch}.zip"
    echo "正在下载..."
    curl -sL "$AGENT_URL" -o "$NEZHA_AGENT_NAME"
    echo "正在解压..."
    unzip "$NEZHA_AGENT_NAME" -d "$NEZHA_AGENT_DIR"
    
    chmod +x "$NEZHA_AGENT_EXECUTABLE"

    main_version=$(echo "$NEZHA_AGENT_VERSION" | cut -d '.' -f1 | sed 's/^v//')

    case "$main_version" in
    "1")
        echo "使用版本v1"
        config="$NEZHA_AGENT_DIR/config.yml"
        cat > "$config" <<EOF
client_secret: "$SERVER_KEY"
debug: false
disable_auto_update: false
disable_command_execute: false
disable_force_update: false
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 0
report_delay: 0
self_update_period: 0
server: "$PANEL_ADDRESS"
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: "$ENABLE_TLS"
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: "$UUID"
EOF

start_script="$NEZHA_AGENT_START_SCRIPT"
cat > "$start_script" <<EOF
#!/bin/sh
"$NEZHA_AGENT_EXECUTABLE" -c "$config" >> "$NEZHA_AGENT_LOG_FILE" 2>&1 &
EOF
    ;;
    "0")
        echo "使用版本v0"
        start_script="$NEZHA_AGENT_START_SCRIPT"
        if [ "$ENABLE_TLS" = "true" ]; then
            cat > "$start_script" <<EOF
#!/bin/sh
"$NEZHA_AGENT_EXECUTABLE" -s "$PANEL_ADDRESS" -p "$SERVER_KEY" --tls >> "$NEZHA_AGENT_LOG_FILE" 2>&1 &
EOF
        else
            cat > "$start_script" <<EOF
#!/bin/sh
"$NEZHA_AGENT_EXECUTABLE" -s "$PANEL_ADDRESS" -p "$SERVER_KEY" >> "$NEZHA_AGENT_LOG_FILE" 2>&1 &
EOF
        fi
    ;;
    *)
        echo "输入的主版本号不支持"
        exit 1
    ;;
    esac

    chmod +x "$start_script"

    echo "哪吒探针agent安装完成。"
}

uninstall_nezha_agent() {
    echo "卸载哪吒探针agent..."
    killall nezha-agent
    rm -rf ~/.nezha/agent
}

start_nezha_agent() {
    echo "启动哪吒探针agent..."

    if [ ! -f "$NEZHA_AGENT_START_SCRIPT" ]; then
        echo "启动文件不存在，请重新安装"
        exit 1
    fi

    sh "$NEZHA_AGENT_START_SCRIPT"
}

stop_nezha_agent() {
    echo "停止哪吒探针agent..."
    PID=$(ps aux | grep "$NEZHA_AGENT_EXECUTABLE" | grep -v grep | awk '{print $2}')
    if [ -n "$PID" ]; then
        kill "$PID"  # 尝试正常停止
        sleep 2       # 等待一段时间
        PID=$(ps aux | grep "$NEZHA_AGENT_EXECUTABLE" | grep -v grep | awk '{print $2}')
        if [ -n "$PID" ]; then
            kill -9 "$PID" # 如果仍然存在，则强制停止
            echo "哪吒探针agent进程 (PID: $PID) 已被强制杀死。"
        else
            echo "哪吒探针agent进程 (PID: $PID) 已被停止。"
        fi
    else
        echo "没有找到正在运行的哪吒探针agent进程。"
    fi
}

case "$1" in
"install")
    uninstall_nezha_agent
    install_nezha_agent
    start_nezha_agent
    ;;
"uninstall")
    uninstall_nezha_agent
    ;;
"start")
    start_nezha_agent
    ;;
"stop")
    stop_nezha_agent
    ;;
*)
    echo "Usage: $0 {install|start|stop}"
    exit 1
    ;;
esac