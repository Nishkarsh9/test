#!/usr/bin/env python3
import http.server
import socketserver
import sys

# Bind explicitly to the local loopback interface on port 5000
HOST = "127.0.0.1"
PORT = 5000

class TestingRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Handle the Nginx reverse proxy endpoint routing test
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        
        # Structure the payload response output HTML
        html_payload = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Python Routing Verification</title>
            <style>
                body { font-family: -apple-system, sans-serif; margin: 4rem; background: #f4f6f9; color: #333; }
                .card { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
                h1 { color: #2b6cb0; margin-top: 0; }
                code { background: #edf2f7; padding: 0.2rem 0.4rem; border-radius: 4px; font-family: monospace; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>🚀 Python 3.8 Routing Success!</h1>
                <p>Nginx successfully captured the incoming request on Port 80 and reverse-proxied it to <code>main.py</code> running on <code>127.0.0.1:5000</code>.</p>
                <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 1.5rem 0;">
                <p style="font-size: 0.9rem; color: #718096;">Container Status: <strong>Operational</strong></p>
            </div>
        </body>
        </html>
        """
        self.wfile.write(html_payload.strip().encode("utf-8"))

if __name__ == "__main__":
    print(f"Initializing development testing server loop at http://{HOST}:{PORT}")
    sys.stdout.flush() # Force immediate flush so it writes instantly to app.log
    
    # Enable socket re-use to prevent "Address already in use" errors on immediate rebuilds
    socketserver.TCPServer.allow_reuse_address = True
    
    try:
        with socketserver.TCPServer((HOST, PORT), TestingRequestHandler) as server:
            server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down testing socket engine clean.")
