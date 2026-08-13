/**
 * Interactive Shell Commands Extension
 *
 * Lets user-entered ! commands run full-screen interactive programs such as
 * vim, nvim, less, htop, fzf, git rebase -i, etc. Pi's TUI is stopped while
 * the command owns the terminal, then restarted when the command exits.
 *
 * Usage after /reload:
 *   !vim MIGRATION_INVENTORY.md
 *   !nvim config/zshrc
 *   !i some-command-that-needs-a-tty
 *
 * Notes:
 * - This intercepts user `!` commands only, not assistant bash tool calls.
 * - Prefix with `!i ` to force interactive mode for any command.
 * - Add commands with INTERACTIVE_COMMANDS="cmd1,cmd2".
 * - Exclude commands with INTERACTIVE_EXCLUDE="cmd1,cmd2".
 */

import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DEFAULT_INTERACTIVE_COMMANDS = [
  // Editors
  "vim",
  "nvim",
  "vi",
  "nano",
  "emacs",
  "pico",
  "micro",
  "helix",
  "hx",
  "kak",

  // Pagers
  "less",
  "more",
  "most",

  // Git interactive flows
  "git commit",
  "git rebase",
  "git merge",
  "git cherry-pick",
  "git revert",
  "git add -p",
  "git add --patch",
  "git add -i",
  "git add --interactive",
  "git stash -p",
  "git stash --patch",
  "git reset -p",
  "git reset --patch",
  "git checkout -p",
  "git checkout --patch",
  "git difftool",
  "git mergetool",

  // TUIs / monitors / file managers
  "htop",
  "top",
  "btop",
  "glances",
  "ranger",
  "nnn",
  "lf",
  "mc",
  "vifm",
  "tig",
  "lazygit",
  "gitui",
  "fzf",
  "sk",

  // Sessions / REPL-ish tools
  "ssh",
  "telnet",
  "mosh",
  "psql",
  "mysql",
  "sqlite3",
  "mongosh",
  "redis-cli",

  // Other interactive commands
  "kubectl edit",
  "kubectl exec -it",
  "docker exec -it",
  "docker run -it",
  "tmux",
  "screen",
  "ncdu",
];

function listFromEnv(name: string): string[] {
  return (process.env[name] ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function getInteractiveCommands(): string[] {
  const excluded = new Set(listFromEnv("INTERACTIVE_EXCLUDE").map((s) => s.toLowerCase()));
  return [...DEFAULT_INTERACTIVE_COMMANDS, ...listFromEnv("INTERACTIVE_COMMANDS")].filter(
    (cmd) => !excluded.has(cmd.toLowerCase()),
  );
}

function isInteractiveCommand(command: string): boolean {
  const trimmed = command.trim().toLowerCase();

  for (const cmd of getInteractiveCommands()) {
    const candidate = cmd.toLowerCase();

    if (trimmed === candidate || trimmed.startsWith(`${candidate} `) || trimmed.startsWith(`${candidate}\t`)) {
      return true;
    }

    // Also catch things like: git log | less
    const pipeIndex = trimmed.lastIndexOf("|");
    if (pipeIndex !== -1) {
      const afterPipe = trimmed.slice(pipeIndex + 1).trim();
      if (afterPipe === candidate || afterPipe.startsWith(`${candidate} `)) {
        return true;
      }
    }
  }

  return false;
}

export default function interactiveShell(pi: ExtensionAPI) {
  pi.on("user_bash", async (event, ctx) => {
    let command = event.command;
    let forceInteractive = false;

    // User syntax: !i command args...
    // Pi passes the command without the leading !, so we detect the "i " prefix here.
    if (command.startsWith("i ") || command.startsWith("i\t")) {
      forceInteractive = true;
      command = command.slice(2).trim();
    }

    if (!forceInteractive && !isInteractiveCommand(command)) {
      return;
    }

    if (!ctx.hasUI) {
      return {
        result: {
          output: "(interactive commands require pi TUI mode)",
          exitCode: 1,
          cancelled: false,
          truncated: false,
        },
      };
    }

    const exitCode = await ctx.ui.custom<number | null>((tui, _theme, _keybindings, done) => {
      tui.stop();
      process.stdout.write("\x1b[2J\x1b[H");

      const shell = process.env.SHELL || "/bin/sh";
      const result = spawnSync(shell, ["-c", command], {
        stdio: "inherit",
        env: process.env,
      });

      tui.start();
      tui.requestRender(true);
      done(result.status);

      return { render: () => [], invalidate: () => {} };
    });

    return {
      result: {
        output:
          exitCode === 0
            ? "(interactive command completed successfully)"
            : `(interactive command exited with code ${exitCode ?? 1})`,
        exitCode: exitCode ?? 1,
        cancelled: false,
        truncated: false,
      },
    };
  });
}
