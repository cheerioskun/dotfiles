import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const STATUS_ID = "dialog-mode";
const DISMISS_HINT = "Close: /dialog-close or Ctrl+Alt+↓";

const moods = ["neutral", "happy", "thinking", "concerned", "excited", "success", "warning"] as const;
type Mood = (typeof moods)[number];

type DialogEvent = {
  id: number;
  kind: "say" | "ask";
  text: string;
  mood: Mood;
  title?: string;
  answer?: string;
};

type DialogState = {
  active: boolean;
  title: string;
  sprite: string;
  mood: Mood;
  events: DialogEvent[];
  index: number;
  nextId: number;
  pendingAskId?: number;
};

const state: DialogState = {
  active: false,
  title: "Pi",
  sprite: "companion",
  mood: "neutral",
  events: [],
  index: 0,
  nextId: 1,
};

const moodSchema = Type.String({ description: `Mood (${moods.join(", ")}).` });

function asMood(value: string | undefined, fallback: Mood): Mood {
  return moods.includes(value as Mood) ? (value as Mood) : fallback;
}

function currentEvent(): DialogEvent | undefined {
  return state.events[state.index];
}

function eventCountLabel(): string {
  if (state.events.length === 0) return "0/0";
  return `${Math.min(state.index + 1, state.events.length)}/${state.events.length}`;
}

function spriteLines(sprite: string, mood: Mood): string[] {
  const faceByMood: Record<Mood, string> = {
    neutral: "•ᴗ•",
    happy: "＾ᴗ＾",
    thinking: "•_•?",
    concerned: "ó_ò",
    excited: ">ᴗ<",
    success: "★ᴗ★",
    warning: "!_!",
  };

  const face = faceByMood[mood];
  if (sprite === "terminal") return ["  ╭────╮", "  │ pi │", "  │  $ │", "  ╰────╯"];
  if (sprite === "cat") return ["   /\_/\\", `  ( ${face} )`, "  /|   |\\", "   / >✨"];
  if (sprite === "slime") return ["    ____", `  ( ${face} )`, "  /      /", " /______/ "];
  return ["    ◜──◝", `  ( ${face} )`, "  /|    |\\", "   |____|"];
}

function renderFooterLines(width = 80): string[] {
  if (!state.active) return [];

  const event = currentEvent();
  const title = event?.title ?? state.title;
  const mood = event?.mood ?? state.mood;
  const count = eventCountLabel();
  const isAsk = event?.kind === "ask";
  const hasNext = state.index < state.events.length - 1;
  const hasPrev = state.index > 0;
  const borderWidth = Math.max(32, width);
  const innerWidth = Math.max(1, borderWidth - 2);
  const label = ` ${title} ${mood !== "neutral" ? `· ${mood} ` : ""}· ${count} `;
  const top = truncateToWidth(`╭─${label}${"─".repeat(Math.max(0, innerWidth - label.length - 1))}╮`, width);
  const bottom = truncateToWidth(`╰${"─".repeat(Math.max(0, innerWidth))}╯`, width);

  const sprite = spriteLines(state.sprite, mood);
  const spriteWidth = Math.max(...sprite.map((line) => line.length), 0);
  const textWidth = Math.max(16, innerWidth - spriteWidth - 5);
  const text = event?.text ?? "Dialog mode is awake.";
  const wrapped = wrapTextWithAnsi(text, textWidth);
  const minBodyRows = 5;
  const rowCount = Math.max(minBodyRows, sprite.length, wrapped.length);
  const rows: string[] = [padPanelLine("", innerWidth, width)];

  for (let i = 0; i < rowCount; i++) {
    const left = (sprite[i] ?? "").padEnd(spriteWidth, " ");
    const right = wrapped[i] ?? "";
    rows.push(padPanelLine(` ${left}  ${right}`, innerWidth, width));
  }

  const hintParts = [DISMISS_HINT];
  if (hasPrev) hintParts.push("Prev: Ctrl+Alt+←");
  if (hasNext) hintParts.push("Next: Ctrl+Alt+→");
  if (isAsk) hintParts.push("answer in prompt");
  if (event?.answer) hintParts.push(`answered: ${event.answer}`);
  if (hintParts.length === 1) hintParts.push("dialog mode active");

  rows.push(padPanelLine("", innerWidth, width));
  rows.push(padPanelLine(` ${hintParts.join("  ·  ")}`, innerWidth, width));
  return [top, ...rows, bottom];
}

