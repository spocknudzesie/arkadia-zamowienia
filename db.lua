function scripts.zamowienia:addDeliveryToDb(item, reward)
    db:add(self.database.db.deliveries, {item=item, reward=reward, character=gmcp.char.info.name, timestamp=os.time()})
end


function scripts.zamowienia:getDeliveries(timeFrom, timeTo, sum)
    local q
    if sum then
        q = string.format("SELECT SUM(reward) AS total_reward FROM deliveries WHERE timestamp >= %s AND timestamp <= %s AND character='%s'", timeFrom, timeTo, gmcp.char.info.name)
    else
        q = string.format("SELECT * FROM deliveries WHERE timestamp >= %s AND timestamp <= %s AND character='%s'", timeFrom, timeTo, gmcp.char.info.name)
    end
    -- print(q)
    return db:execute(self.database.name, q)
end


function scripts.zamowienia:getDeliveriesInRange(timeFrom, timeTo, sum)
    local y1, m1, d1 = unpack(string.split(timeFrom,'-'))
    local y2, m2, d2 = unpack(string.split(timeTo,'-'))

    return self:getDeliveries(
        os.time({year=y1, month=m1, day=d1, hour=0, minute=0}),
        os.time({year=y2, month=m2, day=d2, hour=23, minute=59}),
        sum)
end


