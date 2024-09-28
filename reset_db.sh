#!/bin/bash

# Drop the database
rails db:drop

# Create a new database
rails db:create

# Run migrations to create new tables
rails db:migrate

# Seed the database (optional)
rails db:seed