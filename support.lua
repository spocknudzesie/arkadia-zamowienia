function scripts.zamowienia:saveData()
    table.save(self.db, self.data)
end


function scripts.zamowienia:loadData()
    local filename = self.db
    local f = io.open(filename, 'r')
    if not f then
        self:saveData()
    else
        io.close(f)
    end
    table.load(filename, self.data)
end


function scripts.zamowienia:print(col, text)
    hecho(string.format("[%sZAMOWIENIA#r] #aaaaaa%s#r\n", col, text))
end


function scripts.zamowienia:error(text)
    self:print("#7f0000", text)
end


function scripts.zamowienia:debug(text)
    if self.debugMode then
        self:print('#ffdd00', text)
    end
end


function scripts.zamowienia:ok(text)
    self:print("#007f00", text)
end


function scripts.zamowienia:formatTime(t)
    local months = {
        Jan = "Sty",
        Feb = "Lut",
        Mar = "Mar",
        Apr = "Kwi",
        May = "Maj",
        Jun = "Cze",
        Jul = "Lip",
        Aug = "Sie",
        Sep = "Wrz",
        Oct = "Paz",
        Nov = "Lis",
        Dec = "Gru"
    }
    local d = os.date("%d. %b %H:%M", t):gsub("%d$", "0")
    for en, pl in pairs(months) do
        d = d:gsub(en, pl)
    end
    return d
end
