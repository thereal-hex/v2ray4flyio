#!/bin/sh

# ===============================
# V2Ray Install & Config Script
# Protocol: VMess
# Transport: WebSocket (ws)
# Port: 443 (No TLS)
# ===============================

# ---- Set parameters ----
ARCH="64"
DOWNLOAD_PATH="/tmp/v2ray"
UUID=${UUID:-"$(cat /proc/sys/kernel/random/uuid)"}
FLY_APP_NAME=${FLY_APP_NAME:-"unknown-app"}
FLY_REGION=${FLY_REGION:-"unknown-region"}

# ---- Create working directory ----
mkdir -p ${DOWNLOAD_PATH}
cd ${DOWNLOAD_PATH} || exit

# ---- Get latest V2Ray release tag ----
TAG=$(wget --no-check-certificate -qO- https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)
if [ -z "${TAG}" ]; then
    echo "Error: Failed to get V2Ray latest version." && exit 1
fi
echo "The latest V2Ray version: ${TAG}"

# ---- Download V2Ray binaries ----
V2RAY_FILE="v2ray-linux-${ARCH}.zip"
DGST_FILE="${V2RAY_FILE}.dgst"

wget -O v2ray.zip "https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${V2RAY_FILE}" >/dev/null 2>&1
wget -O v2ray.zip.dgst "https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${DGST_FILE}" >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary files." && exit 1
fi

# ---- Verify SHA512 checksum ----
LOCAL=$(openssl dgst -sha512 v2ray.zip | sed 's/.*= //')
EXPECTED=$(grep 'SHA512' v2ray.zip.dgst | awk '{print $2}')

if [ "${LOCAL}" = "${EXPECTED}" ]; then
    echo "✅ SHA512 checksum passed."
else
    echo "❌ SHA512 checksum failed." && exit 1
fi

# ---- Extract and install ----
unzip -q v2ray.zip && chmod +x v2ray v2ctl
mv v2ray v2ctl /usr/bin/
mkdir -p /usr/local/share/v2ray/
mv geosite.dat geoip.dat /usr/local/share/v2ray/

# ---- Write V2Ray configuration ----
mkdir -p /etc/v2ray
cat <<EOF >/etc/v2ray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": 0
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# ---- Clean up ----
cd ~ || exit
rm -rf ${DOWNLOAD_PATH:?}/*

# ---- Output info ----
echo "✅ V2Ray install and configuration complete!"
echo "--------------------------------------------"
echo "Fly App Name     : ${FLY_APP_NAME}"
echo "Fly App Region   : ${FLY_REGION}"
echo "V2Ray UUID       : ${UUID}"
echo "Port             : 443"
echo "Network Protocol : ws"
echo "TLS              : ❌ Disabled"
echo "--------------------------------------------"

# ---- Start V2Ray ----
exec /usr/bin/v2ray -config /etc/v2ray/config.json
