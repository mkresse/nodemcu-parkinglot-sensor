
hcsr04 = {};

function hcsr04.enable(value, pin_enable)
    local pin = pin_enable or 7
    gpio.mode(pin, gpio.OUTPUT)

    if value then
        gpio.write(pin, gpio.HIGH)
    else
        gpio.write(pin, gpio.LOW)
    end
end

function hcsr04.init(pin_trig, pin_echo, pin_enable)
    local self = {
        time_start = 0, time_stop = 0, distance = 0, sd = 0, cv = 0, readings = {}
    }

    -- start a measure cycle
    function self.measure(callback)
        self.callback = callback
        do_measure()
    end

    function self.measure_cont()
        self.CONTINUOUS = true
        do_measure()
    end

    function do_measure()
        self.readings = {}
        self.timer:start()
    end

    -- called when measure is done
    function done_measuring()
        print("Distance: " .. string.format("%.2f", self.distance) ..
                " Readings: " .. #self.readings ..
                " sd:" .. string.format("%.3f", self.sd) ..
                " cv:" .. string.format("%.3f", self.cv))

        if self.callback then
            node.task.post(self.callback)
        end

        if self.CONTINUOUS then
            node.task.post(do_measure)
        end
    end

    -- distance calculation, called by the echo_callback function on falling edge.
    function calculate()

        -- echo time (or high level time) in seconds
        local echo_time = (self.time_stop - self.time_start) / 1000000

        -- got a valid reading
        if echo_time > 0 then
            -- distance = echo time (or high level time) in seconds * velocity of sound (340M/S) / 2
            local distance = echo_time * 340 / 2
            table.insert(self.readings, distance)
        end

        -- got all readings
        if #self.readings >= self.AVG_READINGS then
            self.timer:stop()

            -- calculate the average of the readings
            local sum = 0
            for _, v in pairs(self.readings) do
                sum = sum + v
            end
            local avg = sum / #self.readings

            local squareSum = 0
            for _, v in pairs(self.readings) do
                local diff = (v - avg)
                squareSum = squareSum + (diff * diff)
            end

            self.sd = math.sqrt(squareSum / (#self.readings - 1))
            self.cv = self.sd / avg

            self.distance = 0
            local valid = 0
            for _, v in pairs(self.readings) do
                if (math.abs(v - avg) <= self.sd) then
                    self.distance = self.distance + v
                    valid = valid + 1
                end
            end

            if valid > 0 then
                self.distance = self.distance / valid
            end

            node.task.post(done_measuring)
        end
    end

    -- echo callback function called on both rising and falling edges
    function echo_callback(level)
        if level == 1 then
            -- rising edge (low to high)
            self.time_start = tmr.now()
        else
            -- falling edge (high to low)
            self.time_stop = tmr.now()
            calculate()
        end
    end

    -- send trigger signal
    function trigger()
        gpio.write(self.TRIG_PIN, gpio.HIGH)
        tmr.delay(self.TRIG_INTERVAL)
        gpio.write(self.TRIG_PIN, gpio.LOW)
    end

    self.TRIG_PIN = pin_trig or 2
    self.ECHO_PIN = pin_echo or 1

    -- trig interval in microseconds (minimun is 10, see HC-SR04 documentation)
    self.TRIG_INTERVAL = 15

    -- maximum distance in meters
    self.MAXIMUM_DISTANCE = 10

    -- minimum reading interval with 20% of margin
    self.READING_INTERVAL = math.ceil(((self.MAXIMUM_DISTANCE * 2 / 340 * 1000) + self.TRIG_INTERVAL) * 1.2)

    -- number of readings to average
    self.AVG_READINGS = 3

    -- CONTINUOUS MEASURING
    self.CONTINUOUS = false

    hcsr04.enable(true, pin_enable)

    -- configure pins
    gpio.mode(self.TRIG_PIN, gpio.OUTPUT)
    gpio.mode(self.ECHO_PIN, gpio.INT)

    -- trigger timer
    self.timer = tmr.create()
    self.timer:register(self.READING_INTERVAL, tmr.ALARM_AUTO, trigger)

    -- set callback function to be called both on rising and falling edges
    gpio.trig(self.ECHO_PIN, "both", echo_callback)

    return self
end
