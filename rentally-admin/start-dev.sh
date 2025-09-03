#!/bin/bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Use the installed Node.js version
nvm use node

# Start the development server
echo "Starting Rentaly Admin Panel..."
echo "Access at: http://localhost:5173"
echo "Login credentials: admin@rentaly.com / admin123"
echo ""

npm run dev
