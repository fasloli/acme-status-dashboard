#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ];
then
    echo "Oh no! Please, run me with sudo, I need these root powers!" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_KEY="${API_KEY:-}"
VERSION="${VERSION:-1.0.0}"
PORT="${PORT:-5000}"

if [ -z "$API_KEY" ]; 
then
    echo "Oh no! I need an API_KEY to get started!" >&2
    echo "Try: sudo API_KEY=yourkey ./install.sh" >&2
    exit 1
fi

echo "Installing dependencies..."
apt-get update -y
apt-get install -y docker.io nginx
systemctl start docker
systemctl enable docker

echo "Building the Docker image..."
docker build -t status-dashboard "$SCRIPT_DIR"

echo "Tidying up old containers if any..."
docker stop status-dashboard 2>/dev/null || true
docker rm status-dashboard 2>/dev/null || true

echo "Launching a shiny new container!"
docker run -d \
    --name status-dashboard \
    --restart unless-stopped \
    -e PORT="$PORT" \
    -e VERSION="$VERSION" \
    -e API_KEY="$API_KEY" \
    -p 127.0.0.1:"$PORT":"$PORT" \
    status-dashboard

echo "Setting up nginx..."
cp "$SCRIPT_DIR/nginx/status-dashboard.conf" /etc/nginx/sites-available/status-dashboard
ln -sf /etc/nginx/sites-available/status-dashboard /etc/nginx/sites-enabled/status-dashboard
rm -f /etc/nginx/sites-enabled/default

echo "Checking if nginx likes our config..."
nginx -t

echo "Waking up nginx!"
systemctl enable nginx
systemctl reload nginx

echo ""
echo "All done! Your Status Dashboard is live and happy at http://$(hostname -I | awk '{print $1}')/"
