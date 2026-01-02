local m, s, o

m = Map("zapret2", translate("Exceptions Management"), 
    translate("Manage whitelist and bypass rules"))

s = m:section(TypedSection, "whitelist", translate("Whitelist"))
s.template = "cbi/tblsection"
s.anonymous = false
s.addremove = true

o = s:option(Value, "domain", translate("Domain/IP/CIDR"))
o.placeholder = "example.com or 192.168.1.0/24"
o.rmempty = false

o = s:option(ListValue, "type", translate("Type"))
o:value("domain", translate("Domain"))
o:value("ip", translate("Single IP"))
o:value("cidr", translate("IP Range (CIDR)"))
o:value("regex", translate("Regular Expression"))
o.default = "domain"

o = s:option(Value, "reason", translate("Reason"))
o.placeholder = "Work requirement"

o = s:option(Flag, "permanent", translate("Permanent"))
o.default = "1"

s = m:section(TypedSection, "blacklist", translate("Additional Block List"))
s.template = "cbi/tblsection"
s.anonymous = false
s.addremove = true

o = s:option(Value, "entry", translate("Entry"))
o.placeholder = "bad-site.com"
o.rmempty = false

o = s:option(ListValue, "category", translate("Category"))
o:value("ads", translate("Advertisement"))
o:value("malware", translate("Malware"))
o:value("phishing", translate("Phishing"))
o:value("tracking", translate("Tracking"))
o:value("custom", translate("Custom"))

s = m:section(TypedSection, "schedule", translate("Time-based Exceptions"))
s.template = "cbi/tblsection"
s.anonymous = false
s.addremove = true

o = s:option(Value, "name", translate("Schedule Name"))
o.placeholder = "Work Hours"
o.rmempty = false

o = s:option(ListValue, "action", translate("Action"))
o:value("disable", translate("Disable Blocking"))
o:value("whitelist", translate("Apply Whitelist Only"))
o:value("reduced", translate("Reduced Blocking"))

o = s:option(Value, "time", translate("Time Range"))
o.placeholder = "09:00-18:00"
o.datatype = "timehhmm"

o = s:option(MultiValue, "days", translate("Days"))
o:value("mon", translate("Monday"))
o:value("tue", translate("Tuesday"))
o:value("wed", translate("Wednesday"))
o:value("thu", translate("Thursday"))
o:value("fri", translate("Friday"))
o:value("sat", translate("Saturday"))
o:value("sun", translate("Sunday"))
o.widget = "checkbox"

s = m:section(TypedSection, "device", translate("Device-based Exceptions"))
s.template = "cbi/tblsection"
s.anonymous = false
s.addremove = true

o = s:option(Value, "mac", translate("MAC Address"))
o.placeholder = "AA:BB:CC:DD:EE:FF"
o.datatype = "macaddr"
o.rmempty = false

o = s:option(Value, "ip", translate("IP Address"))
o.placeholder = "192.168.1.100"
o.datatype = "ipaddr"

o = s:option(Value, "hostname", translate("Hostname"))
o.placeholder = "laptop"

o = s:option(ListValue, "policy", translate("Policy"))
o:value("bypass", translate("Bypass All"))
o:value("whitelist", translate("Use Whitelist"))
o:value("custom", translate("Custom Rules"))

s = m:section(SimpleSection, nil, translate("Quick Import"))

o = s:option(TextValue, "import_whitelist", translate("Import Whitelist (one per line)"))
o.rows = 5
o.wrap = "off"

function o.write(self, section, value)
    if value and #value > 0 then
        for line in value:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if #line > 0 and not line:match("^#") then
                local sid = m:section(TypedSection, "whitelist", nil)
                local newsection = sid:create("import_" .. os.time() .. "_" .. #line)
                m:set(newsection, "domain", line)
                m:set(newsection, "type", "domain")
                m:set(newsection, "reason", "Imported")
            end
        end
    end
end

return m
