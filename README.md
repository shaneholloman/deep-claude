# deep-claude

Run Claude Code against DeepSeek's Anthropic-compatible endpoint without touching your normal Claude Code setup.

Two thin Bash wrappers around `claude`:

- **`deep-claude`** — sets DeepSeek-specific env vars and isolates Claude Code state in `.deep-claude-home/` (not your real `~/.claude`).
- **`deep-cco`** — same env setup, but runs everything inside [nikvdp/cco](https://github.com/nikvdp/cco)'s sandbox (Seatbelt on macOS, bubblewrap on Linux, Docker fallback). Useful with `--dangerously-skip-permissions` when you don't want the agent reaching outside the project.

Both wrappers share the same state dir, so DeepSeek session history is consistent across sandboxed and unsandboxed runs.

## Requirements

- **Claude Code** (`claude` on `PATH`) — required for both wrappers
- **DeepSeek API key** — see *Configure the API key* below
- **[nikvdp/cco](https://github.com/nikvdp/cco)** — required only for `deep-cco`; install separately:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/nikvdp/cco/master/install.sh | bash
  ```

`deep-cco` is unconditionally installed by this repo's `install.sh`, but at runtime it will refuse to start with a clear error if `cco` isn't on `PATH`. Install order doesn't matter — `cco` first or deep-claude first, either works.

## Install

Clone the repo, then either run the wrappers from the checkout:

```bash
./deep-claude
./deep-cco
```

…or symlink both into `~/.local/bin`:

```bash
./install.sh
```

That symlinks `deep-claude` and `deep-cco` into `~/.local/bin/`. Make sure that's on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Configure the API key

Pick any one (precedence: shell env > `.env` > Keychain):

```bash
# 1. Export in your shell
export DEEPSEEK_API_KEY="sk-..."

# 2. Or copy the template and fill it in
cp .env.example .env && $EDITOR .env

# 3. Or store it in the macOS Keychain (never lives on disk in plaintext)
security add-generic-password -s deep-claude -a deepseek -U -w
# (you'll be prompted to paste the key; press return when done)
```

Keychain item: service `deep-claude`, account `deepseek`. The `security` binary handles all access, so the secret never appears in `.env`, shell history, or process listings. Both wrappers look up the same item.

## Usage

```bash
deep-claude                                # interactive, deepseek-v4-pro
deep-claude --model flash                  # deepseek-v4-flash
deep-claude --model pro
deep-claude -p "hello"                     # non-interactive
deep-claude --model flash -- -p "hello"    # -- ends deep-claude option parsing
```

`pro` is the default model.

Model aliases:

- `pro` → `deepseek-v4-pro`
- `flash` → `deepseek-v4-flash`

You can also pass a full model name:

```bash
deep-claude --model deepseek-v4-pro
```

All other arguments are passed through to `claude`. Use `--` if you want to stop `deep-claude` option parsing explicitly.

### Sandboxed: `deep-cco`

```bash
deep-cco                       # sandboxed DeepSeek session on deepseek-v4-pro
deep-cco --model flash
deep-cco --safe -p "hi"        # cco's experimental tighter sandbox (hides $HOME)
deep-cco -- -p 3000:3000       # pass args through to cco's sandbox backend
```

`--model` is consumed locally; everything else flows to `cco` (and then to `claude` per cco's own rules). See [cco's README](https://github.com/nikvdp/cco) for sandbox flags like `--safe`, `--add-dir`, `--allow-readonly`, and `--deny-path`.

## How It Stays Isolated

The wrapper sets:

- `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic`
- `ANTHROPIC_AUTH_TOKEN=$DEEPSEEK_API_KEY`
- `ANTHROPIC_API_KEY=$DEEPSEEK_API_KEY`
- `ANTHROPIC_MODEL=<selected model>`

It also points `HOME` and XDG config/cache/data/state paths at `.deep-claude-home/`, so Claude Code does not write to your normal `~/.claude.json` or regular Claude Code state. `deep-cco` inherits that redirected `HOME`, so cco's sandbox auto-detects the isolated `~/.claude` dir and exposes it as writable inside the sandbox — namespace isolation survives the sandboxing layer.

## Development

Run the wrapper checks without making API calls:

```bash
./test.sh
```

The tests use `CLAUDE_BIN=/bin/echo` and `CCO_BIN=/bin/echo` to verify argument passthrough without invoking real binaries.

## License

MIT
