let port;
let pendingHomeResolver = null;
let pendingFileResolver = null;

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

async function applyScheme(scheme) {
  if (!THEMES[scheme]) throw new Error("unknown scheme: " + scheme);
  await browser.theme.update(THEMES[scheme]);
  await browser.storage.local.set({ scheme, themeId: null });
  return { ok: true, applied: scheme };
}

async function toggleScheme() {
  const { scheme = "light" } = await browser.storage.local.get("scheme");
  const next = scheme === "dark" ? "light" : "dark";
  return applyScheme(next);
}

async function applyThemeById(themeId) {
  const addons = await browser.management.getAll();
  const theme = addons.find(a => a.type === "theme" && a.id === themeId);
  if (!theme) throw new Error("Theme not found: " + themeId);
  
  // Disable all other themes first
  for (const addon of addons) {
    if (addon.type === "theme" && addon.enabled && addon.id !== themeId) {
      await browser.management.setEnabled(addon.id, false);
    }
  }
  
  await browser.management.setEnabled(theme.id, true);
  await browser.storage.local.set({ themeId, scheme: null });
  return { ok: true, applied: themeId };
}

// ---------- Native Messaging ----------
async function onNativeMessage(msg) {
  // 1. Handle internal response for get_home
  if (msg.home && pendingHomeResolver) {
    pendingHomeResolver(msg.home);
    pendingHomeResolver = null;
    return;
  }

  // 2. Handle internal response for read_file
  if ((msg.ok !== undefined || msg.error !== undefined) && pendingFileResolver) {
    pendingFileResolver(msg);
    pendingFileResolver = null;
    return;
  }

  // 3. Handle external commands
  try {
    if (typeof msg === "string") msg = { cmd: msg };
    let res;

    if (msg.cmd === "toggle") res = await toggleScheme();
    else if (msg.cmd === "set" && msg.scheme) res = await applyScheme(msg.scheme.toLowerCase());
    else if (msg.cmd === "dark" || msg.cmd === "light") res = await applyScheme(msg.cmd);
    else if (msg.cmd === "applyThemeId" && msg.themeId) res = await applyThemeById(msg.themeId);
    else if (msg.ok !== undefined) return;
    else throw new Error("bad message");

    port?.postMessage(res);
  } catch (e) {
    port?.postMessage({ ok: false, error: e.message });
  }
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

async function getHomeDir() {
  if (!port) return null;
  return new Promise((resolve) => {
    pendingHomeResolver = resolve;
    port.postMessage({ cmd: "get_home" });
    setTimeout(() => {
      if (pendingHomeResolver === resolve) {
        pendingHomeResolver = null;
        resolve(null);
      }
    }, 1000);
  });
}

async function readFile(path) {
  if (!port) return { ok: false };
  return new Promise((resolve) => {
    pendingFileResolver = resolve;
    port.postMessage({ cmd: "read_file", path });
    setTimeout(() => {
      if (pendingFileResolver === resolve) {
        pendingFileResolver = null;
        resolve({ ok: false });
      }
    }, 1000);
  });
}

let initialized = false;

async function applyStartupTheme() {
  try {
    const home = await getHomeDir();
    if (!home || !port) return;
    
    const statePath = `${home}/.local/share/omarchy/config/firefox-theme-switcher/state.json`;
    const response = await readFile(statePath);
    
    if (response.ok && response.data) {
      const data = JSON.parse(response.data);
      
      if (data.cmd === "dark" || data.cmd === "light") {
        await applyScheme(data.cmd);
      } else if (data.cmd === "toggle") {
        await toggleScheme();
      } else if (data.cmd === "applyThemeId" && data.themeId) {
        await applyThemeById(data.themeId);
      }

      port.postMessage({ cmd: "delete_file", path: statePath });
    } else {
      // No state file - restore last applied theme from storage
      const stored = await browser.storage.local.get(["scheme", "themeId"]);
      
      if (stored.themeId) {
        await applyThemeById(stored.themeId);
      } else if (stored.scheme) {
        await applyScheme(stored.scheme);
      }
      // If nothing stored, keep Firefox's default theme
    }
  } catch (e) {
    // Ignore errors - just keep existing theme
  }
}

connectNative();

async function init() {
  if (initialized) return;
  initialized = true;
  
  // Wait briefly for port connection
  for (let i = 0; i < 10 && !port; i++) {
    await new Promise(r => setTimeout(r, 100));
  }
  
  await applyStartupTheme();
}

browser.runtime.onStartup.addListener(init);
browser.runtime.onInstalled.addListener(async (details) => {
  // On first install or update, ensure dark theme is default if nothing is set
  if (details.reason === "install" || details.reason === "update") {
    const stored = await browser.storage.local.get(["scheme", "themeId"]);
    if (!stored.scheme && !stored.themeId) {
      await applyScheme("dark");
    }
  }
  await init();
});
setTimeout(init, 200);
