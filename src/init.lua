local rawcode, reason = node.bootreason()
print ("bootreason: ", rawcode, reason)
print ("rtctime:    ", rtctime.get())
print ("value:      ", rtcmem.read32(127))

local STARTUP_DELAY = 3000

local starttimer = tmr.create()
starttimer:alarm(STARTUP_DELAY, tmr.ALARM_SINGLE, function()
    dofile("autostart.lua")
    if AUTOSTART == 1 then
        dofile("main.lua")
    end
end)
