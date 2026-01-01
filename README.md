# luci-app-zapret2

LuCI web interface for zapret2 with Block Check feature.

## Features

- ✅ Complete web interface for zapret2
- 🔍 Block Check tool for testing blocking
- 📦 One-click installation/update
- 📋 Block lists management
- ⚙️ Multiple blocking strategies
- ⏰ Scheduled updates
- 📊 Statistics and logs

## Installation

### Method 1: From GitHub Releases
```bash
# Download the latest release
wget https://github.com/bol-van/zapret2/releases/latest/download/luci-app-zapret2_*.ipk

# Install dependencies
opkg update
opkg install curl wget tar jq

# Install the package
opkg install luci-app-zapret2_*.ipk
Method 2: Manual build
bash
# Clone the repository
git clone https://github.com/bol-van/luci-app-zapret2.git

# Copy to OpenWrt packages
cp -r luci-app-zapret2 openwrt/package/

# Build
cd openwrt
make menuconfig  # Select Luci → Applications → luci-app-zapret2
make package/luci-app-zapret2/compile V=s
Usage
Access the web interface: http://192.168.1.1/cgi-bin/luci/admin/services/zapret2

Click "Install/Update" to install zapret2

Configure block lists in "Block Lists" section

Test blocking with "Block Check" tool

Enable the service in "Configuration"

Block Check Features
Test individual websites

Batch testing

Real-time results

Visual status indicators

Statistics

Screenshots
https://screenshots/status.png
https://screenshots/blockcheck.png
https://screenshots/config.png

Dependencies
luci-compat

luci-lib-ipkg

curl

wget

tar

jq

zapret (can be installed via web interface)

Supported Architectures
x86_64

aarch64 (ARMv8)

mipsel

arm_cortex-a7

arm_cortex-a9

License
GPL-3.0

Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Support
For issues and questions, please use GitHub Issues.

text

## 4. `LICENSE`

```text
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

[Full GPLv3 license text...]
