# Haptic — Apple Watch Voice Agent

A lightweight voice assistant for Apple Watch Series 8+ that connects to an AI agent with web research capability.

## Overview

Chat with Claude via your Apple Watch. The agent has full access to the web via Bing Search, so it can answer questions about current events, look up prices, research topics, and more—with citations.

**Built on:** SwiftUI (watchOS) + Node.js Gateway + Anthropic Claude + Bing Search (web research)

---

## Quick Start

### Prerequisites

- Apple Watch Series 8 or later (or watchOS 10+ simulator)
- Node.js 20+
- Anthropic API key ([get one free](https://console.anthropic.com/))
- Perplexity API key ([get one here](https://www.perplexity.ai/))
- LiveKit instance (for agent backend)

### 1. Start the gateway

```bash
cd gateway

# Create .env with your keys
cat > .env <<EOF
PORT=8788
GATEWAY_TOKENS="watch-token:myuserId"
ANTHROPIC_API_KEY=sk-ant-...
BING_SEARCH_KEY=your-bing-search-key
LIVEKIT_URL=ws://localhost:7880
LIVEKIT_API_KEY=your-key
LIVEKIT_API_SECRET=your-secret
AGENT_MODEL=claude-opus-5
AGENT_EFFORT=medium
EOF

npm install
npm start
```

Gateway runs at `http://localhost:8788`.

### 2. Build and run the watch app

**Option A: Xcode (recommended)**
```bash
cd watch
# Open in Xcode or use: xcode-select -p
# Then: Build and Run on Apple Watch simulator or device
```

**Option B: Swift Package Manager**
```bash
cd watch
swift build
```

### 3. Configure the watch app

1. Tap the **Settings** (gear) icon
2. Set:
   - **Gateway URL**: `http://localhost:8788` (for local) or your server URL (for remote)
   - **Auth Token**: `watch-token` (from GATEWAY_TOKENS)
   - **Model**: Claude Opus 5 (or Sonnet 5)
   - **Web Research**: Toggle ON
3. Return to chat

### 4. Start chatting

Type a message or tap the mic button to start a conversation. The agent can:

- Answer questions with web research (auto-cited)
- Remember conversation context
- Handle multi-turn conversations

---

## Features

### Text Chat
Type messages and tap send. Responses stream in real-time.

### Web Research
When the agent needs current information (news, prices, recent events), it automatically:
1. Searches via Bing Search API (1,000 queries/month free)
2. Retrieves citations and snippets
3. Cites sources naturally in its response

Example:
> **You**: "What's the latest ChatGPT news?"
>
> **Agent**: "According to OpenAI's blog, GPT-4 Turbo was released in April 2024 with 128K token context... [continues with citations]"

### Message History
All conversations are saved locally on the watch in JSON format. Switch between chat threads in the UI.

### Agent Memory
The agent has access to a persistent memory store via Anthropic's managed agents API. It can:
- Recall your preferences from past conversations
- Store important facts about you
- Maintain context across sessions

---

## Architecture

```
Apple Watch (watchOS 10+)
       |
       | text messages + auth token
       v
   Gateway (Node.js)
       |
       |-- /v1/chat/completions --> Anthropic Claude
       |                            (with memory store)
       |
       |-- /research endpoint  --> Perplexity API
       |                           (for web search)
       v
   LiveKit Agent Worker
       (runs Claude in agent mode)
```

**Key components:**
- **AgentSessionManager** — Handles gateway communication and audio setup
- **ConversationStore** — Persists message history (JSON) on watch
- **Research module** — Calls Perplexity, formats citations
- **AppSettings** — Stores gateway URL, token, preferences

---

## File Structure

```
.
├── gateway/                   # Node.js backend
│   ├── src/
│   │   ├── server.ts          # Express routes + middleware
│   │   ├── provision.ts       # Agent + session setup
│   │   ├── turn.ts            # Agent turn execution
│   │   ├── research.ts        # Perplexity integration
│   │   ├── connect.ts         # OAuth / vault setup
│   │   └── ...
│   ├── package.json
│   └── .env.example
│
└── watch/                     # watchOS app
    ├── Haptic/
    │   ├── HapticApp.swift
    │   ├── Models/
    │   │   ├── Message.swift
    │   │   ├── AppSettings.swift
    │   │   └── Conversation.swift
    │   ├── Managers/
    │   │   ├── AgentSessionManager.swift
    │   │   └── ConversationStore.swift
    │   └── Views/
    │       ├── ContentView.swift
    │       ├── MessageListView.swift
    │       ├── VoiceControlView.swift
    │       └── SettingsView.swift
    └── Package.swift
```

---

## Configuration

### Environment Variables (Gateway)

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Gateway port | No (default: 8788) |
| `GATEWAY_TOKENS` | `token:userId` pairs | Yes |
| `ANTHROPIC_API_KEY` | Claude API key | Yes |
| `BING_SEARCH_KEY` | Bing Search API key | Yes |
| `LIVEKIT_URL` | WebSocket URL | Yes |
| `LIVEKIT_API_KEY` | LiveKit credential | Yes |
| `LIVEKIT_API_SECRET` | LiveKit credential | Yes |
| `AGENT_MODEL` | `claude-opus-5` or `claude-sonnet-5` | No (default: opus-5) |
| `AGENT_EFFORT` | `low`, `medium`, `high` | No (default: medium) |

### Watch App Settings (UI)

| Setting | Default | Notes |
|---------|---------|-------|
| Gateway URL | `http://localhost:8788` | Must be reachable from watch |
| Auth Token | (empty) | From `GATEWAY_TOKENS` |
| Model | Claude Opus 5 | Agent model to use |
| Web Research | On | Toggle auto-research |

---

## Troubleshooting

### Watch can't connect to gateway

**Check 1: Reachability**
- If local: `curl http://localhost:8788/health`
- If remote: Ensure gateway URL is publicly accessible or on same network

**Check 2: Token**
- Verify token in watch Settings matches `GATEWAY_TOKENS` on gateway
- Restart the watch app and try again

**Check 3: Gateway logs**
- Look for `[chat]` errors: `invalid or missing gateway token`, `provisioning failed`, etc.

### No web research results

**Check 1: Bing Search API key**
- Verify `BING_SEARCH_KEY` is set and valid
- Check gateway logs: `[research] Bing search failed: ...`
- Ensure the API resource in Azure is active (free tier doesn't auto-suspend)

**Check 2: Query format**
- Bing Search is case-sensitive; try rewording
- Very long queries may timeout; keep under 100 chars

### Messages not saving

**Check 1: Storage permissions**
- watchOS 10+ requires app storage permission
- Delete and reinstall app if needed

**Check 2: Disk space**
- Watch storage is limited; old conversations may auto-delete

---

## Development Roadmap

### Completed ✅
- Phase 1: Stripped old iOS/Android code
- Phase 2: watchOS app with text chat
- Phase 3: Bing Search web research integration
- Agent memory (via Anthropic API)

### In Progress 🔄
- Phase 4: Voice recording + speech-to-text

### Coming Soon 📋
- Voice output / speech synthesis
- Conversation history UI (browse past chats)
- iPhone handoff (start on watch, continue on phone)
- Offline message caching
- Richer haptic feedback

---

## License

This source code is licensed under the license found in the [LICENSE](LICENSE) file in the root directory of this source tree.
