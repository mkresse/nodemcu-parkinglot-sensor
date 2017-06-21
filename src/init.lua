local rawcode, reason = node.bootreason()
print ("bootreason: ", rawcode, reason)
print ("rtctime:    ", rtctime.get())
print ("value:      ", rtcmem.read32(127))

local STARTUP_DELAY = 3000

local starttimer = tmr.create()
starttimer:alarm(STARTUP_DELAY, tmr.ALARM_SINGLE, function()
    dofile("main.lua")
end)
