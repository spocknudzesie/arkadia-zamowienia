scripts.zamowienia = scripts.zamowienia or {
    db = getMudletHomeDir() .. '/orders.json',
    database = {
        name = 'orders',
        schemas = {
            deliveries = {
                character = '',
                item = '',
                reward = '',
                timestamp = 0,
            }
        }
    },
    name = 'zamowienia',
    pluginName = 'arkadia-zamowienia',
    data = {
        orders = {},
        items = {},
        reward = 0,
        deliveredOrders = {},
    },
    eventHandlers = {},
    debugMode = false
}


function scripts.zamowienia:init()
    self:killCommandHandler()
    
    self:addEvent('orderPresented', 'incomingMessage',
        function(event, t, msg)
            if t ~= "comm" then return false end
            return self:processNpcTalk(getPlayerRoom(), ansi2string(msg))
        end)

    self:addEvent('orderReceived', 'incomingMessage',
        function(event, t, msg)
            if t ~= 'other' then return false end
            return self:processOrderDelivered(getPlayerRoom(), ansi2string(msg))
        end)

    self:loadData()
    db:create(self.database.name, self.database.schemas)
    self.database.db = db:get_database(self.database.name)
    self:ok("Zaladowane. Uzyj komendy #ffffff/zamowienia#r, aby wyswietlic pomoc.")
    scripts.plugins_update_check:github_check_version('arkadia-zamowienia', 'spocknudzesie')

end


function scripts.zamowienia:createNew(roomId)
    self.data.orders[roomId] = {
        town = "",
        timeDesc = "",
        orderDesc = "",
        roomId = 0,
        createdAt = 0,
        expiresAt = 0,
        items = {
            count = 0,
            item = ""
        }
    }
end


function scripts.zamowienia:deliverItem(item, reward)
    item = item:trim()
    
    if not self.data.deliveredOrders[item] then
        self.data.deliveredOrders[item] = {count=0, reward=0}
    end

    if type(reward) == "table" then
        reward = reward[1] * 240 + reward[2] * 12 + reward[3]
    end

    self:addDeliveryToDb(item, reward)

    self.data.deliveredOrders[item].count = self.data.deliveredOrders[item].count + 1
    self.data.deliveredOrders[item].reward = self.data.deliveredOrders[item].reward + reward
    self:saveData()
end


function scripts.zamowienia:getOrder(roomId)
    roomId = roomId or getPlayerRoom()

    -- echo("Order in room " .. roomId .. "\n")
    -- echo(dump_table(self.data.orders[roomId]))
end


function scripts.zamowienia:processNpcTalk(roomId, msg)
    if not msg:find("do ciebie:") then return false end
    local text = msg:sub(msg:find(":")+1):trim()
    -- echo("TEXT = "..text)
    text = text:degnome()
    -- echo("TEXT = "..text)
    text = string.lower(text)
    
    m = text:match("^tak, mam pewne pilne zamowienie\. potrzebuje (.+), przynajmniej")
    if m then
        self:debug("Moving to processNpcNeedsSomething")
        return self:processNpcNeedsSomething(roomId, m)
    end

    local m = text:match("^na realizacje zamowienia mam (.+),")
    if m then
        self:debug("Deadline caught, moving to processOrderDeadline")
        return self:processOrderDeadline(roomId, m)
    end

    m = text:match("^nie, w tej chwili niczego mi nie trzeba\. zajrzyj moze za (.+)")
    
    if m or text:match("^dziekuje, wiecej mi juz nie trzeba\.$") then
        self:debug("No order available, moving to processNoOrder")
        return self:processNoOrder(roomId, m)
    end

    m = text:match("^dziekuje, potrzebuje jeszcze (.+) sztuk")
    if m then
        self:debug("Moving to updateOrder")
        return self:processUpdateOrder(roomId, m)
    end

    m = text:match("^nie, chwilowo niczego konkretnego nie poszukuje\. pewnie za (.+) znow bede czegos potrzebowac\.")
    if m then
        self:debug("Order completed")
        return self:processNoOrder(roomId, m)
    end
    
    self:debug("Nothing matched!")
    return true
end


function scripts.zamowienia:reload(debug)
    local p = self.pluginName
    self:killCommandHandler()
    scripts[self.name] = nil
    load_plugin(p)
    if debug then
        self.debugMode = debug
        self:debug("Debug on")
    end
end


function scripts.zamowienia:deleteOrder(roomId)
    roomId = roomId or getPlayerRoom()
    self.data.orders[roomId] = nil
    self:saveData()
end


function scripts.zamowienia:getOrders(active)
    local res = {}

    for roomId, order in pairs(self.data.orders) do
        -- echo("ROOMID = " .. roomId .. "\n")
        if (not active) or (active and order.expiresAt > os.time() and active and order.items.count > 0) then
            table.insert(res, order)
        end
    end

    table.sort(res, function(a,b)
        return a.town < b.town
    end)

    return res, #res
end


function scripts.zamowienia:orderToText(order, len)
    local str = ""
    if order.items.item ~= 0 then
        order.items.item = order.items.item:gsub("chroniac%a+", "na")
    end

    str = str .. string.format("%-12s ", order.town)

    if order.items.count > 0 then
        str = str .. string.format("%2d %-40s", order.items.count, order.items.item)
    else
        str = str .. string.format("%-43s", "niczego nie potrzebuje")
    end
    str = str .. string.format("do %s", self:formatTime(order.expiresAt))
    str = str .. string.format(" [%5d]", order.roomId)
    return str
end


function scripts.zamowienia:timeDescToNumber(desc)
    if desc == "niecaly dzien" then
        return {13, 23}
      elseif desc == "dzien" then
        return {24, 47}
      elseif desc == "kilka godzin" then
        return {1, 11}
      else
        local n = scripts.numerals:subLiczebnik(desc)
        return {24*n, 24*n + 23}
      end
end


tempTimer(1, [[scripts.zamowienia:init()]])
