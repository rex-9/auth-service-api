#!/bin/bash

# Set the environment variables
export RAILS_APP_JWT_SECRET_KEY=creator-alliance
export RAILS_APP_CLIENT_BASE_URL=http://localhost:5173
export RAILS_APP_SERVER_BASE_URL=http://localhost:3000

# Start the server
rails s