print ("bootreason: ", node.bootreason())
print ("rtctime:    ", rtctime.get())
print ("value:      ", rtcmem.read32(127))
print ("vin:        ", 3.3*2/1024*adc.read(0))

local STARTUP_DELAY = 3000

local starttimer = tmr.create()
starttimer:alarm(STARTUP_DELAY, tmr.ALARM_SINGLE, function()
    dofile("autostart.lua")
    if AUTOSTART == 1 then
        dofile("main.lua")
    end
end)
