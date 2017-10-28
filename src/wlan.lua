local WPA_CONFIG_FILE = "wpa.json"

function wlan_enable(success)
    local started = tmr.now()

    local conf
    local usingNextKey = false

    local function get_sta_config()
        if conf then
            if conf.nextKey then
                -- only if alternative is available: switch between them
                usingNextKey = not usingNextKey

                if usingNextKey then
                    print("original key is not working, trying alternative")
                else
                    print("alternative key is not working, trying original again")
                end
            end
        else
            -- initial call: load config
            conf = wlan_load_conf()
        end

        return {ssid=conf.ssid, pwd=usingNextKey and conf.nextKey or conf.key}
    end

    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(t)
        local time = (tmr.now() - started) / 1000000
        print(string.format("Connected to AP: %s after %.1fs", t.SSID, time))

        if usingNextKey then
            print("key switched, updating wpa config!")
            wlan_use_next_key(conf)
        end
    end)

    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
        print("\n\tSTA - DISCONNECTED".."\tSSID: "..T.SSID.."\tBSSID: "..T.BSSID.."\treason: "..T.reason)

        if T.reason == 2 then
            print("retrying AP connection...")
            wifi.sta.config(get_sta_config())
        end
    end)

    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function()
        local time = (tmr.now() - started) / 1000000
        print(string.format("Received IP: %s after %.1fs", wifi.sta.getip(), time))

        node.task.post(success)
    end)

    print("Connecting to AP...")
    wifi.setmode(wifi.STATION, false)
    wifi.sta.config(get_sta_config())
end

function wlan_disable(callback)
    wifi.sta.disconnect()
    wifi.setmode(wifi.NULLMODE, true)
    print("WLAN shutdown")
    node.task.post(callback)
end

-- try to load WPA config file or use defaults from global configuration
function wlan_load_conf()
    if file.open(WPA_CONFIG_FILE, "r") then
        local conf = sjson.decode(file.read())
        file.close()
        print("wpa config read")
        return conf
    else
        return {ssid=WLAN_SSID, key=WLAN_PASS}
    end
end

-- store passed config in WPA config file
function wlan_store_conf(conf)
    local json = sjson.encode(conf)

    if file.open(WPA_CONFIG_FILE, "w") then
        file.write(json)
        file.close()
        print("wpa config written")
    end
end

-- store passed key for eventual usage as replacement for WPA
function wlan_set_next_key(nextKey)
    local conf = wlan_load_conf()
    if nextKey and nextKey ~= conf.nextKey then
        conf.nextKey = nextKey
        wlan_store_conf(conf)
    end
end

-- replacement key works: drop old key and adjust WPA config file
function wlan_use_next_key(conf)
    if conf.nextKey then
        conf.key = conf.nextKey
        conf.nextKey = nil
        wlan_store_conf(conf)
    end
end
