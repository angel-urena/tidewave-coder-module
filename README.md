---
display_name: Tidewave
description: Install and run Tidewave in a workspace
icon: ../.icons/tidewave.svg
maintainer_github: tidewave-ai
verified: false
tags: [helper, ai]
---

# Tidewave

Automatically install and run [Tidewave](https://github.com/tidewave-ai/tidewave_app) in a Coder workspace and expose it via the dashboard.

```tf
module "tidewave" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/tidewave/coder"
  version  = "1.0.0"
  agent_id = coder_agent.example.id
}
```

## Examples

### Pin a specific version

```tf
module "tidewave" {
  count            = data.coder_workspace.me.start_count
  source           = "registry.coder.com/modules/tidewave/coder"
  version          = "1.0.0"
  agent_id         = coder_agent.example.id
  tidewave_version = "v0.3.5"
}
```

### Custom port and debug logging

```tf
module "tidewave" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/tidewave/coder"
  version  = "1.0.0"
  agent_id = coder_agent.example.id
  port     = 8080
  debug    = true
}
```

### Alpine Linux (musl libc)

```tf
module "tidewave" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/tidewave/coder"
  version  = "1.0.0"
  agent_id = coder_agent.example.id
  libc     = "musl"
}
```
