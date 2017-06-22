function mqtt_create_client()
    local m = mqtt.Client(MQTT_CLIENTID, 10)

    -- setup Last Will and Testament (optional)
    m:lwt("parking/"..MQTT_TOPICID.."/lwt", MQTT_CLIENTID.." unexpected disconnection", 0, 0)
    
    m:on("connect", function(client) print ("mqtt connected") end)
    m:on("offline", function(client) print ("mqtt offline") end)
    
    -- on publish message receive event
    m:on("message", function(client, topic, data) 
      print(topic .. ":" ) 
      if data ~= nil then
        print(data)
      end
    end)

    return m
end

function mqtt_send(m, callback)
    print(string.format("connecting to %s : %d", MQTT_SERVER, MQTT_PORT))
    m:connect(MQTT_SERVER, MQTT_PORT, 0, function(client)
      print("mqtt connected")
      
      callback(client)
    end,
    function(client, reason)
      print("mqtt failed reason: " .. reason)
    end)
end

MQTT_PUB_COUNT=0
MQTT_PUB_FINAL_CALLBACK=nil

function mqtt_pub_callback()
    MQTT_PUB_COUNT = MQTT_PUB_COUNT - 1
    if MQTT_PUB_COUNT == 0 and MQTT_PUB_FINAL_CALLBACK then
        print("all mqtt publish done")
        MQTT_PUB_FINAL_CALLBACK()
    end
end

function mqtt_publish(client, topic, payload, qos, retain, cb)
    MQTT_PUB_COUNT=MQTT_PUB_COUNT + 1
    MQTT_PUB_FINAL_CALLBACK=cb
    print(string.format("  mqtt publish %s = %s", topic, payload))
    client:publish(topic, payload, qos, retain, mqtt_pub_callback)
end

function testmqtt()

    dofile("config.lua")
    dofile("wlan.lua")
    dofile("sr04.lua")
    
    local m = mqtt_create_client()
    
    wlan_enable(function()
        mqtt_send(m, function(client)

          -- subscribe topic with qos = 0
          client:subscribe("#", 0, function(client) print("subscribe success") end)

          -- publish a message with data = hello, QoS = 0, retain = 0
          client:publish("/topic", "Hello World!", 0, 0, function(client) print("sent") end)
        
          local hc1 = hcsr04.init()
          hc1.measure(function()
            client:publish("parking/"..MQTT_TOPICID.."/distance", hc1.distance, 0, 1)
            client:publish("parking/"..MQTT_TOPICID.."/sd", hc1.sd, 0, 1)
            client:publish("parking/"..MQTT_TOPICID.."/cv", hc1.cv, 0, 1)
            client:publish("parking/"..MQTT_TOPICID.."/vcc", adc.readvdd33(), 0, 1)
          end)

        end)
    end)

end
