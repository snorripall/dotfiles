# My Dotfiles
This is my personal configuration and will change over time based on my needs and preferences. 

This can be a starting point for your own configuration. Feel free to modify it to suit your needs.

If you wish to contribute any improvement such as agents or skills, feel free to send me a pull request. Just make sure you explain in the pull request what problem you are trying to solve.

Use at your own risk. I take zero responsibility. 

## How to use this repo

* Clone this repo to a folder that is not your `~./config/` folder
* For regular updates, symlink desired files/folders from the repo into your `~./config/`
* Only symlink the files/folders you wish to get regular updates for

## Criteria
This is the criteria I set for the ideal work environment. Not all criteria has been met yet. But It's getting close. 

### All tools
* Runs on Linux and MacOS
  * Linux: CachyOS + niri + Dank Material Shell
  * MacOS: Latest OS on M2 
* Open source
* Allows me to bring my own API keys
	* No lock-in models
### Editor
* :white_check_mark: Super super duper fast
* :white_check_mark: Works with large files
* :white_check_mark: Extensible
* :white_check_mark: Native tools made available via ACP
* :white_check_mark: Native or extensions for 3rd party AI agents
* Native support for Agent Protocols
  * :white_check_mark: ACP
  * A2A
* :white_check_mark: Git support
### Agent Harness
* :white_check_mark: Custom models 
* :white_check_mark: Can route between models based on prompts need
* :white_check_mark: Robust permissions so it doesn't accidentally all my computer
* :white_check_mark: Allows me to add custom agents and skills
* Allows me to create my own developer workflow
	* In general
	* For a project
	* For a programming language
