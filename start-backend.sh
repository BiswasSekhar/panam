#!/bin/bash

echo "🚀 Starting Panam Backend..."
cd Backend
go mod tidy
go run main.go
