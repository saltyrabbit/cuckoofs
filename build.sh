#!/usr/bin/env bash

set -euo pipefail

BUILD_TYPE="Release"
BUILD_TEST=true
WITH_FUSE_OPT=false
WITH_ZK_INIT=false

# Default command is build
COMMAND=${1:-build}

# Get source directory
CUCKOOFS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
POSTGRES_SRC_DIR="$CUCKOOFS_DIR/third_party/postgres"
export CONFIG_FILE="$CUCKOOFS_DIR/config/config.json"

# Set build directory
BUILD_DIR="${BUILD_DIR:-$CUCKOOFS_DIR/build}"

# Set default PostgreSQL install directory
PG_INSTALL_DIR="${PG_INSTALL_DIR:-$HOME/metadb}"

gen_proto() {
    mkdir -p "$BUILD_DIR"
    echo "Generating Protobuf files..."
    protoc --cpp_out="$BUILD_DIR" \
        --proto_path="$CUCKOOFS_DIR/remote_connection_def/proto" \
        cuckoo_meta_rpc.proto brpc_io.proto
    echo "Protobuf files generated."
}

build_pg() {
    local BLD_OPT=${1:-"deploy"}
    [[ "$BUILD_TYPE" == "Debug" ]] && BLD_OPT="debug"
    local CONFIGURE_OPTS=()

    echo "Building PostgreSQL (mode: $BLD_OPT) ..."
    rm -rf "$POSTGRES_SRC_DIR/contrib/cuckoo"
    cp -rf "$CUCKOOFS_DIR/cuckoo" "$POSTGRES_SRC_DIR/contrib/cuckoo"

    # 设置构建选项
    if [[ "$BLD_OPT" == "debug" ]]; then
        CONFIGURE_OPTS+=(--enable-debug)
    fi

    # 进入源码目录
    cd "$POSTGRES_SRC_DIR" || exit 1

    # 清理旧配置
    if [[ -f "config.status" ]]; then
        make distclean || true
    fi

    # 生成配置并构建
    ./configure --prefix=${PG_INSTALL_DIR} "${CONFIGURE_OPTS[@]}" &&
        make -j$(nproc) &&
        cd "$POSTGRES_SRC_DIR/contrib" && make -j
    echo "PostgreSQL build complete."
}

clean_pg() {
    echo "Cleaning PostgreSQL..."
    if [[ -d "$POSTGRES_SRC_DIR/contrib/cuckoo" ]]; then
        cd "$POSTGRES_SRC_DIR" &&
            [ -f "Makefile" ] && make clean || true
        rm -rf "$POSTGRES_SRC_DIR/contrib/cuckoo"
    fi
    echo "PostgreSQL clean complete."
}

# 构建 CuckooFS
build_cuckoofs() {
    gen_proto
    echo "Building CuckooFS (mode: $BUILD_TYPE)..."
    cmake -B "$BUILD_DIR" -GNinja "$CUCKOOFS_DIR" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DPOSTGRES_SRC_DIR="$POSTGRES_SRC_DIR" \
        -DWITH_FUSE_OPT="$WITH_FUSE_OPT" \
        -DWITH_ZK_INIT="$WITH_ZK_INIT" \
        -DBUILD_TEST=$BUILD_TEST &&
        cd "$BUILD_DIR" && ninja
    echo "CuckooFS build complete."
}

# 清理 CuckooFS
clean_cuckoofs() {
    echo "Cleaning CuckooFS..."
    rm -rf "$BUILD_DIR"
    echo "CuckooFS clean complete."
}

clean_tests() {
    echo "Cleaning CuckooFS tests..."
    rm -rf "$BUILD_DIR/tests"
    echo "CuckooFS tests clean complete."
}

install_pg() {
    echo "Installing PostgreSQL to $PG_INSTALL_DIR..."
    cd "$POSTGRES_SRC_DIR" &&
        make install
    cd "$POSTGRES_SRC_DIR/contrib" && make install
    echo "PostgreSQL installed to $PG_INSTALL_DIR"
}

clean_dist() {
    echo "Removing installed PostgreSQL from $PG_INSTALL_DIR..."
    rm -rf "$PG_INSTALL_DIR"
    echo "PostgreSQL installation removed from $PG_INSTALL_DIR"
}

