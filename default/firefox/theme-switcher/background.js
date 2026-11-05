let port;
let themeApplied = false;

const THEMES = {
  dark: {
    colors: {
      frame: "#202124",
      toolbar: "#2b2b2b",
      toolbar_text: "#ffffff",
      toolbar_field: "#3a3a3a",
      toolbar_field_text: "#ffffff",
      tab_background_text: "#ffffff",
      popup: "#2b2b2b",
      popup_text: "#ffffff"
    }
  },
  light: {
    colors: {
      frame: "#f0f0f0",
      toolbar: "#f6f6f6",
      toolbar_text: "#000000",
      toolbar_field: "#ffffff",
      toolbar_field_text: "#000000",
      tab_background_text: "#000000",
      popup: "#ffffff",
      popup_text: "#000000"
    }
  }
};

// Serialize all theme operations to prevent races
let queue = Promise.resolve();
function enqueue(fn) {
  queue = queue.then(fn).catch(() => {});
  return queue;
}

async function applyScheme(scheme) {
  if (!THEMES[scheme]) throw new Error("unknown scheme: " + scheme);
  await browser.theme.update(THEMES[scheme]);
  await browser.storage.local.set({ scheme, themeId: null });
  themeApplied = true;
  return { ok: true, applied: scheme };
}

async function toggleScheme() {
  const { scheme = "light" } = await browser.storage.local.get("scheme");
  return applyScheme(scheme === "dark" ? "light" : "dark");
}

async function applyThemeById(themeId) {
  // Clear any dynamic theme so the extension theme takes effect
  await browser.theme.reset();

  // Retry briefly in case theme extensions are still being installed (first boot)
  let theme;
  for (let i = 0; i < 3; i++) {
    const addons = await browser.management.getAll();
    theme = addons.find(a => a.type === "theme" && a.id === themeId);
    if (theme) break;
    await new Promise(r => setTimeout(r, 1000));
  }
  if (!theme) throw new Error("Theme not found: " + themeId);

  await browser.management.setEnabled(theme.id, true);
  await browser.storage.local.set({ themeId, scheme: null });
  themeApplied = true;
  return { ok: true, applied: themeId };
}

async function restoreFromStorage() {
  const stored = await browser.storage.local.get(["scheme", "themeId"]);
  if (stored.themeId) return applyThemeById(stored.themeId);
  if (stored.scheme) return applyScheme(stored.scheme);
  return { ok: true, applied: "default" };
}

async function handleCommand(msg) {
  if (typeof msg === "string") msg = { cmd: msg };

  switch (msg.cmd) {
    case "restore":      return restoreFromStorage();
    case "toggle":       return toggleScheme();
    case "dark":
    case "light":        return applyScheme(msg.cmd);
    case "set":          return applyScheme((msg.scheme || "").toLowerCase());
    case "applyThemeId": return applyThemeById(msg.themeId);
    default:             throw new Error("unknown command: " + JSON.stringify(msg));
  }
}

// ---------- Native Messaging ----------
// The host sends a startup command as its first message:
//   - State file contents if one existed (theme changed while Firefox was closed)
//   - {"cmd":"restore"} otherwise (restore last theme from storage)
// After that, all messages are live theme-switch commands from the CLI.

function onNativeMessage(msg) {
  // Ignore response acks (our own replies echoed back)
  if (!msg.cmd && msg.ok !== undefined) return;

  enqueue(async () => {
    try {
      const res = await handleCommand(msg);
      port?.postMessage(res);
    } catch (e) {
      port?.postMessage({ ok: false, error: e.message });
    }
  });
}

function connectNative() {
  try {
    port = browser.runtime.connectNative("com.local.theme_switcher");
    port.onMessage.addListener(onNativeMessage);
    port.onDisconnect.addListener(() => {
      port = null;
      setTimeout(connectNative, 3000);
    });
  } catch {
    setTimeout(connectNative, 5000);
  }
}

connectNative();

// On first install, default to dark if nothing is stored
browser.runtime.onInstalled.addListener((details) => {
  if (details.reason === "install") {
    enqueue(async () => {
      const stored = await browser.storage.local.get(["scheme", "themeId"]);
      if (!stored.scheme && !stored.themeId) {
        await applyScheme("dark");
      }
    });
  }
});

// Safety net: if the native host hasn't sent a startup command within 2s,
// restore from storage ourselves (handles host crash / missing native manifest)
setTimeout(() => {
  if (!themeApplied) {
    enqueue(() => restoreFromStorage().catch(() => {}));
  }
}, 2000);
