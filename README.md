Tor ➜ HTTP Relay (Droplet Edition)

Purpose
Provide a single HTTPS/HTTP endpoint that forwards every request through Tor’s SOCKS port so any cloud function (e.g. Supabase Edge) can call a .onion API.

⸻

1  Create the droplet

Setting	Value
Image	Ubuntu 22.04 x64
Plan	Basic $4/mo (512 MB RAM)
Region	closest to the gateway / Spark box
SSH key	paste your id_ed25519.pub (or any pub-key)

After it boots, note the public IP (used below as $IP).

⸻

2  Initial login

ssh root@$IP   # no password prompt if key added
apt update -y && apt install -y tor privoxy ufw


⸻

3  Configure Tor (client-only)

/etc/tor/torrc

SOCKSPort 9050
Log notice stdout

systemctl restart tor


⸻

4  Configure Privoxy → Tor

/etc/privoxy/config

listen-address  0.0.0.0:8080      # public HTTP port
permit-connect 80
permit-connect 443
forward-socks5t / 127.0.0.1:9050 .
# Basic auth (optional but recommended)
auth-basic relay SuperSecret123

systemctl restart privoxy
systemctl enable  tor privoxy


⸻

5  Open the firewall

ufw allow OpenSSH
ufw allow 8080/tcp
ufw --force enable


⸻

6  Test the relay

curl -x "http://relay:SuperSecret123@$IP:8080" \
     "http://<your-onion>/goip_get_status.html?username=root&password=root&version=1.1"
# → JSON reply means success


⸻

7  Using from Supabase Edge (Deno)

await fetch(`http://$IP:8080/goip_post_sms.html?username=root&password=root`, {
  method: "POST",
  headers: {
    "content-type": "application/json",
    "Authorization": "Basic " + btoa("relay:SuperSecret123"),
  },
  body: JSON.stringify(payload),   // your SMS JSON
  timeout: 15000,
});


⸻

8  (Option) Add HTTPS with Let’s Encrypt

apt install -y nginx certbot python3-certbot-nginx
certbot --nginx -d relay.example.com
# add reverse-proxy block: 443 → 8080


⸻

9  Security checklist
	•	Change relay/SuperSecret123 to long random strings.
	•	Keep droplet updated: unattended-upgrades.
	•	Monitor logs: journalctl -u tor -u privoxy -f.
	•	Shut down the droplet when not needed to avoid charges (power off in panel).

⸻

One-liner to reinstall on a fresh droplet

apt update -y && apt install -y tor privoxy ufw && \
cat > /etc/tor/torrc <<'EOF1' && \
SOCKSPort 9050
Log notice stdout
EOF1
cat > /etc/privoxy/config <<'EOF2' && \
listen-address  0.0.0.0:8080
permit-connect 80
permit-connect 443
forward-socks5t / 127.0.0.1:9050 .
auth-basic relay SuperSecret123
EOF2
systemctl restart tor privoxy && systemctl enable tor privoxy && \
ufw allow OpenSSH && ufw allow 8080/tcp && ufw --force enable


⸻

Last updated 2025-06-17


# Proxy access 


# Tor ➜ Privoxy ➜ Nginx Relay (2025‑06‑17)

A **single HTTP endpoint** on your droplet that forwards every request through Tor to your GOIP `.onion` API, protected by a simple `X‑API‑KEY` header.

```
Browser / Backend
   │  X‑API‑KEY
   ▼
┌───────────────────────────────┐  http://$IP:8080/…
│       Nginx 1.24 (port 8080)  │───► Host header →
│  • API‑key gate               │    127.0.0.1:8118
│  • Adds correct Host header   │
└───────────────────────────────┘
               │               Privoxy HTTP proxy
               │ 127.0.0.1:8118  • forward‑socks5t → 127.0.0.1:9050
               ▼
           Tor SOCKS (9050)
               │
               ▼
          GOIP Gateway (.onion)
```

---

## 0 Droplet specs

* Ubuntu 22.04 (x64) • Basic 512 MB (\$4/mo)
* Public IP used below as **\$IP**
* UFW firewall enabled

---

## 1 Install packages

```bash
apt update -y && apt install -y tor privoxy nginx ufw
```

---

## 2 Tor: minimal client

`/etc/tor/torrc`

```conf
SOCKSPort 9050
Log notice stdout
```

```bash
systemctl restart tor && systemctl enable tor
```

---

## 3 Privoxy: internal proxy

`/etc/privoxy/config`

```conf
listen-address               127.0.0.1:8118
permit-connect               80
permit-connect               443
forward-socks5t /            127.0.0.1:9050 .
max-client-connections       100
accept-intercepted-requests  1
```

```bash
systemctl restart privoxy && systemctl enable privoxy
```

---

## 4 Nginx: public endpoint (port 8080)

`/etc/nginx/conf.d/relay.conf`

```nginx
server {
    listen 8080;
    server_name _;               # works for direct-IP access

    # 1️⃣ API‑key gate
    if ($http_x_api_key != "MyVeryLongBrowserKey123") { return 403; }

    # 2️⃣ Send correct Host header to Privoxy
    proxy_set_header Host t3c2gaz4wintmdl6d6lytuuvuvsmfopb6ufx7o52pdxsfa7sdqwn5uid.onion;

    location / {
        proxy_pass http://127.0.0.1:8118;   # Privoxy
    }
}
```

