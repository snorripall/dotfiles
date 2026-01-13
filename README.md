# Agent Developer Setup
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
* Runs on Aarch and MacOS
* Open source
* Allows me to bring my own API keys
	* No lock-in models
### Editor
* Super super duper fast
* Works with large files
* Extensible
* Native tools made available via ACP
* Native or extensions for 3rd party AI agents
* Native support for ACP / A2A protocol
* Git support
### Developer Agent
* Allows me to add custom 
* Can route between models based on prompts need
* Robust permissions so it doesn't accidentally all my computer
* Allows me to add custom agents and skills
* Allows me to create my own developer workflow
	* In general
	* For a project
	* For a programming language
* Must have [ACP](https://agentcommunicationprotocol.dev/introduction/welcome) / [A2A](https://a2a-protocol.org/latest/) support so it can run in side a compatible editor 
* Has a nice CLI interface
	* When I want to run something autonomously
	* To use when I'm managing servers
### Task Management
* Can rewrite my prompt into a better feature description 
* Can break down large tasks into smaller tasks
* Can mange multiple set of complex features (Epics/Branches)
* Can identify the next logical task to pick up
	* Can identify the dependency tree between all tasks and figure out what needs 
* When I add a new task it should
	* Updates the dependency tree
	* Notify me of inconsistencies and conflicts
		* Will suggest fixes 
		* Allows me to modify suggestions or give my own 
	* Is accessible as a tool or MCP to any developer agent. 
* Is embedded visually into my editor

## Tools I am currently using

### [Zed](https://zed.dev/)
Zed by far the best editor I have ever used. It's robust and super fast and it's community is growing fast. 

I believe that [their vision for the editor](https://zed.dev/blog/sequoia-backs-zed
) is a very strong one and quite unique in the sea of VS Code clones. 

 It is created by the same team that created Atom and Electron (which inspired Microsoft to create VS Code). 
### [OpenCode](https://opencode.ai/)
 I spent over 6 weeks to try out all possible developer agent tools I could find and pushed them to their limits and ended up on [OpenCode](https://github.com/anomalyco/opencode). 
 
 But that may change in the future.
 
 [Goose](https://github.com/block/goose) technically came first due to it's robust architecture and overall extensibility. But the user experience and the functionality is unfortunately half-baked across the board. 
## Plugins and MCPs
### [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode)
Oh My OpenCode is the real reason I found OpenCode acceptable. 

This replaces OpenCodes default agents. It is far superior than what OpenCode has. I recommend having a look at their repo to see what features they offer. 

### [Taskmaster AI](https://github.com/eyaltoledano/claude-task-master)
I am using Taskmaster AI to manage tasks. It is a great tool that fulfills most of my needs and makes running OpenCode autonomously much easier

```
/ralph-loop Please finish all the tasks in Task Master. You are not finished until all tasks are marked as done. 
```

# API Keys
I store all my API keys in my environment. 

- `XAI_API_KEY`
- `MISTRAL_API_KEY`
- `OPENROUTER_API_KEY`
- `GOOGLE_API_KEY`
- `GEMINI_API_KEY`

etc.
