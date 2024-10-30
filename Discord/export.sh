#!/bin/bash

if [ ! -f .Discord_token.env ]; then
    echo "Discord_token.env file not found!"
    exit 1
else
    source .Discord_token.env
fi

dotnet DiscordChatExporter/DiscordChatExporter.Cli.dll export -t "$TOKEN" $@