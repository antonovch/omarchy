let port;

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
  await browser.storage.local.set({ scheme });
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
  await browser.management.setEnabled(theme.id, true);
  await browser.storage.local.set({ themeId });
  return { ok: true, applied: themeId };
}

// ---------- Native Messaging ----------
async function onNativeMessage(msg) {
  try {
    if (typeof msg === "string") msg = { cmd: msg };
    let res;

    if (msg.cmd === "toggle") res = await toggleScheme();
    else if (msg.cmd === "set" && msg.scheme) res = await applyScheme(msg.scheme.toLowerCase());
    else if (msg.cmd === "dark" || msg.cmd === "light") res = await applyScheme(msg.cmd);
    else if (msg.cmd === "applyThemeId" && msg.themeId) res = await applyThemeById(msg.themeId);
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
  return new Promise((resolve) => {
    if (!port) {
      resolve(null);
      return;
    }
    
    const originalHandler = port.onMessage.hasListener ? port.onMessage.removeListener : null;
    
    const handler = (msg) => {
      if (msg.home) {
        port.onMessage.removeListener(handler);
        if (originalHandler) port.onMessage.addListener(originalHandler);
        resolve(msg.home);
      }
    };
    
    port.onMessage.addListener(handler);
    port.postMessage({ cmd: "get_home" });
  });
}

async function applyStartupTheme() {
  try {
    const home = await getHomeDir();
    if (!home || !port) return;
    
    const statePath = `${home}/.config/firefox-theme-switcher/state.json`;
    
    const response = await new Promise((resolve) => {
      const handler = (msg) => {
        if (msg.hasOwnProperty('ok') || msg.hasOwnProperty('error')) {
          port.onMessage.removeListener(handler);
          resolve(msg);
        }
      };
      
      port.onMessage.addListener(handler);
      port.postMessage({ cmd: "read_file", path: statePath });
    });
    
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
    }
  } catch {
    // Ignore errors
  }
}

connectNative();

let startupApplied = false;

browser.runtime.onStartup.addListener(async () => {
  if (!startupApplied) {
    startupApplied = true;
    await applyStartupTheme();
  }
});

browser.runtime.onInstalled.addListener(async () => {
  if (!startupApplied) {
    startupApplied = true;
    try {
      await applyStartupTheme();
    } catch {
      await applyScheme("light");
    }
  }
});

setTimeout(async () => {
  if (!startupApplied) {
    startupApplied = true;
    let retries = 10;
    while (!port && retries > 0) {
      await new Promise(resolve => setTimeout(resolve, 100));
      retries--;
    }
    if (port) {
      await applyStartupTheme();
    }
  }
}, 200);