print_help() {
    case "$1" in
    build)
        echo "Usage: $0 build [subcommand] [options]"
        echo ""
        echo "Build All Components of CuckooFS"
        echo ""
        echo "Subcommands:"
        echo "  pg               Build only PostgreSQL"
        echo "  cuckoo           Build only CuckooFS"
        echo ""
        echo "Options:"
        echo "  --debug          Build debug versions"
        echo "  --release        Build release versions (default)"
        echo "  -h, --help       Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 build --debug     # Build everything in debug mode"
        ;;
    clean)
        echo "Usage: $0 clean [target] [options]"
        echo ""
        echo "Clean build artifacts and installations"
        echo ""
        echo "Targets:"
        echo "  pg       Clean PostgreSQL build artifacts"
        echo "  cuckoo   Clean CuckooFS build artifacts"
        echo "  test     Clean test binaries"
        echo "  dist     Remove installed PostgreSQL from $PG_INSTALL_DIR"
        echo ""
        echo "Options:"
        echo "  -h, --help  Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 clean           # Clean everything except installed PostgreSQL"
        echo "  $0 clean pg       # Clean only PostgreSQL"
        echo "  $0 clean dist     # Remove installed PostgreSQL"
        ;;
    *)
        # 主帮助信息
        echo "Usage: $0 <command> [subcommand] [options]"
        echo ""
        echo "Commands:"
        echo "  build     Build components"
        echo "  clean     Clean artifacts"
        echo "  test      Run tests"
        echo "  install   Install PostgreSQL"
        echo ""
        echo "Run '$0 <command> --help' for more information on a specific command"
        ;;
    esac
}

# 命令分发
case "$COMMAND" in
build)
    # Process shared build options (only debug/deploy allowed for combined build)
    while [[ $# -ge 2 ]]; do
        case "$2" in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --deploy | --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --help | -h)
            print_help "build"
            exit 0
            ;;
        *)
            # Only break if this isn't the combined build case
            [[ -z "${2:-}" || "$2" == "pg" || "$2" == "cuckoo" ]] && break
            echo "Error: Combined build only supports --debug or --deploy" >&2
            exit 1
            ;;
        esac
    done

    case "${2:-}" in
    pg)
        for arg in "${@:3}"; do
            if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
                echo "Usage: $0 build pg [options]"
                echo ""
                echo "Build PostgreSQL Components"
                echo ""
                echo "Options:"
                echo "  --debug    Build in debug mode"
                echo "  --deploy   Build in deploy mode"
                exit 0
            fi
        done
        build_pg "${@:3}"
        ;;
    cuckoo)
        shift 2
        while [[ $# -gt 0 ]]; do
            case "$1" in
            --debug)
                BUILD_TYPE="Debug"
                ;;
            --release | --deploy)
                BUILD_TYPE="Release"
                ;;
            --relwithdebinfo)
                BUILD_TYPE="RelWithDebInfo"
                ;;
            --with-fuse-opt)
                WITH_FUSE_OPT=true
                ;;
            --with-zk-init)
                WITH_ZK_INIT=true
                ;;
            --help | -h)
                echo "Usage: $0 build cuckoo [options]"
                echo ""
                echo "Build CuckooFS Components"
                echo ""
                echo "Options:"
                echo "  --debug         Build in debug mode"
                echo "  --release       Build in release mode"
                echo "  --relwithdebinfo Build with debug symbols"
                echo "  --with-fuse-opt Enable FUSE optimizations"
                echo "  --with-zk-init Enable Zookeeper initialization for containerized deployment"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
            esac
            shift
        done
        build_cuckoofs
        ;;
    *)
        build_pg "${@:2}" && build_cuckoofs
        ;;
    esac
    ;;
clean)
    case "${2:-}" in
    pg)
        # Check for --help in clean pg
        for arg in "${@:3}"; do
            if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
                echo "Usage: $0 clean pg"
                echo "Clean PostgreSQL build artifacts"
                exit 0
            fi
        done
        clean_pg
        ;;
    cuckoo)
        # Check for --help in clean cuckoo
        for arg in "${@:3}"; do
            if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
                echo "Usage: $0 clean cuckoo"
                echo "Clean CuckooFS build artifacts"
                exit 0
            fi
        done
        clean_cuckoofs
        ;;
    test)
        # Check for --help in clean test
        for arg in "${@:3}"; do
            if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
                echo "Usage: $0 clean test"
                echo "Clean test binaries"
                exit 0
            fi
        done
        clean_tests
        ;;
    dist)
        # Check for --help in clean dist
        for arg in "${@:3}"; do
            if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
                echo "Usage: $0 clean dist"
                echo "Remove installed PostgreSQL from $PG_INSTALL_DIR"
                exit 0
            fi
        done
        clean_dist
        ;;
    *)
        # Main clean command options
        while true; do
            case "${2:-}" in
            --help | -h)
                print_help "clean"
                exit 0
                ;;
            *) break ;;
            esac
        done
        clean_pg && clean_cuckoofs
        ;;
    esac
    ;;
test)
    TARGET_DIR="$CUCKOOFS_DIR/build/tests/cuckoo_store/"
    find "$TARGET_DIR" -type f -executable | while read -r executable_file; do
        echo "Executing: $executable_file"
        "$executable_file"
        echo "---------------------------------------------------------------------------------------"
    done
    echo "All unit tests passed."
    ;;
install)
    install_pg
    ;;
*)
    print_help "build"
    exit 1
    ;;
esac
