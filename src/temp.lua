
temp = {};

function temp.init(pin)
    local self = {
        temp = nil
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
        ds18b20.read(done_measuring, {});
    end

    -- called when measurement is done
    function done_measuring(ind, rom, res, temp, tdec, par)
        self.temp = temp

        print(ind,
              string.format("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X", string.match(rom,"(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)"))
            ,res,temp,tdec,par)

        if self.callback then
            node.task.post(self.callback)
        end

        if self.CONTINUOUS then
            node.task.post(do_measure)
        end
    end

    ds18b20.setup(pin or 2)

    return self
end
