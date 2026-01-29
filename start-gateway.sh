#!/bin/bash
export CLAWDBOT_GATEWAY_TOKEN="local-dev-token"
exec moltbot gateway run --bind loopback --port 18789 --force
