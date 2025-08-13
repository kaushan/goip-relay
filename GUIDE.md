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

settings 
port: all or number (27A)
box: 1 or 2

get sms: 
curl -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
     "http://167.172.133.156:8080/goip_get_sms.html?username=root&password=zynJyc-tysvat-2&op=get&port=allA&box=1&version=1.1"


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
            "from": "23",   
            "to": "19543190477",
            "sms": "Test via API 23.01",
            "chs": "utf8",
            "coding": 0
        }]
      }'


{"code":200, "reason":"OK", "type":"task-status","status":[{"tid":5011,"status":"0 OK"}]}

- port only on number and it will use active sim to send 

## swtich port 

curl -X POST \
  -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
  "http://167.172.133.156:8080/goip_send_cmd.html?username=root&password=zynJyc-tysvat-2" \
  -H "Content-Type: application/json" \
  -d '{"type":"command","op":"switch","ports":"23.01"}'

{"code":0, "reason":"OK"}%  

## reset port 
GET /goip_send_cmd.html?Version=1.1&type=command&op=reset&ports=23&username=USER&password=PASS

curl -X POST \
  -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
  "http://167.172.133.156:8080/goip_send_cmd.html?username=root&password=zynJyc-tysvat-2" \
  -H "Content-Type: application/json" \
  -d '{"type":"command","op":"reset","ports":"23"}'

## Lock port 
goip_send_cmd.html?username=USER&password=PASS&Version=1.1
&type=command&op=lock&ports=23

curl -X POST \
  -H "X-API-KEY: lAzDbl0r6mg7HR4zQkQ3FxKFGFkkzJo9" \
  "http://167.172.133.156:8080/goip_send_cmd.html?username=root&password=zynJyc-tysvat-2" \
  -H "Content-Type: application/json;charset=utf-8" \
  -d '{"type":"command","op":"lock","ports":"23"}'




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
               "from":"5A",
               "to":"'"$TO1"'",
               "sms":"Test plain digits",
               "chs":"utf8",
               "coding":0
          }]
          }'



# Tor address 
http://t3c2gaz4wintmdl6d6lytuuvuvsmfopb6ufx7o52pdxsfa7sdqwn5uid.onion/
root
zynJyc-tysvat-2