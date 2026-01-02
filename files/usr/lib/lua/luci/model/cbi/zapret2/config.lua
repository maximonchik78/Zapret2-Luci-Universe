local m, s, o

m = Map("zapret2", translate("Zapret2 Configuration"), 
    translate("Configure main settings for the blocking system"))

s = m:section(NamedSection, "config", "config", translate("General Settings"))

o = s:option(Flag, "enabled", translate("Enable Service"), 
    translate("Enable zapret2 blocking system"))
o.default = "0"
o.rmempty = false

o = s:option(ListValue, "mode", translate("Operation Mode"))
o:value("transparent", translate("Transparent Proxy"))
o:value("gateway", translate("Network Gateway"))
o:value("router", translate("Router Mode"))
o:value("custom", translate("Custom"))
o.default = "transparent"

o = s:option(ListValue, "strategy", translate("Default Blocking Strategy"))
o:value("tpws", translate("TPWS - Transparent Proxy"))
o:value("nfqws", translate("NFQWS - NetFilter Queue"))
o:value("ipset", translate("IPSet"))
o:value("dns", translate("DNS Blocking"))
o:value("mixed", translate("Mixed Strategy"))
o.default = "tpws"

o = s:option(Flag, "ipv6", translate("IPv6 Support"), 
    translate("Enable IPv6 blocking"))
o.default = "1"

o = s:option(Flag, "autoupdate", translate("Auto Update"), 
    translate("Automatically update block lists"))
o.default = "1"

o = s:option(Value, "update_hour", translate("Update Hour"))
o.datatype = "range(0,23)"
o.default = "3"
o:depends("autoupdate", "1")

s = m:section(NamedSection, "network", "config", translate("Network Settings"))

o = s:option(Value, "lan_interface", translate("LAN Interface"))
o.placeholder = "br-lan"
o.rmempty = false

o = s:option(Value, "wan_interface", translate("WAN Interface"))
o.placeholder = "eth0"

o = s:option(DynamicList, "dns_servers", translate("DNS Servers"))
o.placeholder = "8.8.8.8"
o.datatype = "ipaddr"

o = s:option(Value, "dns_port", translate("DNS Port"))
o.datatype = "port"
o.default = "53"

s = m:section(NamedSection, "performance", "config", translate("Performance Settings"))

o = s:option(ListValue, "conntrack", translate("Connection Tracking"))
o:value("enabled", translate("Enabled"))
o:value("disabled", translate("Disabled"))
o:value("loose", translate("Loose"))
o.default = "enabled"

o = s:option(Value, "max_connections", translate("Max Connections"))
o.datatype = "uinteger"
o.default = "10000"

o = s:option(Value, "cache_size", translate("Cache Size (MB)"))
o.datatype = "uinteger"
o.default = "50"

o = s:option(ListValue, "log_level", translate("Log Level"))
o:value("0", translate("Disabled"))
o:value("1", translate("Errors Only"))
o:value("2", translate("Warnings"))
o:value("3", translate("Info"))
o:value("4", translate("Debug"))
o.default = "2"

s = m:section(NamedSection, "advanced", "config", translate("Advanced Settings"))

o = s:option(TextValue, "custom_rules", translate("Custom Rules"))
o.rows = 10
o.wrap = "off"
o.rmempty = true

o = s:option(Value, "config_dir", translate("Config Directory"))
o.default = "/etc/zapret"
o.rmempty = false

o = s:option(Value, "work_dir", translate("Working Directory"))
o.default = "/var/lib/zapret"
o.rmempty = false

function m.on_after_commit(self)
    os.execute("/etc/init.d/zapret restart 2>/dev/null || true")
end

return m
