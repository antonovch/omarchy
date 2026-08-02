#!/usr/bin/env python3
import json, os, pathlib, select, signal, socket, struct, sys, time

STDIN_FD = sys.stdin.fileno()

def read_exact(n):
    """Read exactly n bytes from stdin fd (bypasses Python buffering)."""
    buf = b""
    while len(buf) < n:
        chunk = os.read(STDIN_FD, n - len(buf))
        if not chunk:
            return None
        buf += chunk
    return buf

def read_msg():
    rawlen = read_exact(4)
    if rawlen is None:
        return None
    msglen = struct.unpack("<I", rawlen)[0]
    data = read_exact(msglen)
    if data is None:
        return None
    return json.loads(data.decode("utf-8"))

def send_msg(obj):
    data = json.dumps(obj).encode("utf-8")
    payload = struct.pack("<I", len(data)) + data
    sys.stdout.buffer.write(payload)
    sys.stdout.buffer.flush()

# Paths
runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or os.path.join(os.path.expanduser("~"), ".local", "run")
sock_path = os.path.join(runtime_dir, "firefox-theme-switcher.sock")
config_dir = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
state_path = os.path.join(config_dir, "firefox-theme-switcher", "state.json")

pathlib.Path(runtime_dir).mkdir(parents=True, exist_ok=True)

pending_client = None
pending_client_time = None

def cleanup(*_):
    try:
        if pending_client:
            pending_client.close()
        if os.path.exists(sock_path):
            os.unlink(sock_path)
    finally:
        sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

# Create UNIX socket
try:
    if os.path.exists(sock_path):
        os.unlink(sock_path)
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(sock_path)
    os.chmod(sock_path, 0o600)
    srv.listen(5)
except Exception as e:
    send_msg({"host_error": str(e)})
    cleanup()

# On startup: send state file content or "restore" command to the extension.
# This replaces the old get_home/read_file/delete_file roundtrip protocol.
try:
    if os.path.exists(state_path):
        with open(state_path, "r") as f:
            state = json.loads(f.read())
        os.unlink(state_path)
        send_msg(state)
    else:
        send_msg({"cmd": "restore"})
except Exception:
    send_msg({"cmd": "restore"})

# Main event loop
while True:
    # Clean up stale pending client after 5 seconds
    if pending_client and pending_client_time and (time.time() - pending_client_time > 5):
        try:
            pending_client.close()
        except Exception:
            pass
        pending_client = None
        pending_client_time = None

    timeout = 1.0 if pending_client else None
    rlist, _, _ = select.select([STDIN_FD, srv], [], [], timeout)

    if STDIN_FD in rlist:
        msg = read_msg()
        if msg is None:
            cleanup()

        # Forward extension response to the waiting socket client
        if pending_client and ("ok" in msg or "error" in msg):
            try:
                pending_client.sendall((json.dumps(msg) + "\n").encode("utf-8"))
            except Exception:
                pass
            finally:
                try:
                    pending_client.close()
                except Exception:
                    pass
                pending_client = None
                pending_client_time = None

    if srv in rlist:
        conn, _ = srv.accept()
        try:
            if pending_client:
                conn.sendall(b'{"ok":false,"error":"busy"}\n')
                conn.close()
                continue

            data = b""
            while True:
                chunk = conn.recv(4096)
                if not chunk:
                    break
                data += chunk
                if b"\n" in data:
                    break
            line = data.decode("utf-8").strip()

            try:
                payload = json.loads(line)
            except Exception:
                if line == "toggle":
                    payload = {"cmd": "toggle"}
                elif line in ("dark", "light"):
                    payload = {"cmd": line}
                else:
                    payload = {"cmd": "applyThemeId", "themeId": line}

            send_msg(payload)
            pending_client = conn
            pending_client_time = time.time()

        except Exception as e:
            try:
                conn.sendall((json.dumps({"ok": False, "error": str(e)}) + "\n").encode("utf-8"))
            except Exception:
                pass
            conn.close()