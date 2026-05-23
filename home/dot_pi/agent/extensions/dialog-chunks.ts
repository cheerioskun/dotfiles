import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

const DIALOG_TAG = "<dialog>";
const WIDGET_ID = "dialog-chunks";
const STATUS_ID = "dialog-chunks";

type StreamState = {
  messageId: string | null;
  raw: string;
  chunks: string[];
  activeIndex: number;
  sawDialog: boolean;
};

type DebugState = {
  lastPromptInjected: boolean;
  lastPromptLength: number;
  lastContextPrune: string;
};

const debugState: DebugState = {
  lastPromptInjected: false,
  lastPromptLength: 0,
  lastContextPrune: "none",
};

const dialogSystemPrompt =
  "Conversation mode (dialog chunks): For any user-facing assistant prose, output plain text split by repeated <dialog> tags. " +
  "Start each new visible chunk with <dialog>. Do not use </dialog>; message end implicitly closes the final chunk. " +
  "Keep using tools normally when tools are needed, but when you speak to the user, speak in dialog chunks.";

const state: StreamState = {
  messageId: null,
  raw: "",
  chunks: [],
  activeIndex: 0,
  sawDialog: false,
};

let enabled = true;

function updateStatus(ctx?: ExtensionContext) {
  if (!ctx?.hasUI) return;
  if (!enabled) {
    ctx.ui.setStatus(STATUS_ID, undefined);
    return;
  }

  const total = state.chunks.length;
  const index = total === 0 ? 0 : Math.min(state.activeIndex, total - 1);
  const suffix = total === 0 ? "" : ` ${index + 1}/${total}`;
  ctx.ui.setStatus(STATUS_ID, `dialog:on${suffix}`);
}

function resetState(ctx?: ExtensionContext) {
  state.messageId = null;
  state.raw = "";
  state.chunks = [];
  state.activeIndex = 0;
  state.sawDialog = false;
  ctx?.ui.setWidget(WIDGET_ID, undefined);
  updateStatus(ctx);
}

function getMessageText(message: any): string {
  const content = Array.isArray(message?.content) ? message.content : [];
  return content
    .filter((part: any) => part?.type === "text" && typeof part?.text === "string")
    .map((part: any) => part.text)
    .join("");
}

function renderWidgetLines(width = 80): string[] {
  const total = state.chunks.length;
  const index = total === 0 ? 0 : Math.min(state.activeIndex, total - 1);
  const chunk = total === 0 ? "…" : state.chunks[index] ?? "…";
  const title = ` Dialogue ${total === 0 ? "0/0" : `${index + 1}/${total}`}  (Ctrl+Alt+←/Ctrl+Alt+→ navigate, /dialog-clear hide)`;
  return [
    truncateToWidth(title, width),
    truncateToWidth("─".repeat(width), width),
    ...wrapTextWithAnsi(chunk.trim() || "…", Math.max(1, width)),
  ];
}

function updateWidget(ctx: ExtensionContext) {
  updateStatus(ctx);
  if (!ctx.hasUI || !state.sawDialog) return;
  ctx.ui.setWidget(WIDGET_ID, (_tui, _theme) => ({
    render: (width: number) => renderWidgetLines(width),
    invalidate: () => {},
  }));
}

function parseFullText(full: string, ctx: ExtensionContext) {
  state.raw = full;
  const parts = state.raw.split(DIALOG_TAG);
  if (parts.length <= 1) return;

  state.sawDialog = true;
  state.chunks = parts.slice(1);

  // Auto-follow the newest chunk while streaming, unless user navigated back.
  if (state.activeIndex >= state.chunks.length - 2) {
    state.activeIndex = Math.max(0, state.chunks.length - 1);
  } else {
    state.activeIndex = Math.min(state.activeIndex, Math.max(0, state.chunks.length - 1));
  }

  updateWidget(ctx);
}

function truncateDialogTextForContext(text: string): { text: string; description: string } | undefined {
  const parts = text.split(DIALOG_TAG);
  if (parts.length <= 1 || state.chunks.length === 0) return undefined;

  const total = parts.length - 1;
  if (total <= 1) return undefined;

  // UX policy: the currently selected dialog is the source of truth. Keep the
  // prefix through the selected item plus one lookahead item. This matches the
  // desired behavior that selecting 4/6 sends dialogs 1-5 on the next call.
  const keep = Math.min(total, Math.max(1, state.activeIndex + 2));
  if (keep >= total) return undefined;

  return {
    text: parts[0] + parts.slice(1, keep + 1).map((part) => DIALOG_TAG + part).join(""),
    description: `${keep}/${total}`,
  };
}

