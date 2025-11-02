#!/bin/bash

echo "🚀 Setting up Laravel Docker Environment..."

# Create directory structure
mkdir -p docker/nginx/conf.d
mkdir -p docker/nginx/logs
mkdir -p docker/php
mkdir -p src

echo "✅ Directory structure created"

# Check if Laravel is already installed
if [ ! -f "src/artisan" ]; then
    echo "📦 Installing Laravel..."
    docker run --rm -v $(pwd)/src:/app composer create-project --prefer-dist laravel/laravel .
    echo "✅ Laravel installed"
else
    echo "⏭️  Laravel already exists, skipping installation"
fi

# Set permissions
chmod -R 755 src/storage src/bootstrap/cache 2>/dev/null || true

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy the .env file to src/.env"
echo "2. Run: docker-compose up -d"
echo "3. Run the artisan commands from the README"