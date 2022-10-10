#!/bin/sh
set -e

echo "Activating feature 'loop'"

MESSAGE=${MESSAGE:-undefined}
COUNT=${COUNT:-10}


cat > /usr/local/bin/loop \
<< EOF
#!/bin/bash
RED='\033[0;91m'
NC='\033[0m' # No Color
for i in \$(seq 1 ${COUNT})
do    echo -e "\${RED}${MESSAGE}\${NC}"
done
EOF

chmod +x /usr/local/bin/loop

# Take it for a spin
echo 'Executing loop...'
/usr/local/bin/loop