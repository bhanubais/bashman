# **SYSTEM DIRECTIVE: STANDALONE PROJECT PROPOSAL FOR AI DEVELOPMENT AGENTS**

## **PROJECT: `bashman` (Stateless API Client)**

### **1\. PROJECT OBJECTIVE**

Build an ultra-fast, dependency-light developer CLI utility dedicated to API testing and network request orchestration.
The core architecture must consist of a lightweight Bash orchestration layer strictly wrapping modern, compiled Rust
binaries. This stack guarantees native-level execution speeds, entirely eliminates Graphical User Interface (GUI)
friction, and strictly bypasses Electron-based memory bloat.

### **2\. THE MARKET PROBLEM**

Standard API testing platforms, most notably Postman, have devolved into bloated Electron applications. They frequently
consume upwards of 1.2 GB of RAM even while sitting idle, essentially starving local IDEs and Docker containers of
critical compute memory [^1]. Furthermore, they introduce severe enterprise friction by gating basic team features
behind subscriptions, installing unnecessary background agents, and forcing cloud synchronization of proprietary backend
data [^2].
While some developers attempt to revert to raw `curl` combined with `jq`, this approach lacks necessary workflow
ergonomics,
makes environment management tedious, and lacks visual clarity for complex JSON responses [^3].

### **3\. CORE ARCHITECTURAL STANDARDS (RUST \+ BASH)**

- **No Legacy GNU Coreutils:** The agent must replace traditional utilities like `cat`, `sed`, and `curl` with modern,
  highly
  performant Rust-based equivalents (`bat`, `sd`, `xh`).
- **Idempotency & Safety:** The `set -eou pipefail` directive must be enforced across all scripts. The CLI must
  gracefully degrade, handling missing dependencies by prompting the user rather than throwing raw syntax errors.
- **Stateless Execution:** No background daemons and no hidden SQLite local databases. The host file system acts as the
  sole source of truth, storing requests and variables as pure text.

### **4\. THE AI ARCHITECTURAL BLUEPRINT**

- **Network Transport:** Implement `xh` (a modern, fast Rust-based HTTP tool) as the core request engine. This tool
  natively handles formatting and simplifies the highly verbose syntax of standard `curl`.
- **Template Orchestration:** Store API requests as standard plain text `.http` files inside the project repository. The
  agent must utilize `sd` (an intuitive Rust-based `sed` alternative) to securely parse files and inject environment
  variables (e.g., replacing `{{BEARER\_TOKEN}}` with actual keys) into the payload. This entirely prevents the
  string-escaping vulnerabilities common in legacy bash scripts.
- **Presentation Layer:** Pipe the API JSON response directly into `bat` (a Rust-based `cat` clone that features native
  syntax highlighting and paging). This ensures the final terminal output perfectly mimics the visual polish,
  colorization, and nested indentation of a heavy GUI, but executes instantly with a memory footprint of under 10
  megabytes.

#### **Works cited**

- [^1]: [Bruno: Fast and Git-friendly open-source API
  client...](https://news.ycombinator.com/item?id=39653718)
- [^2]: [What's the one tool in your stack you wish you could throw in the bin?...](https://www.reddit.com/r/devops/comments/1xsvrsd/whats_the_one_tool_in_your_stack_you_wish_you/)
- [^3]: [Any good offline-first alternatives to Postman? r/devops - Reddit...](https://www.reddit.com/r/devops/comments/1mzksbo/any_good_offlinefirst_alternatives_to_postman/)
- [^4]: [Looking for offline Postman alternatives : r/devops - Reddit...](https://www.reddit.com/r/devops/comments/1mv9dl1/looking_for_offline_postman_alternatives/)