function pruneMessagesToActiveDialog(messages: any[]): any[] | undefined {
  if (!enabled || !state.sawDialog || state.chunks.length === 0) return undefined;

  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i];
    if (message?.role !== "assistant" || !Array.isArray(message.content)) continue;

    const textParts = message.content.filter((part: any) => part?.type === "text" && typeof part.text === "string");
    if (textParts.length === 0) continue;

    const fullText = textParts.map((part: any) => part.text).join("");
    const truncated = truncateDialogTextForContext(fullText);
    if (!truncated) continue;

    const nextMessages = messages.slice();
    let replacedText = false;
    nextMessages[i] = {
      ...message,
      content: message.content.flatMap((part: any) => {
        if (part?.type !== "text" || typeof part.text !== "string") return [part];
        if (replacedText) return [];
        replacedText = true;
        return [{ ...part, text: truncated.text }];
      }),
    };
    debugState.lastContextPrune = truncated.description;
    return nextMessages;
  }

  debugState.lastContextPrune = "none";
  return undefined;
}

export default function dialogChunks(pi: ExtensionAPI) {
  pi.registerCommand("dialog-mode", {
    description: "Toggle streamed <dialog> chunk mode: /dialog-mode on|off",
    handler: async (args, ctx) => {
      const value = (args || "").trim().toLowerCase();
      if (value === "on") enabled = true;
      else if (value === "off") enabled = false;
      else enabled = !enabled;

      if (!enabled) resetState(ctx);
      else updateStatus(ctx);
      ctx.ui.notify(`dialog-mode ${enabled ? "on" : "off"}`, "info");
    },
  });

  pi.registerCommand("dialog-status", {
    description: "Show dialog mode status/debug info",
    handler: async (_args, ctx) => {
      const total = state.chunks.length;
      const index = total === 0 ? 0 : Math.min(state.activeIndex, total - 1);
      ctx.ui.notify(
        `dialog-mode ${enabled ? "on" : "off"}; visible ${total === 0 ? "0/0" : `${index + 1}/${total}`}; ` +
          `promptInjected=${debugState.lastPromptInjected}; promptLength=${debugState.lastPromptLength}; ` +
          `lastContextPrune=${debugState.lastContextPrune}`,
        "info",
      );
    },
  });

  pi.registerCommand("dialog-clear", {
    description: "Hide the dialog chunk widget",
    handler: async (_args, ctx) => resetState(ctx),
  });

  pi.registerShortcut("ctrl+alt+right", {
    description: "Dialog chunks: next chunk",
    handler: async (ctx) => {
      if (!state.sawDialog || state.chunks.length === 0) return;
      state.activeIndex = Math.min(state.activeIndex + 1, state.chunks.length - 1);
      updateWidget(ctx);
    },
  });

  pi.registerShortcut("ctrl+alt+left", {
    description: "Dialog chunks: previous chunk",
    handler: async (ctx) => {
      if (!state.sawDialog || state.chunks.length === 0) return;
      state.activeIndex = Math.max(state.activeIndex - 1, 0);
      updateWidget(ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    updateStatus(ctx);
  });

  pi.on("before_agent_start", async (event) => {
    debugState.lastPromptInjected = false;
    debugState.lastPromptLength = event.systemPrompt.length;
    if (!enabled) return;

    const systemPrompt = `${event.systemPrompt}\n\n${dialogSystemPrompt}`;
    debugState.lastPromptInjected = true;
    debugState.lastPromptLength = systemPrompt.length;
    return { systemPrompt };
  });

  pi.on("context", async (event) => {
    const messages = pruneMessagesToActiveDialog(event.messages as any[]);
    if (messages) return { messages };
  });

  pi.on("message_start", async (event, ctx) => {
    if ((event.message as any)?.role !== "assistant") return;
    resetState(ctx);
    state.messageId = String((event.message as any)?.id ?? "assistant");
  });

  pi.on("message_update", async (event, ctx) => {
    if (!enabled) return;
    if ((event.message as any)?.role !== "assistant") return;

    const messageId = String((event.message as any)?.id ?? "assistant");
    if (state.messageId && messageId !== state.messageId) return;

    parseFullText(getMessageText(event.message), ctx);
  });

  pi.on("message_end", async (event, ctx) => {
    if (!enabled) return;
    if ((event.message as any)?.role !== "assistant") return;
    parseFullText(getMessageText(event.message), ctx);
    // Keep session content unchanged (raw LLM output remains in history).
  });
}
