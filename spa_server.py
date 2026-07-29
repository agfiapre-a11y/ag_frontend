#!/usr/bin/env python3
"""Simple SPA-aware static file server for Flutter web builds.
Falls back to index.html for any path that doesn't match a real file,
so client-side routes (e.g. /login, /dashboard) work correctly.

Supports HTTPS with a self-signed certificate for local development
(PECR / UK GDPR Art. 32 — encryption in transit).
"""
import http.server
import os
import ssl
import sys
import subprocess

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
USE_HTTPS = os.environ.get("USE_HTTPS", "1").lower() in ("1", "true", "yes")
CERT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "certs")
CERT_FILE = os.path.join(CERT_DIR, "cert.pem")
KEY_FILE = os.path.join(CERT_DIR, "key.pem")


def generate_self_signed_cert():
    """Generates a self-signed TLS certificate using openssl."""
    os.makedirs(CERT_DIR, exist_ok=True)
    if os.path.isfile(CERT_FILE) and os.path.isfile(KEY_FILE):
        return
    print("Generating self-signed TLS certificate...")
    # Collect all local IP addresses for the certificate's subjectAltName
    import socket
    local_ips = ["127.0.0.1"]
    try:
        hostname = socket.gethostname()
        for info in socket.getaddrinfo(hostname, None):
            ip = info[4][0]
            if ":" not in ip and ip not in local_ips:  # IPv4 only, no duplicates
                local_ips.append(ip)
    except Exception:
        pass
    san_parts = [f"IP:{ip}" for ip in local_ips] + ["DNS:localhost"]
    san = ",".join(san_parts)
    subprocess.run([
        "openssl", "req", "-x509", "-newkey", "rsa:2048",
        "-keyout", KEY_FILE, "-out", CERT_FILE,
        "-days", "365", "-nodes",
        "-subj", "/CN=localhost",
        "-addext", f"subjectAltName={san}",
    ], check=True, capture_output=True)
    print(f"Certificate saved to {CERT_DIR} (SANs: {san})")


class SPARequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        requested_path = self.translate_path(self.path.split("?")[0])
        if not os.path.isfile(requested_path):
            self.path = "/index.html"
        return super().do_GET()


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), SPARequestHandler)

    if USE_HTTPS:
        try:
            generate_self_signed_cert()
            ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ctx.load_cert_chain(CERT_FILE, KEY_FILE)
            server.socket = ctx.wrap_socket(server.socket, server_side=True)
            print(f"Serving {DIRECTORY} at https://0.0.0.0:{PORT} (HTTPS, SPA fallback enabled)")
            print("NOTE: Browser will warn about self-signed certificate — accept to proceed.")
        except Exception as e:
            print(f"HTTPS setup failed ({e}), falling back to HTTP.")
            print(f"Serving {DIRECTORY} at http://0.0.0.0:{PORT} (SPA fallback enabled)")
            print("WARNING: HTTP is not secure. Set USE_HTTPS=1 and install openssl for HTTPS.")
    else:
        print(f"Serving {DIRECTORY} at http://0.0.0.0:{PORT} (SPA fallback enabled)")
        print("WARNING: HTTP is not secure. Set USE_HTTPS=1 for HTTPS (PECR / UK GDPR).")

    server.serve_forever()
