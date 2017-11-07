require("config_test")

describe("keystore", function()

    it("should be volatile", function()
        local keystore = require("keystore")()

        assert.truthy(keystore)
        assert.is_nil(package.loaded["keystore"])
    end)


    it("should use defaults with no conf file", function()
        local keystore = require("keystore")()

        _G.file = mock({open=function() return false end })

        assert.are.same({ssid=WLAN_SSID, key=WLAN_PASS}, keystore.load_conf())

        assert.spy(file.open).was.called()
    end)


    it("should read and decode existing conf file", function()
        local keystore = require("keystore")()

        _G.file = mock({
            open = function() return true end,
            read = function() end,
            close = function() end
        })

        local conf = {}
        _G.sjson = mock({decode = function() return conf end})

        assert.are.equals(conf, keystore.load_conf())

        assert.spy(sjson.decode).was.called()
        assert.spy(file.open).was.called()
        assert.spy(file.read).was.called()
        assert.spy(file.close).was.called()
    end)


    it("should encode and store passed conf", function()
        local keystore = require("keystore")()

        _G.file = mock({
            open = function() return true end,
            write = function() end,
            close = function() end
        })

        local json = "foo"
        _G.sjson = mock({encode = function() return json end})

        local conf = {}

        keystore.store_conf(conf)

        assert.spy(sjson.encode).was.called_with(conf)
        assert.spy(file.open).was.called()
        assert.spy(file.write).was.called_with(json)
        assert.spy(file.close).was.called()
    end)


    it("should set next key and store conf", function()
        local keystore = require("keystore")()

        local oldConf = {ssid="ssid", key="old" }
        local newConf = {ssid="ssid", key="old", nextKey="next" }

        keystore.load_conf = spy.new(function() return oldConf end)
        stub(keystore, "store_conf")

        keystore.set_next_key("next")

        assert.spy(keystore.load_conf).was_called()
        assert.spy(keystore.store_conf).was_called_with(match.is_same(newConf))
    end)


    it("should ignore known next key", function()
        local keystore = require("keystore")()

        local conf = {ssid="ssid", key="old", nextKey="next" }

        keystore.load_conf = spy.new(function() return conf end)
        stub(keystore, "store_conf")

        keystore.set_next_key("next")

        assert.spy(keystore.load_conf).was_called()
        assert.spy(keystore.store_conf).was_not_called()
    end)


    it("should replace obsolete next key and store conf", function()
        local keystore = require("keystore")()

        local oldConf = {ssid="ssid", key="current", nextKey="oldNext"}
        local newConf = {ssid="ssid", key="current", nextKey="newNext" }

        keystore.load_conf = spy.new(function() return oldConf end)
        stub(keystore, "store_conf")

        keystore.set_next_key("newNext")

        assert.spy(keystore.load_conf).was_called()
        assert.spy(keystore.store_conf).was_called_with(match.is_same(newConf))
    end)


    it("should replace old key and store conf", function()
        local keystore = require("keystore")()

        local oldConf = {ssid="ssid", key="old", nextKey="next" }
        local newConf = {ssid="ssid", key="next" }

        stub(keystore, "store_conf")

        keystore.use_next_key(oldConf)

        assert.spy(keystore.store_conf).was_called_with(match.is_same(newConf))
    end)


    it("should return stored conf for every iteration", function()
        local keystore = require("keystore")()

        local conf = {ssid="ssid", key="old" }

        keystore.load_conf = spy.new(function() return conf end)

        assert.are.same({ssid=conf.ssid, pwd=conf.key}, keystore.get_next_sta_conf())
        assert.are.same({ssid=conf.ssid, pwd=conf.key}, keystore.get_next_sta_conf())
        assert.are.same({ssid=conf.ssid, pwd=conf.key}, keystore.get_next_sta_conf())
        assert.are.same({ssid=conf.ssid, pwd=conf.key}, keystore.get_next_sta_conf())

        assert.spy(keystore.load_conf).was_called(1)
    end)


    it("should return alternating conf for every iteration", function()
        local keystore = require("keystore")()

        local conf = {ssid="ssid", key="old", nextKey="next" }

        keystore.load_conf = spy.new(function() return conf end)

        assert.are.same({ssid=conf.ssid, pwd=conf.key}, keystore.get_next_sta_conf())
        assert.are.same({ssid=conf.ssid, pwd=conf.nextKey}, keystore.get_next_sta_conf())
        assert.are.same({ssid=conf.ssid, pwd=conf.key}, keystore.get_next_sta_conf())
        assert.are.same({ssid=conf.ssid, pwd=conf.nextKey}, keystore.get_next_sta_conf())

        assert.spy(keystore.load_conf).was_called(1)
    end)


    it("should not update current key without next key", function()
        local keystore = require("keystore")()

        local conf = {ssid="ssid", key="old"}

        keystore.load_conf = spy.new(function() return conf end)
        stub(keystore, "store_conf")

        keystore.update_conf()
        keystore.get_next_sta_conf()
        keystore.update_conf()
        keystore.get_next_sta_conf()
        keystore.update_conf()

        assert.spy(keystore.load_conf).was_called(1)
        assert.spy(keystore.store_conf).was_not_called()
    end)


    it("should not update current key", function()
        local keystore = require("keystore")()

        local conf = {ssid="ssid", key="old", nextKey="next" }

        keystore.load_conf = spy.new(function() return conf end)
        stub(keystore, "store_conf")

        keystore.get_next_sta_conf()
        keystore.get_next_sta_conf()
        keystore.get_next_sta_conf()
        keystore.update_conf()

        assert.spy(keystore.load_conf).was_called(1)
        assert.spy(keystore.store_conf).was_not_called()
    end)


    it("should update current key", function()
        local keystore = require("keystore")()

        local conf = {ssid="ssid", key="old", nextKey="next" }

        keystore.load_conf = spy.new(function() return conf end)
        stub(keystore, "store_conf")

        keystore.update_conf()
        keystore.get_next_sta_conf()
        keystore.update_conf()

        assert.spy(keystore.store_conf).was_not_called()

        keystore.get_next_sta_conf()
        keystore.update_conf()

        assert.spy(keystore.load_conf).was_called(1)
        assert.spy(keystore.store_conf).was_called(1)
    end)

end)