function padPanelLine(content: string, innerWidth: number, width: number): string {
  return truncateToWidth(`│${content.padEnd(innerWidth, " ")}│`, width);
}

function updateUi(ctx?: ExtensionContext) {
  if (!ctx?.hasUI) return;

  if (!state.active) {
    ctx.ui.setFooter(undefined);
    ctx.ui.setStatus(STATUS_ID, undefined);
    return;
  }

  ctx.ui.setStatus(STATUS_ID, `dialog ${eventCountLabel()}`);
  ctx.ui.setFooter((_tui, _theme, _footerData) => ({
    render: (width: number) => renderFooterLines(width),
    invalidate: () => {},
  }));
}

function requireDialogActive() {
  if (!state.active) {
    throw new Error("Dialog mode is not active. Call invoke_dialog first, then retry the dialog tool call.");
  }
}

function pushEvent(kind: "say" | "ask", text: string, mood?: Mood, title?: string): DialogEvent {
  const event: DialogEvent = {
    id: state.nextId++,
    kind,
    text,
    mood: mood ?? state.mood,
    title,
  };
  state.events.push(event);
  state.index = state.events.length - 1;
  return event;
}

function resetDialog() {
  state.active = false;
  state.title = "Pi";
  state.sprite = "companion";
  state.mood = "neutral";
  state.events = [];
  state.index = 0;
  state.nextId = 1;
  state.pendingAskId = undefined;
}