```bash
nginx -t && nginx -s reload
```

*(Optional) Later switch to HTTPS: run `certbot --nginx -d relay.example.com`, change `listen 8080;` to `listen 443 ssl;` and update firewall.*

---

## 5 Firewall

```bash
ufw allow OpenSSH
ufw allow 8080/tcp
ufw --force enable
```

---

## 6 Sanity checks

### 6‑a Local (droplet)

```bash
curl -x http://127.0.0.1:8118 \
     "http://<onion>/goip_get_status.html?username=root&password=root&version=1.1"
```

### 6‑b External

```bash
curl -H "X-API-KEY: MyVeryLongBrowserKey123" \
     "http://$IP:8080/goip_get_status.html?username=root&password=root&version=1.1"
```

Both should return the GOIP JSON status.

---

## 7 Supabase Edge Function snippet

```ts
const url = `http://${process.env.RELAY_IP}:8080/goip_post_sms.html` +
            `?username=${process.env.GOIP_USER}&password=${process.env.GOIP_PASS}`;

await fetch(url, {
  method: "POST",
  headers: {
    "content-type": "application/json",
    "X-API-KEY": "MyVeryLongBrowserKey123",
  },
  body: JSON.stringify({
    version: "1.1",
    type: "send-sms",
    task_num: 1,
    tasks: [{ tid: Date.now(), from: "5A", to: "+15551234567", sms: "Hi" }]
  }),
  timeout: 15000,
});
```

---

## 8 One‑liner rebuild (fresh droplet)

```bash
apt update -y && apt install -y tor privoxy nginx ufw && \
echo -e 'SOCKSPort 9050\nLog notice stdout' > /etc/tor/torrc && \
cat > /etc/privoxy/config <<'PCFG' && \
listen-address 127.0.0.1:8118
permit-connect 80
permit-connect 443
forward-socks5t / 127.0.0.1:9050 .
max-client-connections 100
accept-intercepted-requests 1
PCFG
cat > /etc/nginx/conf.d/relay.conf <<'NCFG' && \
server {
    listen 8080;
    server_name _;
    if ($http_x_api_key != "MyVeryLongBrowserKey123") { return 403; }
    proxy_set_header Host t3c2gaz4wintmdl6d6lytuuvuvsmfopb6ufx7o52pdxsfa7sdqwn5uid.onion;
    location / { proxy_pass http://127.0.0.1:8118; }
}
NCFG
systemctl restart tor privoxy nginx && systemctl enable tor privoxy nginx && \
ufw allow OpenSSH && ufw allow 8080/tcp && ufw --force enable
```

---

### Notes / troubleshooting

* **403** → wrong or missing `X-API-KEY`.
* **Invalid header** → ensure `accept-intercepted-requests 1` and no stray auth headers.
* **Connection refused** → check Privoxy (`systemctl status privoxy`) and port bindings (`ss -ltnp`).

# Current : 
test proxy 
curl -x http://127.0.0.1:8118 \
     "http://t3c2gaz4wintmdl6d6lytuuvuvsmfopb6ufx7o52pdxsfa7sdqwn5uid.onion/goip_get_status.html?username=root&password=root&version=1.1"

apikey lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9
password zynJyc-tysvat-2
request: 
curl -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
     "http://167.172.133.156:8080/goip_get_status.html?username=root&password=zynJyc-tysvat-2&version=1.1"

get sms: 
curl -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
     "http://167.172.133.156:8080/goip_get_sms.html?username=root&password=zynJyc-tysvat-2&op=get&port=27A&box=1&version=1.1"


## send sms 

curl -X POST \
  -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
  "http://167.172.133.156:8080/goip_post_sms.html?username=root&password=zynJyc-tysvat-2" \
  -H "Content-Type: application/json" \
  -d '{
        "version": "1.1",
        "type": "send-sms",
        "task_num": 1,
        "tasks": [{
            "tid": 5011,
            "from": "21.01",
            "to": "19543190477",
            "sms": "Test via API",
            "chs": "utf8",
            "coding": 0
        }]
      }'


## previous 
     # A) international digits, NO '+'
     TO1="19543190477" {works!}

     # B) national 10-digit, if SIM and number are on same US carrier
     TO2="9543190477"

     curl -X POST \
     -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
     "http://167.172.133.156:8080/goip_post_sms.html?username=root&password=zynJyc-tysvat-2" \
     -H "Content-Type: application/json" \
     -d '{
          "version":"1.1",
          "type":"send-sms",
          "task_num":1,
          "tasks":[{
               "tid":5011,
               "from":"1A",
               "to":"16465874352",
               "sms":"Test plain digits",
               "chs":"utf8",
               "coding":0
          }]
          }'



# Tor address 
http://t3c2gaz4wintmdl6d6lytuuvuvsmfopb6ufx7o52pdxsfa7sdqwn5uid.onion/
