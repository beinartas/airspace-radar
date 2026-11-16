#!/usr/bin/env python3
import http.server
import os
import urllib.request
import urllib.parse
import webbrowser
import threading

PORT = 8765
ROOT = os.path.dirname(os.path.abspath(__file__))


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/adsb":
            qs = urllib.parse.parse_qs(parsed.query)
            lat = qs.get("lat", [""])[0]
            lon = qs.get("lon", [""])[0]
            dist = qs.get("dist", [""])[0]
            if not (lat and lon and dist):
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'{"error":"missing params"}')
                return

            url = f"https://api.adsb.lol/v2/lat/{lat}/lon/{lon}/dist/{dist}"
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "SysAirspaceRadar/1.0"})
                with urllib.request.urlopen(req, timeout=8) as resp:
                    data = resp.read()
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(data)
            except Exception as exc:
                print(f"[502] {url} -> {exc}")
                self.send_response(502)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(b'{"error":"upstream failed"}')
            return

        super().do_GET()


if __name__ == "__main__":
    url = f"http://localhost:{PORT}/"
    print(f"AIRSPACE RADAR RUNNING AT {url}")
    threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    with http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")
