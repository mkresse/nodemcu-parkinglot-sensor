dofile("config.lua")
dofile("sr04.lua")
dofile("wlan.lua")
dofile("mqtt.lua")
dofile("temp.lua")

function main()
    -- enable vcc measurement
    if adc.force_init_mode(adc.INIT_ADC) then
        print("Switching ADC to EXT mode")
        node.restart()
        return -- don't bother continuing, the restart is scheduled
    end

    -- disable sensor
    hcsr04.enable(false)

    print("Starting up...")

    local sec, usec = rtctime.get()
    local initialized = rtcmem.read32(RTC_POS_INITIALIZED)
    if (sec == 0 or initialized ~= 1) then
        on_powerup(sec)
    else
        on_wakeup(sec)
    end

    setupFailureTimeout()
end


function on_powerup(time)
    if time == 0 then
        print("POWER UP", tmr.now(), tmr.time(), time)
        rtctime.set(time, 0)
        rtcmem.write32(RTC_POS_ERR_COUNT, 0)
    else
        print("RETRY INITIALIZATION", tmr.now(), tmr.time(), time)
    end

    rtcmem.write32(RTC_POS_INITIALIZED, 0)
    rtcmem.write32(RTC_POS_VALUE, PL_UNDEFINED)
    rtcmem.write32(RTC_POS_NEXT_CHECKIN, time + CHECKIN_TIME)
    rtcmem.write32(RTC_POS_SUCC_SAMPLE_COUNT, 0)
    rtcmem.write32(RTC_POS_SUCC_CHECKIN_COUNT, 0)

    wlan_enable(function()
        print("WLAN on")

        powerupBeacon(function()
            rtcmem.write32(RTC_POS_INITIALIZED, 1)
            print("successfully initialized")

            wlan_disable(function()
                print(string.format("WLAN off, sleeping %ds...", 1))

                -- trigger initial reading
                rtctime.dsleep(1 * 1000 * 1000, 4)
            end)
        end)
    end)
end

function powerupBeacon(callback)
    print("publishing powerup status...")

    local m = mqtt_create_client()

    mqtt_send(m, function(client)
        local topic = "parking/"..MQTT_TOPICID
        mqtt_publish(client, topic.."/event", "POWER_UP", 0, 0, function()
            print("ALL published")
            client:close()
            node.task.post(callback)
        end)
    end)
end

function getStatus(sensor)
    if sensor.distance > TAKEN_THRESHOLD then
        return PL_FREE
    elseif sensor.distance > 0 then
        return PL_TAKEN
    else
        return PL_UNDEFINED
    end
end

function on_wakeup(time)
    print("DSLEEP wakeup", tmr.now(), tmr.time(), time)

    local lastValue = rtcmem.read32(RTC_POS_VALUE)
    -- read voltage before wlan
    local vin =  adc.read(0) * ADC_FACTOR

    local sensor = hcsr04.init(6,1,7)
    sensor.measure(function()
        hcsr04.enable(false)
        rtcmem.write32(RTC_POS_SUCC_SAMPLE_COUNT, rtcmem.read32(RTC_POS_SUCC_SAMPLE_COUNT) + 1)

        local newValue = getStatus(sensor)
        local isChanged = (lastValue ~= newValue)
        if isChanged then
            print("  CHANGED from: "..lastValue.." to "..newValue)
        end

        local nextCheckin = rtcmem.read32(RTC_POS_NEXT_CHECKIN)
        local doCheckin = time >= nextCheckin
        if (doCheckin) then
            print("  CHECKIN OVERDUE!")
        end

        if isChanged or doCheckin then

            local tempInstance
            if (MEASURE_TEMPERATURE) then
                tempInstance = temp.init()
                -- assume measurement is faster than WLAN setup
                tempInstance.measure()
            end

            wlan_enable(function()
                print("WLAN on")

                sendBeacon(newValue, isChanged, sensor, tempInstance, vin, function()
                    rtcmem.write32(RTC_POS_VALUE, newValue)
                    rtcmem.write32(RTC_POS_NEXT_CHECKIN, time + CHECKIN_TIME)
                    rtcmem.write32(RTC_POS_ERR_COUNT, 0)
                    rtcmem.write32(RTC_POS_SUCC_CHECKIN_COUNT, rtcmem.read32(RTC_POS_SUCC_CHECKIN_COUNT) + 1)

                    wlan_disable(function()
                        print(string.format("WLAN off, sleeping %ds...", SLEEP_TIME))
                        print()

                        rtctime.dsleep(SLEEP_TIME * 1000 * 1000, 4)
                    end)
                end)
            end)
        else
            print(string.format("no change, sleeping %ds...", SLEEP_TIME))
            print()

            rtctime.dsleep(SLEEP_TIME * 1000 * 1000, 4)
        end
    end)
end



function sendBeacon(status, isChanged, hc1, tempInstance, vin, callback)
    print("publishing status...")

    local m = mqtt_create_client()

    mqtt_send(m, function(client)
        local topic = "parking/"..MQTT_TOPICID

        local event = "CHECKIN"
        if isChanged then event = "STATUS_CHANGED" end
        local uptime = rtctime.get()

        mqtt_publish(client, topic.."/status", status, 0, 1)
        mqtt_publish(client, topic.."/distance", hc1.distance, 0, 1)
        mqtt_publish(client, topic.."/sd", hc1.sd, 0, 1)
        mqtt_publish(client, topic.."/cv", hc1.cv, 0, 1)
        mqtt_publish(client, topic.."/vin", vin, 0, 1)
        mqtt_publish(client, topic.."/rssi", wifi.sta.getrssi(), 0, 1)
        mqtt_publish(client, topic.."/uptime", uptime, 0, 1)

        if tempInstance then
            mqtt_publish(client, topic.."/temp", tempInstance.temp, 0, 1)
        end

        mqtt_publish(client, topic.."/sampleCount", rtcmem.read32(RTC_POS_SUCC_SAMPLE_COUNT), 0, 1)
        mqtt_publish(client, topic.."/checkinCount", rtcmem.read32(RTC_POS_SUCC_CHECKIN_COUNT), 0, 1)

        local errCount = rtcmem.read32(RTC_POS_ERR_COUNT)
        if errCount > 0 then
            mqtt_publish(client, topic.."/lastErrors", errCount, 0, 1)
        end

        if vin <= LOW_BATTERY_WARNING_LIMIT then
            mqtt_publish(client, topic.."/event", "LOW_BATTERY", 1, 0)
        end

        mqtt_publish(client, topic.."/event", event, 0, 0, function()
            print("ALL published")
            client:close()
            node.task.post(callback)
        end)
    end)
end

function setupFailureTimeout()
    tmr.create():alarm(GLOBAL_TIMEOUT, tmr.ALARM_SINGLE, function()
        print("Timeout reached!")

        local errCount = rtcmem.read32(RTC_POS_ERR_COUNT) + 1
        rtcmem.write32(RTC_POS_ERR_COUNT, errCount)

        local retryTime = math.pow(2, math.min(errCount, 8))

        print(string.format("Retry #%d in %ds...", errCount, retryTime))
        print()

        rtctime.dsleep(retryTime * 1000 * 1000, 4)
    end)
end

-- start application
main()