* :white_check_mark: Must have [ACP](https://agentcommunicationprotocol.dev/introduction/welcome) / [A2A](https://a2a-protocol.org/latest/) support so it can run in side a compatible editor 
* :white_check_mark: Has a nice CLI interface
	* :white_check_mark: When I want to run something autonomously
	* To use when I'm managing servers
### Task Management
* :white_check_mark: Can rewrite my prompt into a better feature description 
* :white_check_mark: Can break down large tasks into smaller tasks
* :white_check_mark: Can mange multiple set of complex features (Epics/Branches)
* :white_check_mark: Can identify the next logical task to pick up
	* :white_check_mark: Can identify the dependency tree between all tasks and figure out what order things should be done in
* :last_quarter_moon: When I add a new task it should
	* :last_quarter_moon: Updates the dependency tree
	* :white_check_mark: Notify me of inconsistencies and conflicts
		* :white_check_mark: Will suggest fixes 
		* :white_check_mark: Allows me to modify suggestions or give my own 
	* :x: Is accessible as a tool or MCP to any developer agent. 
* :last_quarter_moon: Is embedded visually into my editor

# My workflow
I spend most of my time planning features and writing good detailed requirements documents. 

* Ideation: 
  * I start a conversation with a general agent like grok.com and get my idea across and structured in an abstract manner.
  * When I'm happy with the results I ask it to summarise it up so an AI agent can make a plan out of it. 
* Planning: 
  * Prompt the agent: "Please take this and turn it into a executable plan. Ask me any clarifying questions". Then I paste in the text. 
  * Work on it until I'm satisfied
    
* Execution
  * Prompt the agent: "Ultrawork on the latest plan"
  * Go work on my next Ideation while the agent delivers. 

## Tips
* Ideation: Make sure you tell it to only work on architecture and system design level. Not to think of what technology to use. Just pure problem solving on a system / product level. 
* Planning: 
  * To speed up your review, ask your agent to use Mermaid in the markdown files for better communication of any architecutre / system design. 
    * I use Obsidian to view the plans from the agent before I finalize them
  * Currently /start-work in Oh-My-OpenCode seem to not work as *I* would expect it to work. So I ask it to finalize the plan and remove it from draft mode and when that is done I switch over to the execution agent. 


## Tools I am currently using

### [Zed](https://zed.dev/)
Zed by far the best editor I have ever used. It's robust and super fast and it's community is growing fast. 

I believe that [their vision for the editor](https://zed.dev/blog/sequoia-backs-zed
) is a very strong one and quite unique in the sea of VS Code clones. 

 It is created by the same team that created Atom and Electron (which inspired Microsoft to create VS Code). 
### [OpenCode](https://opencode.ai/)
 I spent over 6 weeks to try out all possible developer agent tools I could find and pushed them to their limits and ended up on [OpenCode](https://github.com/anomalyco/opencode). 
 
 But that may change in the future.
 
## Plugins and MCPs
### [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode)
Oh My OpenCode is the real reason I found OpenCode acceptable. 

This replaces OpenCodes default agents. It is far superior than what OpenCode has. I recommend having a look at their repo to see what features they offer.


# Configs

## API Keys
I store all my API keys in my environment. 

- `XAI_API_KEY`
- `MISTRAL_API_KEY`
- `OPENROUTER_API_KEY`
- `GOOGLE_API_KEY`
- `GEMINI_API_KEY`

etc.

## Repository Structure

```
dotfiles/
├── fish/                   # Fish shell configuration
│   ├── config.fish        # Main fish config with git abbreviations
│   └── functions/         # Fish functions
│       └── env-sync.fish  # Bitwarden environment sync
├── opencode/              # OpenCode configuration
│   ├── opencode.json      # Main OpenCode config (MCPs, model)
│   ├── oh-my-opencode.json # Custom agents and categories
│   └── AGENTS.md          # Development guidelines for AI agents
├── zed/                   # Zed editor configuration
│   ├── settings.json      # Editor settings and agent config
│   └── keymap.json        # Custom keybindings
├── scripts/               # Setup scripts
│   ├── setup-fish.sh      # Symlink fish config
│   └── symlink-opencode.sh # Symlink OpenCode config
└── README.md              # This file
```

## Shell Configuration (Fish)

### Git Abbreviations

The fish config includes convenient git abbreviations:
- `g` → `git`
- `gs` → `git status`
- `gc` → `git clone`
- `gpush` → `git push`
- `gpull` → `git pull`

### Environment Sync (`env-sync`)
I need to be able to keep my keys in sync across operating systems. 
This is a fish function that syncs API keys from Bitwarden to environment variables. 

```bash
# Sync API keys from Bitwarden to current session
env-sync

# Force refresh all variables (even unchanged)
env-sync --force

# Show help
env-sync --help
```

**Requirements:**
- Bitwarden CLI (`bw`) installed and logged in
- `jq` for JSON parsing
- An "API Keys" item in Bitwarden with custom fields for each API key

**Behavior:**
- New variables: Always set
- Changed values: Auto-updated (smart sync)
- Unchanged values: Skipped (unless `--force`)
- All values persisted to `~/.config/fish/conf.d/env-sync-vars.fish` for future shells

### SSH Keychain

Automatically loads SSH keys via `keychain` on shell startup.

## Setup Scripts
### `scripts/setup-fish.sh` (linux)

Symlinks fish configuration files:
```bash
./scripts/setup-fish.sh
```

This will:
- Create `~/.config/fish/functions/` if needed
- Symlink `env-sync.fish` to functions directory
- Backup existing `config.fish` (if not a symlink)
- Symlink `config.fish`

### `scripts/symlink-opencode.sh` (linux+mac)

Symlinks OpenCode configuration:
```bash
./scripts/symlink-opencode.sh
```

This symlinks all opencode config files to `~/.config/opencode/`.

## OpenCode Configuration

### Main Config (`opencode.json`)

- **Plugin:** Oh My OpenCode (latest)
- **Default Model:** xAI/grok-code-fast-1
- **MCPs:**
  - Playwright (enabled) - Browser automation

### Custom Agents (`oh-my-opencode.json`)

All agents and categories use `kimi-for-coding/k2p5` model:

| Agent | Purpose |
|-------|---------|
| `build` | Building and compilation tasks |
| `plan` | Planning and architecture |
| `sisyphus` | Main orchestration agent |
| `sisyphus-junior` | Delegated subtasks |
| `OpenCode-Builder` | Code construction |
| `prometheus` | Planning consultant |
| `metis` | Pre-planning analysis |
| `momus` | Quality assurance |
| `oracle` | Complex debugging/architecture |
| `librarian` | Documentation research |
| `explore` | Codebase exploration |
| `hephaestus` | Infrastructure/devops |
| `frontend-ui-ux-engineer` | Frontend development |
| `document-writer` | Documentation |
| `multimodal-looker` | Media analysis |
| `atlas` | Project mapping |

**Categories:** visual-engineering, ultrabrain, artistry, quick, unspecified-low, unspecified-high, writing, deep

### Development Guidelines (`AGENTS.md`)

Rules for AI agents working in this codebase:
- Separation of concerns and SRP
- Layered architecture
- Dependency inversion
- Event-driven patterns
- **Git workflow:** Mandatory commits, conventional commits format
- **Testing:** Design for testability

### Keybindings (`keymap.json`)

| Key | Action |
|-----|--------|
| `Cmd+Æ` | Toggle assistant focus |
| `Ctrl+Cmd+Right` | Quote selection to assistant |
| `Ctrl+Cmd+Left` | Insert assistant response into editor |
