local m, s, o

m = Map("zapret2", translate("Block Lists Configuration"), 
    translate("Manage and update blocking lists for zapret2"))

s = m:section(TypedSection, "list", translate("Block Lists"))
s.template = "cbi/tblsection"
s.anonymous = false
s.addremove = true

o = s:option(Flag, "enabled", translate("Enabled"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "name", translate("List Name"))
o.placeholder = "Default List"
o.rmempty = false

o = s:option(ListValue, "type", translate("List Type"))
o:value("domains", translate("Domains"))
o:value("ips", translate("IP Addresses"))
o:value("urls", translate("URL Patterns"))
o:value("mixed", translate("Mixed"))
o.default = "domains"

o = s:option(Value, "url", translate("Source URL"))
o.placeholder = "https://example.com/blocklist.txt"
o.rmempty = false

o = s:option(ListValue, "update", translate("Update Frequency"))
o:value("manual", translate("Manual"))
o:value("hourly", translate("Hourly"))
o:value("daily", translate("Daily"))
o:value("weekly", translate("Weekly"))
o.default = "daily"

o = s:option(Value, "update_hour", translate("Update Hour (0-23)"))
o.datatype = "range(0,23)"
o.default = "3"
o:depends("update", "daily")
o:depends("update", "weekly")

o = s:option(Value, "entries", translate("Entries Count"))
o.datatype = "uinteger"
o.placeholder = "auto"
o.readonly = true

s:option(Button, "_update", translate("Update Now"))
function s.handle_update(self, section)
    local list_name = m:get(section, "name") or section
    os.execute(string.format("/usr/libexec/zapret2/update_list.sh '%s' >/tmp/update.log 2>&1 &", list_name))
    luci.http.redirect(luci.dispatcher.build_url("admin/services/zapret2/log"))
end

s = m:section(SimpleSection, nil, translate("Batch Operations"))

o = s:option(Button, "update_all", translate("Update All Lists"))
o.inputtitle = translate("Update Now")
o.inputstyle = "apply"
function o.write(self, section, value)
    os.execute("/usr/libexec/zapret2/update_all_lists.sh >/tmp/update_all.log 2>&1 &")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/zapret2/log"))
end

s = m:section(SimpleSection, nil, translate("Import Block List"))

o = s:option(TextValue, "import_data", translate("Import Domains/IPs (one per line)"))
o.rows = 10
o.wrap = "off"

function o.write(self, section, value)
    if value and #value > 0 then
        local temp_file = os.tmpname()
        local f = io.open(temp_file, "w")
        if f then
            f:write(value)
            f:close()
            
            local sid = m:section(TypedSection, "list", nil)
            sid.anonymous = true
            local newsection = sid:create("imported_" .. os.time())
            
            m:set(newsection, "name", "Imported List")
            m:set(newsection, "type", "domains")
            m:set(newsection, "enabled", "1")
            m:set(newsection, "update", "manual")
            m:set(newsection, "url", "file://" .. temp_file)
            
            os.remove(temp_file)
        end
    end
end

return m
