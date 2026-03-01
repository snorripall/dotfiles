# Generalized rules for development

## Overview
These are rules for development. 

Given the programming language you are working with, ignore any rules that make no logical sense for that language. 

## Seperation of concerns
- Split logic into individual files / components / and modules. This helps in maintaining a clear structure and makes it easier to understand and modify the code and reduces LLM context overflow. 
- Follow the Single Responsibility Principle (SRP): Ensure each class or module has only one reason to change.
- Layer your architecture: Separate concerns into distinct layers, such as Presentation, Business Logic, and Data Access.
- Keep business logic out of the UI: Do not put core business rules in controllers or views; delegate to services or use cases.
- Use services or domain models for business rules: Encapsulate logic in dedicated classes, such as UserService or OrderValidator.
- Avoid god classes: Break down large classes that handle multiple concerns into smaller, focused classes.
- Apply Dependency Inversion: Depend on abstractions, not concrete implementations; use interfaces for loose coupling.
- Isolate data access: Let Repositories or DAOs handle persistence; business logic must not reference databases directly.
- Externalize configuration: Never hardcode values; use config files or environment variables for app settings.
- Separate validation: Perform input validation in controllers and business validation in domain services.
- Design for testing: Structure code so business logic can be unit-tested without UI or database dependencies.
- Use events for decoupling: Apply event-driven patterns for communication across concerns instead of direct calls.

## Git Workflow

### Mandatory Commit Rule
**ALWAYS commit completed, tested features. Never leave uncommitted code.**

### When to Commit
- **After completing any feature or task** that has been implemented and tested
- **Before switching contexts** (moving to a different task or project)
- **At the end of a work session** if any changes exist
- **After fixing a bug** once verified working

### Commit Process
1. **Check for git repository**: Run `git status` to verify you're in a git repo
   - If error "not a git repository": Run `git init` to create a new repo
   - If error "not a git repository": Run `git init` to create a new repo
2. **Ensure .gitignore exists**: Check if `.gitignore` file exists
   - If missing: Create a sensible `.gitignore` for the project type (Node.js, Python, Rust, etc.)
   - Include: secrets, build artifacts, dependencies, IDE files, OS files
3. **Review changes**: Check `git status` and `git diff` to understand what changed
4. **Stage selectively**: Add only relevant files with `git add <file>` (avoid `git add .` unless certain)
5. **Write descriptive message**: Follow conventional commit format
   - `feat: add user authentication endpoint`
   - `fix: resolve null pointer in payment processing`
   - `refactor: extract validation logic into separate module`
6. **Verify commit**: Run `git status` to confirm clean working directory

### Commit Message Format
```
<type>: <short description>

[optional body explaining why and what]

[optional footer with issue references]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### What NOT to Commit
- Secrets (`.env`, API keys, credentials)
- Generated files (build output, `node_modules`, `__pycache__`)
- Temporary files (`.log`, `.tmp`)
- IDE-specific files (unless team-agreed)

### Verification Checklist
Before considering a task complete:
- [ ] All tests pass
- [ ] Code reviewed (if required)
- [ ] Changes committed with descriptive message
- [ ] Working directory is clean (`git status` shows nothing to commit)



## Privilege Escalation Protocol

**OpenCode has NO sudo access and cannot run elevated commands.**

When a task requires elevated privileges:

1. **STOP** - Do NOT attempt to run `sudo` commands
2. **Use the `question` tool** to request manual execution:
   - Explain exactly what command needs to run
   - Explain why it's needed
   - Provide the exact command to copy/paste
   - ONLY use PLAIN TEXT for the question. NEVER user Markdown syntax. 
3. **Wait for confirmation** - Do not proceed until user explicitly confirms
4. **Verify the result** (if applicable) - Check that the command succeeded
5. **Continue** - Resume the task

### Examples requiring manual execution:

- Installing system packages: `sudo apt install`, `sudo pacman -S`
- Starting system services: `sudo systemctl start <service>`
- Modifying system configuration files in `/etc/`
- Any operation that modifies system-wide state

### Example workflow:

OpenCode: I need to install PostgreSQL to set up the database.

[Uses question tool]
Title: Manual sudo required
Question: Please run the following commands in your terminal to install PostgreSQL:

sudo apt update
sudo apt install postgresql postgresql-contrib

Options: [Done]

[User clicks Done] or [User types in their answer]
