# deep-claude

> Run [Claude Code](https://claude.com/claude-code) against DeepSeek's V4 models without polluting your normal Claude Code setup. Optionally sandboxed.

DeepSeek exposes its V4 models behind an Anthropic-compatible API, so a few environment variables are enough to point Claude Code at it. The friction is keeping state from colliding with your normal Anthropic-authed Claude Code, and (optionally) sandboxing an agent you're running with `--dangerously-skip-permissions`. This repo handles both.

Two thin Bash wrappers:

| Wrapper      | What it does                                                                 | Extra dependency                                       |
| ------------ | ---------------------------------------------------------------------------- | ------------------------------------------------------ |
| `deep-claude` | Runs `claude` against `api.deepseek.com/anthropic` with isolated state.     | none                                                   |
| `deep-cco`    | Same as `deep-claude`, but inside [nikvdp/cco](https://github.com/nikvdp/cco)'s sandbox. | [`cco`](https://github.com/nikvdp/cco) |

Both wrappers share the same state directory, so DeepSeek session history is consistent whether you run sandboxed or unsandboxed.

## Contents

- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Configuring the API key](#configuring-the-api-key)
- [Usage](#usage)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## Requirements

- **macOS or Linux**
- **[Claude Code](https://claude.com/claude-code)** — `claude` on `PATH`. Install via the [official installer](https://claude.com/claude-code) or `npm i -g @anthropic-ai/claude-code`.
- **A DeepSeek API key** — sign up at [platform.deepseek.com](https://platform.deepseek.com/).
- **[nikvdp/cco](https://github.com/nikvdp/cco)** — **only** required for `deep-cco`. Install with:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/nikvdp/cco/master/install.sh | bash
  ```

`deep-cco` is installed by this repo's `install.sh` regardless of whether `cco` is present; it will refuse to start with a clear error if `cco` is missing at runtime.

## Quickstart

```bash
git clone https://github.com/dennisonbertram/deep-claude
cd deep-claude
./install.sh
```

This symlinks `deep-claude` and `deep-cco` into `~/.local/bin`. Make sure that directory is on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Set your DeepSeek API key (Keychain is recommended on macOS — see all options below):

```bash
security add-generic-password -s deep-claude -a deepseek -U -w
# (paste the key, then return)
```

Run it:

```bash
deep-claude              # interactive session on deepseek-v4-pro
deep-cco                 # same, but sandboxed (requires cco installed)
```

## Configuring the API key

The wrappers look for `DEEPSEEK_API_KEY` in this order:

1. **Shell environment** — `export DEEPSEEK_API_KEY="sk-..."`
2. **`.env` next to this repo** — `cp .env.example .env && $EDITOR .env`
3. **macOS Keychain** — `security add-generic-password -s deep-claude -a deepseek -U -w`

The literal placeholder `sk-...` (as committed in `.env.example`) is treated as **unset**, so a stale `.env` won't shadow a real Keychain entry.

### Keychain details (macOS)

- Service: `deep-claude` — Account: `deepseek`
- The `security` binary handles all reads, so the key never lives in `.env`, shell history, or process listings.
- The first read after a reboot may show a Keychain access prompt. Click **Always Allow** once and subsequent calls are silent.
- To rotate the key: re-run the `security add-generic-password` command (the `-U` flag updates in place).
- To inspect: `security find-generic-password -s deep-claude -a deepseek -w`
- To remove: `security delete-generic-password -s deep-claude -a deepseek`

### `.env` details

Copy `.env.example` to `.env` (gitignored) and set `DEEPSEEK_API_KEY=...`. You can also override the executables:

```bash
# Optional
CLAUDE_BIN=claude   # used by deep-claude
CCO_BIN=cco         # used by deep-cco
```

## Usage

### `deep-claude` — unsandboxed

```bash
deep-claude                                # interactive, deepseek-v4-pro (default)
deep-claude --model flash                  # deepseek-v4-flash
deep-claude --model deepseek-v4-pro        # full model name also works
deep-claude -p "hello"                     # non-interactive prompt
deep-claude --model flash -- -p "hello"    # -- stops deep-claude option parsing
```

Model aliases:

- `pro` → `deepseek-v4-pro` (default)
- `flash` → `deepseek-v4-flash`

All arguments other than `--model` pass straight through to `claude`. Use `--` to be explicit when `claude`'s own flags overlap with the wrapper's.

### `deep-cco` — sandboxed via [nikvdp/cco](https://github.com/nikvdp/cco)

Same wrapper, but everything runs inside `cco`'s sandbox (native: Seatbelt on macOS, bubblewrap on Linux; Docker as a fallback). Use this when you want the ergonomics of `--dangerously-skip-permissions` without exposing all of `$HOME` to a prompt-injectable agent.

```bash
deep-cco                       # sandboxed DeepSeek session
deep-cco --model flash
deep-cco --safe -p "hi"        # cco's experimental tighter sandbox (hides $HOME)
deep-cco -- -p 3000:3000       # pass args through to cco's underlying sandbox backend
```

`--model` is consumed locally; everything else flows to `cco` (and then to `claude` per cco's rules). See [cco's README](https://github.com/nikvdp/cco) for sandbox flags like `--safe`, `--add-dir`, `--allow-readonly`, and `--deny-path`.

## How it works

Both wrappers set the same environment variables:

```
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=$DEEPSEEK_API_KEY
ANTHROPIC_API_KEY=$DEEPSEEK_API_KEY
ANTHROPIC_MODEL=<selected model>
```

…and redirect `HOME` plus the XDG `config`/`cache`/`data`/`state` directories into `<repo>/.deep-claude-home/`. Claude Code's state — session history, projects, MCP configuration, `~/.claude.json` — lives there instead of in your real `~/.claude/`. Your normal Anthropic Claude Code setup is untouched.

`deep-cco` inherits that redirected `$HOME` and then execs `cco`. cco's filesystem-detection logic uses `$HOME` to find Claude's config dir, so it auto-mounts the redirected `.deep-claude-home/home/.claude` as writable inside the sandbox. Namespace isolation survives the sandboxing layer.

### Files

| Path                       | Purpose                                                                  |
| -------------------------- | ------------------------------------------------------------------------ |
| `bin/deep-claude`          | The wrapper script                                                       |
| `bin/deep-cco`             | The sandboxed wrapper                                                    |
| `deep-claude`, `deep-cco`  | Top-level shims that `exec bin/...` — handy for `./deep-claude` from the repo |
| `install.sh`               | Symlinks both into `~/.local/bin`                                        |
| `test.sh`                  | Syntax and arg-passthrough tests                                         |
| `.env.example`             | Template; copy to `.env` to set the API key in a file                    |
| `.deep-claude-home/`       | gitignored; created on first run; holds isolated Claude Code state       |

## Troubleshooting

**`deep-claude: missing DEEPSEEK_API_KEY`**
No key found in shell env, `.env`, or Keychain. Set one (see [Configuring the API key](#configuring-the-api-key)). Common gotcha: a `.env` file containing the literal `DEEPSEEK_API_KEY=sk-...` placeholder is treated as unset starting from `7629c8b` — if you're on an older version, replace `sk-...` with a real key or `rm .env`.

**`deep-cco: 'cco' is not on PATH`**
Install cco:
```bash
curl -fsSL https://raw.githubusercontent.com/nikvdp/cco/master/install.sh | bash
```

**`Missing required module: ~/.local/bin/lib/agents.sh`**
You're on a `deep-cco` version older than `1ebac2c` that doesn't resolve cco's symlinks before redirecting `$HOME`. `git pull && ./install.sh` to fix.

**Keychain prompt appears repeatedly**
Click **Always Allow** once. macOS pins the access ACL to the `security` binary, so subsequent reads are silent — even across reboots.

**`claude` not found inside the sandbox**
cco bundles its own `claude` install in Docker mode. For native sandboxing (Seatbelt / bubblewrap), make sure `claude` is installed on your host and on `PATH`.

**Argument passthrough confusion**
The wrappers eat `--model X` themselves. Everything else passes through. Use `--` to be explicit: `deep-claude --model flash -- -p "hello"` is unambiguous.

**Want to see what the wrapper would run without actually running it?**
Override the executable:
```bash
CLAUDE_BIN=/bin/echo deep-claude --model flash -p hi
# prints: --model deepseek-v4-flash -p hi
```

## Development

```bash
./test.sh
```

The tests use `CLAUDE_BIN=/bin/echo` and `CCO_BIN=/bin/echo` to verify argument passthrough without invoking real binaries. They cover:

- Bash syntax (`bash -n`) for every script
- Model alias resolution (`pro` / `flash` / explicit name)
- Argument passthrough (`-p`, `--output-format`, etc.)
- The `--` separator semantics

## License

MIT — see [LICENSE](LICENSE).
