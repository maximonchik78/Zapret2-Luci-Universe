#!/bin/sh

set -e

DOWNLOAD_URL="$1"
VERSION="$2"
TMPDIR="/tmp/zapret_install"

echo "Starting Zapret2 installation..."
echo "Version: $VERSION"
echo "URL: $DOWNLOAD_URL"

mkdir -p "$TMPDIR"
cd "$TMPDIR"

if [ -f /etc/init.d/zapret ] && [ -x /etc/init.d/zapret ]; then
    echo "Stopping existing zapret service..."
    /etc/init.d/zapret stop >/dev/null 2>&1 || true
fi

echo "Downloading package..."
wget --no-check-certificate -q --show-progress -O zapret.tar.gz "$DOWNLOAD_URL"

if [ ! -f "zapret.tar.gz" ]; then
    echo "ERROR: Failed to download package"
    exit 1
fi

echo "Extracting files..."
tar -xzf zapret.tar.gz

if [ ! -d "zapret" ]; then
    echo "ERROR: Invalid package structure"
    exit 1
fi

cd zapret

echo "Installing files..."

if [ -f "zapret" ]; then
    cp zapret /usr/bin/ 2>/dev/null || cp zapret /usr/sbin/ 2>/dev/null || true
fi

if [ -f "zapret.initd" ]; then
    cp zapret.initd /etc/init.d/zapret
    chmod +x /etc/init.d/zapret
fi

if [ -f "zapret.service" ]; then
    cp zapret.service /etc/systemd/system/ 2>/dev/null || true
fi

mkdir -p /etc/zapret
cp -r etc/zapret/* /etc/zapret/ 2>/dev/null || true

mkdir -p /usr/share/doc/zapret
cp -r doc/* /usr/share/doc/zapret/ 2>/dev/null || true

chmod +x /usr/bin/zapret 2>/dev/null || chmod +x /usr/sbin/zapret 2>/dev/null || true

if [ ! -f /usr/sbin/zapret ] && [ -f /usr/bin/zapret ]; then
    ln -sf /usr/bin/zapret /usr/sbin/zapret 2>/dev/null || true
fi

if [ -f /etc/init.d/zapret ]; then
    /etc/init.d/zapret enable 2>/dev/null || true
fi

if [ ! -f /etc/config/zapret2 ]; then
    cat > /etc/config/zapret2 << 'EOF'
config main 'config'
    option enabled '0'
    option strategy 'tpws'
    option ipv6 '1'
    option debug '0'
    option update_interval '7'

config list 'blocked'
    option name 'default'
    option url 'https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv'
    option enabled '1'
    option update 'daily'

config exception 'whitelist'
    list domain 'example.com'
    list domain 'google.com'
    list ip '192.168.1.0/24'

config strategy 'tpws'
    option enabled '1'
    option http_port '80'
    option https_port '443'
    option dns_port '53'

config strategy 'nfqws'
    option enabled '0'
    option queue_num '0'
EOF
fi

cd /
rm -rf "$TMPDIR"

echo ""
echo "========================================="
echo "Zapret2 $VERSION successfully installed!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Configure blocking lists in the web interface"
echo "2. Select blocking strategy"
echo "3. Enable and start the service"
echo ""
echo "Installation completed at $(date)"
