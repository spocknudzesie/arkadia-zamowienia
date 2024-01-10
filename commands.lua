function scripts.zamowienia:cmdZamowienia()
    echo("-- ZAMOWIENIA --\n"
    .. "/zamowienia - ta pomoc\n"
    .. "/zamowienia_list [aktywne] - lista zamowien\n"
    .. "/zamowienia_miasto <miasto> - ustawia miasto dla aktualnego zamowienia\n"
    .. "/zamowienia_sprawdz <short> - sprawdza nagrode za podany przedmiot\n"
    .. "/zamowienia_raport [prowizja] - generuje raport ze zrealizowanch zamowien z uwzglednieniem podanej prowizji\n"
    .. "/zamowienia_licznik [reset|szczegoly] - wyswietla dotychczasowy zysk (z ew. edytowalnymi szczegolami) z zamowien lub resetuje go\n\n")
    
end


function scripts.zamowienia:cmdList(arg)
    local data, c = self:getOrders(arg)
    local l = 0

    arg = (arg == 'aktywne')

    echo("-- ZAMOWIENIA --\n")
    for i=1, c do
        local order = data[i]
        if not arg then
            if os.time() > order.expiresAt or order.items.count == 0 then
                echo("(-) ")
            else
                echo("(+) ")
            end
        end
            
        echo(self:orderToText(order) .. "\n")
    end


end


function scripts.zamowienia:cmdMiasto(arg)
    local roomId = getPlayerRoom()

    if not arg then
        self:error('W lokacji z zamowieniem uzyj np. #ffffff/zamowienia_miasto Varieno#r, aby przypisac biezaca lokacje do danego miasta.')
        return
    end

    if not self.data.orders[roomId] then self:createNew(roomId) end
    self.data.orders[roomId].town = arg
    self:saveData()
    self:ok(string.format("Ustawiam miasto biezacej lokacji #00aa00%d#r na #00aa00%s#r.", roomId, arg))
end


function scripts.zamowienia:reportLines(margin)
    local len = 0
    local sum = 0
    local res = {}
    for item, _ in pairs(self.data.deliveredOrders) do
        if string.len(item) > len then
            len = string.len(item)
        end
    end

    for item, details in pairs(self.data.deliveredOrders) do
        table.insert(res, {item, string.format("%2dx %-" .. len .. "s %s", details.count, item, scripts.money:cCopperToDesc(details.reward))})
        sum = sum + details.reward
    end

    table.insert(res, string.rep("-", len+4+20))
    table.insert(res, string.format("    %-"..len.."s %s", "Lacznie", scripts.money:cCopperToDesc(sum, true)))

    if margin and tonumber(margin) then
        local m = sum * margin/100
        local s = sum - m
        table.insert(res, string.format("    %-"..len.."s %s", string.format("Prowizja %d%%", margin), scripts.money:cCopperToDesc(m, true)))
        table.insert(res, string.format("    %-"..len.."s %s", "Suma", scripts.money:cCopperToDesc(s, true)))
    end

    return res
end


function scripts.zamowienia:cmdLicznik(arg)
    self:ok("Dotychczasowy zarobek: " .. scripts.money:hCopperToDesc(self.data.reward))

    if arg == "reset" then
        self.data.reward = 0
        self.data.deliveredOrders = {}
        self:ok("Zresetowano licznik zamowien")
        self:saveData()
        return
    elseif arg and arg:find("szczegoly") then
        local msg = self:reportLines(arg:match("%d+"))
        for i=1, #msg do
            if type(msg[i]) == 'table' then
                hechoLink('[usun] ', string.format("scripts.zamowienia.data.deliveredOrders['%s'] = nil", msg[i][1]), 'usun', true)
                cecho(msg[i][2] .. "\n")
            else
                cecho(msg[i] .. "\n")
            end
        end
    end
end


function scripts.zamowienia:cmdRaport(arg)
    local msg = self:reportLines(arg)
    for i=1, #msg do
        local m 
        if type(msg[i]) == 'table' then
            m = msg[i][2]
        else
            m = msg[i]
        end
        m = string.gsub(m, ',', '')
        m = string.gsub(m, '_', '')
        m = string.gsub(m, '<%w+>', '')
        echo(m .. "\n")
    end
end


function scripts.zamowienia:cmdMonth(startDate, endDate, details)
    details = details or false
    local data = self:getDeliveriesInRange(startDate, endDate, true)[1].total_reward
    print(string.format("Zrealizowane zamowienia dla postaci '%s' za okres %s - %s:", gmcp.char.info.name, startDate, endDate))
    hecho(string.format("Laczny zysk: %s\n", scripts.money:hCopperToDesc(data, true)))
end


function scripts.zamowienia:cmdSprawdz(short)
    local r = self.data.items[short]

    if not r then
        self:error("Nie znaleziono przedmiotu '" .. short .. "'.")
    else
        self:ok("Za " .. short .. " dostaniesz " .. scripts.money:hCopperToDesc(r, false))
    end
end
