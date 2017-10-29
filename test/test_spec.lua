require("config_test")

describe("nodemcu-parkinglot-sensor", function()

    it("should just work", function()
        assert.truthy("Yup.")
    end)

    it("should have a SSID defined", function()
        assert.truthy(WLAN_SSID)
    end)

end)