export default function dialogMode(pi: ExtensionAPI) {
  pi.registerTool({
    name: "invoke_dialog",
    label: "Invoke Dialog",
    description: "Enter intentional dialog mode and show a large sticky footer companion dialog component. Must be called before dialog_say or dialog_ask.",
    promptSnippet: "Enter intentional companion dialog mode before using dialog_say or dialog_ask.",
    promptGuidelines: [
      "Use invoke_dialog before dialog_say or dialog_ask; dialog_say and dialog_ask intentionally fail until dialog mode is active.",
      "Use invoke_dialog only to start dialog mode; the agent cannot close it. The user dismisses dialog mode with /dialog-close, /dialog-reset, or Ctrl+Alt+DownArrow.",
      "Use dialog_say for short, game-like progress or narration chunks while continuing normal agent/tool streaming outside the dialog.",
      "Use dialog_ask only when you need to block and receive a user choice or freeform answer.",
    ],
    parameters: Type.Object({
      title: Type.Optional(Type.String({ description: "Name shown in the dialog box, e.g. Pi." })),
      sprite: Type.Optional(Type.String({ description: "Sprite flavor: companion, cat, slime, terminal, etc." })),
      mood: Type.Optional(moodSchema),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      state.active = true;
      state.title = params.title?.trim() || state.title;
      state.sprite = params.sprite?.trim() || state.sprite;
      state.mood = asMood(params.mood, state.mood);
      updateUi(ctx);
      return {
        content: [{ type: "text", text: `Dialog mode is active as ${state.title}. Use dialog_say for short chunks, or dialog_ask to ask a blocking question. Only the user can close it (${DISMISS_HINT}).` }],
        details: { active: true, title: state.title, sprite: state.sprite, mood: state.mood, dismiss: DISMISS_HINT },
      };
    },
  });

  pi.registerTool({
    name: "dialog_say",
    label: "Dialog Say",
    description: "Show one small companion-dialog event in the sticky footer dialog component. Requires invoke_dialog first. Returns immediately; normal agent/tool streaming continues outside the dialog.",
    promptSnippet: "Queue one short non-blocking line in the active dialog component.",
    parameters: Type.Object({
      text: Type.String({ description: "A small, human-facing dialog chunk. Keep it brief." }),
      mood: Type.Optional(moodSchema),
      title: Type.Optional(Type.String({ description: "Optional temporary speaker/name override." })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      requireDialogActive();
      const event = pushEvent("say", params.text, asMood(params.mood, state.mood), params.title);
      updateUi(ctx);
      return {
        content: [{ type: "text", text: `Displayed dialog event ${event.id}.` }],
        details: { event },
      };
    },
  });

  pi.registerTool({
    name: "dialog_ask",
    label: "Dialog Ask",
    description: "Ask a blocking question through the sticky footer dialog component. Requires invoke_dialog first. Use only when the agent needs user input to continue.",
    promptSnippet: "Ask a blocking companion-dialog question and receive the user's answer.",
    parameters: Type.Object({
      text: Type.String({ description: "Question to show in the dialog component." }),
      choices: Type.Optional(Type.Array(Type.String(), { description: "Optional choice buttons/list items." })),
      freeform: Type.Optional(Type.Boolean({ description: "Allow typed input. Defaults to true when choices are omitted." })),
      mood: Type.Optional(moodSchema),
      title: Type.Optional(Type.String({ description: "Optional temporary speaker/name override." })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      requireDialogActive();
      if (!ctx.hasUI) throw new Error("dialog_ask requires an interactive or RPC UI.");

      const event = pushEvent("ask", params.text, asMood(params.mood, "thinking"), params.title);
      state.pendingAskId = event.id;
      updateUi(ctx);

      const choices = (params.choices ?? []).map((choice) => choice.trim()).filter(Boolean);
      const allowFreeform = params.freeform ?? choices.length === 0;
      let answer: string | undefined;

      if (choices.length > 0 && !allowFreeform) {
        answer = await ctx.ui.select(params.text, choices);
      } else if (choices.length > 0) {
        const picked = await ctx.ui.select(`${params.text}\n\nPick a choice, or cancel to type a custom answer.`, [...choices, "Other…"]);
        if (picked && picked !== "Other…") answer = picked;
        else answer = await ctx.ui.input(params.text, "Type your answer…");
      } else {
        answer = await ctx.ui.input(params.text, "Type your answer…");
      }

      event.answer = answer?.trim() || "";
      state.pendingAskId = undefined;
      updateUi(ctx);

      return {
        content: [{ type: "text", text: event.answer ? `User answered: ${event.answer}` : "User did not provide an answer." }],
        details: { event, answer: event.answer },
      };
    },
  });

  pi.registerShortcut("ctrl+alt+down", {
    description: "Dialog mode: close",
    handler: async (ctx) => {
      if (!state.active) return;
      const count = state.events.length;
      resetDialog();
      updateUi(ctx);
      ctx.ui.notify(`dialog mode closed (${count} event(s))`, "info");
    },
  });

  pi.registerShortcut("ctrl+alt+right", {
    description: "Dialog mode: next event",
    handler: async (ctx) => {
      if (!state.active || state.events.length === 0) return;
      state.index = Math.min(state.index + 1, state.events.length - 1);
      updateUi(ctx);
    },
  });

  pi.registerShortcut("ctrl+alt+left", {
    description: "Dialog mode: previous event",
    handler: async (ctx) => {
      if (!state.active || state.events.length === 0) return;
      state.index = Math.max(state.index - 1, 0);
      updateUi(ctx);
    },
  });

  pi.registerCommand("dialog-next", {
    description: "Show the next dialog event",
    handler: async (_args, ctx) => {
      if (!state.active || state.events.length === 0) return;
      state.index = Math.min(state.index + 1, state.events.length - 1);
      updateUi(ctx);
    },
  });

  pi.registerCommand("dialog-prev", {
    description: "Show the previous dialog event",
    handler: async (_args, ctx) => {
      if (!state.active || state.events.length === 0) return;
      state.index = Math.max(state.index - 1, 0);
      updateUi(ctx);
    },
  });

  pi.registerCommand("dialog-close", {
    description: "Close dialog mode and remove the sticky footer component",
    handler: async (_args, ctx) => {
      const count = state.events.length;
      resetDialog();
      updateUi(ctx);
      ctx.ui.notify(`dialog mode closed (${count} event(s))`, "info");
    },
  });

  pi.registerCommand("dialog-reset", {
    description: "Close dialog mode and clear its state",
    handler: async (_args, ctx) => {
      resetDialog();
      updateUi(ctx);
      ctx.ui.notify("dialog mode reset", "info");
    },
  });

  pi.registerCommand("dialog-status", {
    description: "Show dialog mode status",
    handler: async (_args, ctx) => {
      ctx.ui.notify(
        `dialog ${state.active ? "active" : "inactive"}; events=${state.events.length}; visible=${eventCountLabel()}; title=${state.title}; sprite=${state.sprite}`,
        "info",
      );
    },
  });

  pi.on("session_start", async (_event, ctx) => updateUi(ctx));
  pi.on("session_shutdown", async (_event, ctx) => {
    if (ctx.hasUI) {
      ctx.ui.setFooter(undefined);
      ctx.ui.setStatus(STATUS_ID, undefined);
    }
  });
}
