
function wlan_enable(success)
    local started = tmr.now()

    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(t)
        local time = (tmr.now() - started) / 1000000
        print(string.format("Connected to AP: %s after %.1fs", t.SSID, time))
    end)

    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function()
        local time = (tmr.now() - started) / 1000000
        print(string.format("Received IP: %s after %.1fs", wifi.sta.getip(), time))

        node.task.post(success)
    end)

    print("Connecting to AP...")
    wifi.setmode(wifi.STATION, false)
    wifi.sta.config({ssid=WLAN_SSID, pwd=WLAN_PASS})
end

function wlan_disable(callback)
    wifi.sta.disconnect()
    wifi.setmode(wifi.NULLMODE, true)
    print("WLAN shutdown")
    node.task.post(callback)
end
