#!/usr/bin/env python3
import os, sys, json, struct, socket, pathlib, signal, select

def read_msg():
    rawlen = sys.stdin.buffer.read(4)
    if not rawlen:
        return None
    msglen = struct.unpack("<I", rawlen)[0]
    data = sys.stdin.buffer.read(msglen)
    if not data:
        return None
    return json.loads(data.decode("utf-8"))

def send_msg(obj):
    data = json.dumps(obj).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.flush()

runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or os.path.join(os.path.expanduser("~"), ".local", "run")
sock_path = os.path.join(runtime_dir, "firefox-theme-switcher.sock")
pathlib.Path(runtime_dir).mkdir(parents=True, exist_ok=True)

pending_client = None

def cleanup(*_):
    global pending_client
    try:
        if pending_client:
            pending_client.close()
        if os.path.exists(sock_path):
            os.unlink(sock_path)
    finally:
        sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)
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

def handle_extension_cmd(msg):
    cmd = msg.get("cmd")
    if cmd == "get_home":
        return {"home": os.path.expanduser("~")}
    if cmd == "read_file":
        path = msg.get("path")
        try:
            if path and os.path.exists(path):
                with open(path, 'r') as f:
                    data = f.read()
                return {"ok": True, "data": data}
            return {"ok": False, "error": "file not found", "path": path}
        except Exception as e:
            return {"ok": False, "error": str(e), "path": path}
    if cmd == "delete_file":
        path = msg.get("path")
        try:
            if path and os.path.exists(path):
                os.unlink(path)
                return {"ok": True, "deleted": path}
            return {"ok": False, "error": "file not found", "path": path}
        except Exception as e:
            return {"ok": False, "error": str(e), "path": path}
    return None

while True:
    rlist, _, _ = select.select([sys.stdin.buffer, srv], [], [])
    
    if sys.stdin.buffer in rlist:
        msg = read_msg()
        if msg is None:
            cleanup()
        
        resp = handle_extension_cmd(msg)
        if resp is not None:
            send_msg(resp)
        else:
            if pending_client and ("ok" in msg or "error" in msg):
                try:
                    pending_client.sendall((json.dumps(msg) + "\n").encode("utf-8"))
                except:
                    pass
                finally:
                    pending_client.close()
                    pending_client = None

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
                elif line in ["dark", "light"]:
                    payload = {"cmd": line}
                else:
                    payload = {"cmd": "set", "scheme": line}
            
            send_msg(payload)
            pending_client = conn
            
        except Exception as e:
            try:
                conn.sendall((json.dumps({"ok": False, "error": str(e)}) + "\n").encode("utf-8"))
            except:
                pass
            conn.close()