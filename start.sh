#!/bin/bash

# Quick Start Script for Open WebUI with External APIs
# =====================================================

set -e

echo "🚀 Open WebUI Quick Setup (External APIs)"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to install Docker
install_docker() {
    echo -e "${BLUE}📦 Installing Docker...${NC}"
    echo ""

    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}Cannot detect OS${NC}"
        exit 1
    fi

    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        SUDO="sudo"
    else
        SUDO=""
    fi

    case $OS in
        debian|ubuntu)
            echo "Detected: $OS"
            echo "Installing Docker for Debian/Ubuntu..."

            # Remove old versions
            $SUDO apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

            # Update and install prerequisites
            $SUDO apt-get update
            $SUDO apt-get install -y ca-certificates curl gnupg lsb-release

            # Add Docker's official GPG key
            $SUDO install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

            # Set up the repository
            CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
            ARCH=$(dpkg --print-architecture)
            echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS ${CODENAME} stable" \
                | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install Docker Engine
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Start Docker
            $SUDO systemctl start docker
            $SUDO systemctl enable docker

            # Add current user to docker group (if not root)
            if [ "$EUID" -ne 0 ]; then
                $SUDO usermod -aG docker "$USER"
                echo -e "${YELLOW}⚠️  You've been added to the docker group${NC}"
                echo -e "${YELLOW}⚠️  Please log out and log back in, or run: newgrp docker${NC}"
                echo -e "${YELLOW}⚠️  Then run this script again${NC}"
                exit 0
            fi
            ;;
        centos|rhel|fedora)
            echo "Detected: $OS"
            echo "Installing Docker for CentOS/RHEL/Fedora..."

            # Remove old versions
            $SUDO yum remove -y docker docker-client docker-client-latest docker-common docker-latest \
                docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true

            # Install prerequisites
            $SUDO yum install -y yum-utils
            $SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

            # Install Docker Engine
            $SUDO yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Start Docker
            $SUDO systemctl start docker
            $SUDO systemctl enable docker

            # Add current user to docker group (if not root)
            if [ "$EUID" -ne 0 ]; then
                $SUDO usermod -aG docker "$USER"
                echo -e "${YELLOW}⚠️  You've been added to the docker group${NC}"
                echo -e "${YELLOW}⚠️  Please log out and log back in, or run: newgrp docker${NC}"
                echo -e "${YELLOW}⚠️  Then run this script again${NC}"
                exit 0
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS: $OS${NC}"
            echo "Please install Docker manually: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac

    echo -e "${GREEN}✅ Docker installed successfully${NC}"
    echo ""
}

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not installed${NC}"
    read -p "Do you want to install Docker automatically? (y/n): " install_choice
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
        install_docker
    else
        echo -e "${RED}❌ Docker is required. Exiting.${NC}"
        echo "Install manually: https://docs.docker.com/get-docker/"
        exit 1
    fi
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo "Docker Compose should be installed with Docker."
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Creating .env from template..."
    cp .env.example .env 2>/dev/null || {
        echo -e "${RED}Cannot find .env.example${NC}"
        exit 1
    }
fi

# Interactive setup
echo "📝 Configuration Setup"
echo "====================="
echo ""

# Domain setup
read -p "Enter your domain (e.g., chat.example.com): " user_domain
if [ ! -z "$user_domain" ]; then
    sed -i "s/DOMAIN=.*/DOMAIN=$user_domain/" .env
    sed -i "s/your-domain\.com/$user_domain/g" Caddyfile
    echo -e "${GREEN}✅ Domain set to: $user_domain${NC}"
fi

echo ""
echo "🔑 API Keys Configuration"
echo "========================="
echo "Leave blank to skip any provider"
echo ""

# OpenAI
read -p "Enter OpenAI API Key (sk-...): " openai_key
if [ ! -z "$openai_key" ]; then
    sed -i "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=$openai_key/" .env
    echo -e "${GREEN}✅ OpenAI configured${NC}"
fi

# Anthropic
read -p "Enter Anthropic API Key (sk-ant-...): " anthropic_key
if [ ! -z "$anthropic_key" ]; then
    sed -i "s/ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$anthropic_key/" .env
    echo -e "${GREEN}✅ Anthropic configured${NC}"
fi

# Google
read -p "Enter Google Gemini API Key: " google_key
if [ ! -z "$google_key" ]; then
    sed -i "s/GOOGLE_API_KEY=.*/GOOGLE_API_KEY=$google_key/" .env
    echo -e "${GREEN}✅ Google Gemini configured${NC}"
fi

# Groq
read -p "Enter Groq API Key (optional): " groq_key
if [ ! -z "$groq_key" ]; then
    sed -i "s/GROQ_API_KEY=.*/GROQ_API_KEY=$groq_key/" .env
    echo -e "${GREEN}✅ Groq configured${NC}"
fi

echo ""
echo "🔐 Security Setup"
echo "================="

# Generate secret key
SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sed -i "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=$SECRET_KEY/" .env
echo -e "${GREEN}✅ Secret key generated${NC}"

# Enable signup
read -p "Allow new user signups? (y/n): " allow_signup
if [ "$allow_signup" = "n" ] || [ "$allow_signup" = "N" ]; then
    sed -i "s/ENABLE_SIGNUP=.*/ENABLE_SIGNUP=false/" .env
    echo -e "${YELLOW}⚠️  Signups disabled${NC}"
else
    sed -i "s/ENABLE_SIGNUP=.*/ENABLE_SIGNUP=true/" .env
    echo -e "${GREEN}✅ Signups enabled${NC}"
fi

echo ""
echo "🌐 Starting Services"
echo "==================="

# Create data directory
mkdir -p data

# Start services
docker compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check status
if docker ps | grep -q "open-webui.*Up"; then
    echo -e "${GREEN}✅ Open WebUI is running!${NC}"
else
    echo -e "${RED}❌ Open WebUI failed to start${NC}"
    echo "Check logs: docker compose logs open-webui"
    exit 1
fi

if docker ps | grep -q "caddy.*Up"; then
    echo -e "${GREEN}✅ Caddy is running!${NC}"
else
    echo -e "${RED}❌ Caddy failed to start${NC}"
    echo "Check logs: docker compose logs caddy"
    exit 1
fi

# Success message
echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "📌 Access your Open WebUI at:"
echo "   https://$user_domain"
echo ""
echo "📝 Next steps:"
echo "   1. Visit the URL above"
echo "   2. Create your admin account (first user becomes admin)"
echo "   3. Start chatting with AI!"
echo ""
echo "📊 Useful commands:"
echo "   View logs:  docker compose logs -f"
echo "   Stop:       docker compose down"
echo "   Restart:    docker compose restart"
echo "   Update:     docker compose pull && docker compose up -d"
echo ""
echo "Need help? Check README.md for more information"