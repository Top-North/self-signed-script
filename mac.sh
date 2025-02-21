#!/bin/bash

set -e

clear
echo "  _  ___           _             "
echo " | |/ (_) ___  ___| | _____ _ __ "
echo " | ' /| |/ _ \/ __| |/ / _ \ '__|"
echo " | . \| | (_) \__ \   <  __/ |   "
echo " |_|\_\_|\___/|___/_|\_\___|_|   "
echo "                                 "
echo "This is a helper-script for generating a self-signed certificate to be used with Kiosker API."
echo ""

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NOCOLOR='\033[0m'

# Prompt for root CA generation
read -p "Generate root CA? [Y/n]: " GENERATE_ROOT_CA
echo ""

# Set default for generating root CA if not provided
GENERATE_ROOT_CA=${GENERATE_ROOT_CA:-y}

# Generate root CA if requested
if [ "$GENERATE_ROOT_CA" = "y" ]; then
  read -p "Enter Country (C) for root CA: " ROOT_CA_C
  read -p "Enter State (ST) for root CA: " ROOT_CA_ST
  read -p "Enter Location (L) for root CA: " ROOT_CA_L
  read -p "Enter Organisation (O) for root CA: " ROOT_CA_O
  read -p "Enter Common name (CN) for root CA: " ROOT_CA_CN
  read -p "Enter number of days the root CA certificate should be valid (default: 3650): " ROOT_CA_VALID_DAYS
  read -sp "Enter desired password for root CA: " ROOT_CA_PASSWORD
  echo

  # Set default valid days for root CA if not provided
  ROOT_CA_VALID_DAYS=${ROOT_CA_VALID_DAYS:-3650}

  echo ""
  echo -e "${YELLOW}Generating root CA...${NOCOLOR}"

  openssl genrsa -aes256 -out rootCA.key -passout pass:"$ROOT_CA_PASSWORD" 4096
  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -passin pass:"$ROOT_CA_PASSWORD" -subj "/C=$ROOT_CA_C/ST=$ROOT_CA_ST/L=$ROOT_CA_L/O=$ROOT_CA_O/CN=$ROOT_CA_CN"
  
  echo -e "${GREEN}Generated root CA with the specified parameters.${NOCOLOR}"

else
  read -p "Enter path to root CA key (default: rootCA.key): " ROOT_CA_KEY_PATH
  read -p "Enter path to root CA certificate (default: rootCA.crt): " ROOT_CA_CRT_PATH
  read -sp "Enter password for root CA: " ROOT_CA_PASSWORD
  echo ""
fi

ROOT_CA_KEY_PATH=${ROOT_CA_KEY_PATH:-rootCA.key}
ROOT_CA_CRT_PATH=${ROOT_CA_CRT_PATH:-rootCA.crt}

echo ""
read -p "Enter Country (C): " COUNTRY
read -p "Enter State (ST): " STATE
read -p "Enter Location (L): " LOCATION
read -p "Enter Organisation (O): " ORGANISATION
read -p "Enter DNS/Common name (CN): " COMMON_NAME
read -p "Enter Export name (default: kioskerApi.p12): " EXPORT_NAME
read -p "Enter number of days the certificate should be valid (default: 3650): " VALID_DAYS
read -sp "Enter Export password: " EXPORT_PASSWORD
echo ""

# Set default export name if not provided
EXPORT_NAME=${EXPORT_NAME:-kioskerApi.p12}

# Set default valid days if not provided
VALID_DAYS=${VALID_DAYS:-3650}

echo ""
echo -e "${YELLOW}Generating certificate...${NOCOLOR}"

openssl req -new -nodes -keyout domain.key -out domain.csr -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANISATION/CN=$COMMON_NAME"
echo ""
openssl x509 -req -days $VALID_DAYS -sha256 -in domain.csr -CA $ROOT_CA_CRT_PATH -CAkey $ROOT_CA_KEY_PATH -passin pass:"$ROOT_CA_PASSWORD" -CAcreateserial -out domain.crt -extensions v3_ca -extfile <(
cat <<-EOF
[ v3_ca ]
subjectAltName = DNS:$COMMON_NAME
EOF
)

echo ""
echo -e "${GREEN}Generated certificate with the specified parameters.${NOCOLOR}"
echo ""

echo -e "${YELLOW}Exporting certificate and key...${NOCOLOR}"

openssl pkcs12 -export -legacy -out $EXPORT_NAME -inkey domain.key -in domain.crt -passout pass:"$EXPORT_PASSWORD"

echo -e "${GREEN}Exported certificate and key to $EXPORT_NAME.${NOCOLOR}"
echo ""

# Prompt for root CA generation
read -p "View export? [y/N]: " PRINT_EXPORT

# Set default for generating root CA if not provided
PRINT_EXPORT=${PRINT_EXPORT:-n}

if [ "$PRINT_EXPORT" = "y" ]; then
    openssl pkcs12 -legacy -in $EXPORT_NAME -nodes -passin pass:"$EXPORT_PASSWORD" | openssl x509 -noout -text
fi
