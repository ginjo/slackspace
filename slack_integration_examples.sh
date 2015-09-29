###  SLACK STUFF  ###

# WbrSandboxWebhook incoming-webhook integration URL
wbr_sandbox_webhook='https://hooks.slack.com/services/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'

# CerneOps incoming-webhook integration URL
cerne_ops_webhook='https://hooks.slack.com/services/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'

# Integration (incoming-webhook) to send a message to wbrsandbox.slack.com.
curl $wbr_sandbox_webhook -d '{"text": "This is a line of text in a channel.\nAnd this is another line of text."}'

# This works too.
curl $wbr_sandbox_webhook -d @- <<EOF
{"text": "This is a message passed as here-doc at end of curl command."}
EOF

# SiteUptime integrates nicely with Slack. They will send this kind of data (below),
# but it won't show up like that. I think SUT reformats specifically for Slack.
{
  "MonitorId": "1234",
  "MonitorName": "Main server",
  "Host_Url": "domain.com",
  "Service": "http",
  "Date": "2014-07-25 10:24:01",
  "Result": "Failed",
  "Error": "Connection timed out"
}

# A more advanced curl example
curl $wbr_sandbox_webhook -d @- <<EOF
{"channel": "#general", "username": "webhookbot", "text": "This is posted to #general and comes from a bot named webhookbot.", "icon_emoji": ":ghost:"}
EOF

# A Slackbot integration (like incoming-webhook but less flexible?).
curl 'https://wbrsandbox.slack.com/services/hooks/slackbot?token=9lMNvdA9tQ3BrT8CNOBPADgC&channel=%23general' -d @- <<EOF
Hey this is a big hello from Slackbot integration.
EOF


rackspace_test_hook='
{
    "event_id": "test_check",
    "log_entry_id": "ntXetimnKt",
    "details": {
        "target": "www.example.com",
        "timestamp": 1443462921906,
        "metrics": {
            "tt_firstbyte": {
                "type": "I",
                "data": 2,
                "unit": "unknown"
            },
            "duration": {
                "type": "I",
                "data": 2,
                "unit": "unknown"
            },
            "bytes": {
                "type": "i",
                "data": 17,
                "unit": "unknown"
            },
            "tt_connect": {
                "type": "I",
                "data": 0,
                "unit": "unknown"
            },
            "code": {
                "type": "s",
                "data": "200",
                "unit": "unknown"
            }
        },
        "state": "CRITICAL",
        "status": "Critical Error :-(",
        "txn_id": ".rh-q6GU.h-api1.ord1.prod.cm.k1k.me.r-xjbGojRZ.c-40810954.ts-1443462921723.v-7dc593a",
        "observations": [
            {
                "monitoring_zone_id": "mzTEST1",
                "state": "CRITICAL",
                "status": "Critical Error :-(",
                "timestamp": 1443462921906,
                "collectorState": "UP"
            },
            {
                "monitoring_zone_id": "mzTEST2",
                "state": "WARNING",
                "status": "Warning :-/",
                "timestamp": 1443462911906
            },
            {
                "monitoring_zone_id": "mzTEST3",
                "state": "OK",
                "status": "Rocking (all good)!",
                "timestamp": 1443462891906
            }
        ]
    },
    "entity": {
        "id": "enTEST",
        "label": "Test Entity",
        "ip_addresses": {
            "default": "203.0.113.1"
        },
        "metadata": null,
        "managed": false,
        "uri": null,
        "agent_id": "agentA"
    },
    "check": {
        "id": "chTEST",
        "label": "Check Testing Notifications",
        "type": "remote.http",
        "details": {
            "url": "http://www.example.com",
            "method": "GET",
            "follow_redirects": true,
            "include_body": false
        },
        "monitoring_zones_poll": [
            "mzTEST1",
            "mzTEST2",
            "mzTEST3"
        ],
        "timeout": 30,
        "period": 60,
        "target_alias": "default",
        "target_hostname": null,
        "target_resolver": "",
        "disabled": false,
        "metadata": null,
        "confd_name": null,
        "confd_hash": null
    },
    "alarm": {
        "id": "alTEST",
        "label": "Alarm Testing Notifications",
        "check_type": null,
        "check_id": "chTEST",
        "entity_id": "enTEST",
        "criteria": "if (metric[\"t\"] >= 2.1) { return CRITICAL } return OK",
        "disabled": false,
        "notification_plan_id": null,
        "metadata": null,
        "confd_name": null,
        "confd_hash": null
    },
    "tenant_id": "545570"
}
'
