local module, M = ..., {}

local WPA_CONFIG_FILE = "wpa.json"
local usingNextKey = false


-- return (possibly alternating) sta config
function M.get_next_sta_conf()
    if M.conf then
        if M.conf.nextKey then
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
        M.conf = M.load_conf()
    end

    return {ssid=M.conf.ssid, pwd=usingNextKey and M.conf.nextKey or M.conf.key}
end


-- if next key is used, update config file
function M.update_conf()
    if usingNextKey then
        print("key switched, updating wpa config!")
        M.use_next_key(M.conf)
    end
end


-- try to load WPA config file or use defaults from global configuration
function M.load_conf()
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
function M.store_conf(conf)
    local json = sjson.encode(conf)

    if file.open(WPA_CONFIG_FILE, "w") then
        file.write(json)
        file.close()
        print("wpa config written")
    end
end

-- store passed key for eventual usage as replacement for WPA
function M.set_next_key(nextKey)
    local conf = M.load_conf()
    if nextKey and nextKey ~= conf.nextKey then
        conf.nextKey = nextKey
        M.store_conf(conf)
    end
end

-- replacement key works: drop old key and adjust WPA config file
function M.use_next_key(conf)
    if conf.nextKey then
        conf.key = conf.nextKey
        conf.nextKey = nil
        M.store_conf(conf)
    end
end

local function construct()
    package.loaded[module] = nil
    return M
end

return construct