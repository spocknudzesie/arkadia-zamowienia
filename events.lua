function scripts.zamowienia:killEvent(event)
    if self.eventHandlers[event] then
        self:debug("Killing event " .. event)
        killAnonymousEventHandler(self.eventHandlers[event])
    end
end


function scripts.zamowienia:addEvent(intName, event, func, times)
    self.eventHandlers[intName] = registerAnonymousEventHandler(event, func, times)
end


function scripts.zamowienia:killCommandHandler()
    for name, _ in pairs(self.eventHandlers) do
        self:killEvent(name)
    end
end


function scripts.zamowienia:setOrderTime(roomId, timeDesc, startTime)
    local t = self:timeDescToNumber(timeDesc)
    startTime = startTime or os.time()
    self.data.orders[roomId].expiresAt = startTime + t[1] * 120
    self.data.orders[roomId].timeDesc = timeDesc
    return self.data.orders[roomId].expiresAt
end


-- nie ma zamowienia, ale podaje pozostaly czas albo i nie
function scripts.zamowienia:processNoOrder(roomId, m)
    self:debug("No order available")

    if not self.data.orders[roomId] then self:createNew(roomId) end
    self.data.orders[roomId].items.count = 0

    if m then
        self:debug("Time for next order: " .. m)
        self:setOrderTime(roomId, m)
    else
        self:debug("Time for the next order unknown")
    end

    self:saveData()

    return true
end


-- npc mowi, ile czasu zostalo
function scripts.zamowienia:processOrderDeadline(roomId, m)
    self:debug("Time left: " .. m)


    self:setOrderTime(roomId, m)
    self:ok(self:orderToText(self.data.orders[roomId]))    
    self:saveData()
end


-- npc mowi, ile przedmiotow zostalo
function scripts.zamowienia:processUpdateOrder(roomId, m)
    m = scripts.numerals:subLiczebnik(m)

    self:debug("Order " .. roomId .. " item count updated.")
    self.data.orders[roomId].items.count = m
    self:saveData()
end


-- przedmiot przekazany
function scripts.zamowienia:processOrderDelivered(roomId, msg)
    local item, reward = msg:match("^.+ odbiera od ciebie (.+) i wrecza ci (.+)\.")
    local copper

    if not item or not reward then return true end

    if item then self:debug("ITEM = " .. item) end
    if reward then self:debug("REWARD = " .. reward) end

    self:debug("Order delivered: " .. item .. " for " .. reward)

    copper = scripts.money:descToCopper(reward)

    local data = {reward=copper, item=item, roomId=getPlayerRoom()}
    
    self:debug("Emitting event orderDelivered with args " .. dump_table(data))
    raiseEvent("orderDelivered", data)
    
    self.data.reward = self.data.reward + copper
    self.data.items[item] = copper
    self:ok(string.format("Dostarczasz %s za %s.", item, scripts.money:hCopperToDesc(copper, false)))
    self:deliverItem(item, copper)
    self:cmdLicznik('')
    self:saveData()
    return false
end


-- jest zamowienie, opisujemy je
function scripts.zamowienia:processNpcNeedsSomething(roomId, orderDesc)
    orderDesc = orderDesc:gsub("jeszcze ", "")
    local count, item = scripts.numerals:subLiczebnik(orderDesc)
    local data = {count=count, item=item, text=orderDesc}
    local msg = ""
    
    self:debug("Emitting event orderPresented: " .. dump_table(data))
    raiseEvent("orderPresented", data)

    if not self.data.orders[roomId] then
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

    self.data.orders[roomId].roomId = roomId
    self.data.orders[roomId].orderDesc = orderDesc
    self.data.orders[roomId].createdAt = os.time()
    self.data.orders[roomId].items = {
        count = count,
        item = item,
    }

    msg = "Dodano zamowienie do "
    if string.len(self.data.orders[roomId].town) > 0 then
        msg = msg ..  " miasta " .. self.data.orders[roomId].town
    else
        msg = msg .. " lokacji " .. roomId
    end

    self:ok(msg)

    self:saveData()
    return false
end