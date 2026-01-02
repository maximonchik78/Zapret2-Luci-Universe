module("luci.controller.zapret2", package.seeall)

function index()
    entry({"admin", "services", "zapret2"}, firstchild(), _("Zapret2"), 60).dependent = false
    entry({"admin", "services", "zapret2", "status"}, template("zapret2/status"), _("Status"), 1).leaf = true
    entry({"admin", "services", "zapret2", "install"}, call("action_install"), _("Install/Update"), 2).leaf = true
    entry({"admin", "services", "zapret2", "blockcheck"}, call("action_blockcheck"), _("Block Check"), 3).leaf = true
    entry({"admin", "services", "zapret2", "config"}, form("zapret2/config"), _("Configuration"), 4).leaf = true
    entry({"admin", "services", "zapret2", "strategies"}, call("action_strategies"), _("Strategies"), 5).leaf = true
    entry({"admin", "services", "zapret2", "lists"}, form("zapret2/lists"), _("Block Lists"), 6).leaf = true
    entry({"admin", "services", "zapret2", "exceptions"}, form("zapret2/exceptions"), _("Exceptions"), 7).leaf = true
    entry({"admin", "services", "zapret2", "log"}, call("action_log"), _("Log"), 8).leaf = true
    entry({"admin", "services", "zapret2", "api"}, call("action_api")).leaf = true
    entry({"admin", "services", "zapret2", "control"}, call("action_control")).leaf = true
end

function action_blockcheck()
    local http = require "luci.http"
    local sys = require "luci.sys"
    
    local action = http.formvalue("action")
    
    if action == "test" then
        local test_url = http.formvalue("url") or "http://example.com"
        local timeout = http.formvalue("timeout") or "10"
        
        local cmd = string.format("curl -s -o /dev/null -w '%%{http_code}' --connect-timeout %s --max-time %s '%s' 2>&1", timeout, timeout, test_url)
        local result = sys.exec(cmd)
        
        local blocked = false
        local status = "unknown"
        
        if result:match("^0$") or result:match("timeout") or result:match("Connection refused") then
            blocked = true
            status = "blocked"
        elseif result:match("^[2345]") then
            blocked = false
            status = "accessible"
        else
            status = "error"
        end
        
        http.prepare_content("application/json")
        http.write_json({
            url = test_url,
            blocked = blocked,
            status = status,
            result = result,
            timestamp = os.time()
        })
        
    elseif action == "multi_test" then
        local tests = http.formvalue("tests")
        local timeout = http.formvalue("timeout") or "5"
        
        local test_list = {}
        for test in tests:gmatch("[^,]+") do
            table.insert(test_list, test:gsub("^%s*(.-)%s*$", "%1"))
        end
        
        local results = {}
        local util = require "luci.util"
        
        for _, url in ipairs(test_list) do
            local cmd = string.format("timeout %s curl -s -o /dev/null -w '%%{http_code}' '%s' 2>&1", timeout, url)
            local result = sys.exec(cmd)
            
            local blocked = result:match("^0$") or result:match("timeout") or 
                           result:match("Connection refused") or result:match("Connection timed out")
            
            table.insert(results, {
                url = url,
                blocked = blocked,
                status_code = result,
                timestamp = os.time()
            })
            
            sys.exec("sleep 0.5")
        end
        
        http.prepare_content("application/json")
        http.write_json({
            results = results,
            total = #results,
            blocked = #util.filter(results, function(r) return r.blocked end)
        })
        
    else
        local test_sites = {
            "http://rutracker.org",
            "http://example.com",
            "http://google.com",
            "http://youtube.com",
            "http://facebook.com"
        }
        
        luci.template.render("zapret2/blockcheck", {
            test_sites = test_sites
        })
    end
end

function action_install()
    local http = require "luci.http"
    local sys = require "luci.sys"
    local json = require "luci.jsonc"
    
    local step = http.formvalue("step") or "check"
    local action = http.formvalue("action")
    
    if action == "download" then
        local arch = sys.exec("opkg print-architecture | awk 'NR>2 {print $2}' | head -1")
        local arch_map = {
            ["aarch64_generic"] = "aarch64",
            ["arm_cortex-a7_neon-vfpv4"] = "arm_cortex-a7",
            ["arm_cortex-a9_neon"] = "arm_cortex-a9",
            ["mipsel_24kc"] = "mipsel",
            ["x86_64"] = "x86_64",
            ["i386_pentium4"] = "i386"
        }
        
        local arch_suffix = arch_map[arch] or "mipsel"
        
        local release_info = sys.exec("curl -s -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/bol-van/zapret/releases/latest")
        local release = json.parse(release_info)
        
        if not release then
            luci.template.render("zapret2/install_error", {
                error = "Failed to fetch release information"
            })
            return
        end
        
        local download_url = nil
        local asset_name = string.format("zapret-openwrt-%s.tar.gz", arch_suffix)
        
        for _, asset in ipairs(release.assets or {}) do
            if asset.name and asset.name:match(arch_suffix) then
                download_url = asset.browser_download_url
                break
            end
        end
        
        if not download_url then
            for _, asset in ipairs(release.assets or {}) do
                if asset.name and asset.name:match("%.tar%.gz$") then
                    download_url = asset.browser_download_url
                    break
                end
            end
        end
        
        if download_url then
            luci.template.render("zapret2/install_progress", {
                version = release.tag_name,
                download_url = download_url,
                arch = arch_suffix
            })
        else
            luci.template.render("zapret2/install_error", {
                error = "No compatible package found for architecture: " .. arch
            })
        end
        
    elseif action == "do_install" then
        local url = http.formvalue("url")
        local version = http.formvalue("version")
        
        local output = sys.exec("/usr/libexec/zapret2/install.sh '" .. url .. "' '" .. version .. "' 2>&1")
        
        http.prepare_content("application/json")
        http.write_json({
            success = true,
            output = output
        })
        
    else
        luci.template.render("zapret2/install_start", {})
    end
end

function action_status()
    local sys = require "luci.sys"
    local fs = require "nixio.fs"
    
    local is_installed = fs.access("/usr/bin/zapret") or fs.access("/usr/sbin/zapret")
    local is_running = sys.call("pgrep -f 'zapret' >/dev/null") == 0
    local is_enabled = sys.call("[ -f /etc/rc.d/S*zapret ]") == 0
    
    local version = "Not installed"
    if is_installed then
        version = sys.exec("zapret --version 2>/dev/null | head -1 || echo 'Unknown'")
    end
    
    luci.template.render("zapret2/status", {
        is_installed = is_installed,
        is_running = is_running,
        is_enabled = is_enabled,
        version = version
    })
end

function action_strategies()
    local fs = require "nixio.fs"
    
    local strategies = {
        {
            id = "tpws",
            name = "TPWS (Transparent Proxy)",
            description = "Transparent proxy with WebSocket support",
            enabled = false,
            config_file = "/etc/zapret/tpws.config"
        },
        {
            id = "nfqws",
            name = "NFQWS (NetFilter Queue)",
            description = "NetFilter queue with WebSocket support",
            enabled = false,
            config_file = "/etc/zapret/nfqws.config"
        },
        {
            id = "custom",
            name = "Custom Script",
            description = "Custom blocking script",
            enabled = false,
            config_file = "/etc/zapret/custom.config"
        }
    }
    
    if fs.access("/etc/zapret/config.ini") then
        local content = fs.readfile("/etc/zapret/config.ini")
        if content then
            for _, strategy in ipairs(strategies) do
                if content:match("strategy.*" .. strategy.id) then
                    strategy.enabled = true
                    break
                end
            end
        end
    end
    
    luci.template.render("zapret2/strategies", {
        strategies = strategies
    })
end

function action_log()
    local sys = require "luci.sys"
    local fs = require "nixio.fs"
    
    local lines = tonumber(luci.http.formvalue("lines") or 100)
    local filter = luci.http.formvalue("filter") or ""
    
    local log_files = {
        "/var/log/zapret.log",
        "/tmp/zapret.log",
        "/var/log/messages"
    }
    
    local log_content = ""
    
    for _, log_file in ipairs(log_files) do
        if fs.access(log_file) then
            local cmd = string.format("tail -n %d '%s'", lines, log_file)
            if filter and filter ~= "" then
                cmd = cmd .. string.format(" | grep -i '%s'", filter)
            end
            log_content = sys.exec(cmd)
            if log_content and log_content ~= "" then
                break
            end
        end
    end
    
    if log_content == "" then
        log_content = sys.exec("journalctl -u zapret -n " .. lines .. " 2>/dev/null")
    end
    
    luci.template.render("zapret2/log", {
        log_content = log_content or "No log entries found",
        lines = lines,
        filter = filter
    })
end

function action_api()
    local http = require "luci.http"
    local sys = require "luci.sys"
    
    local cmd = http.formvalue("cmd")
    
    if cmd == "status" then
        local is_running = sys.call("pgrep -f zapret >/dev/null") == 0
        http.write_json({ running = is_running })
        
    elseif cmd == "start" then
        sys.call("/etc/init.d/zapret start >/dev/null 2>&1")
        http.write_json({ success = true })
        
    elseif cmd == "stop" then
        sys.call("/etc/init.d/zapret stop >/dev/null 2>&1")
        http.write_json({ success = true })
        
    elseif cmd == "restart" then
        sys.call("/etc/init.d/zapret restart >/dev/null 2>&1")
        http.write_json({ success = true })
        
    elseif cmd == "enable" then
        sys.call("/etc/init.d/zapret enable >/dev/null 2>&1")
        http.write_json({ success = true })
        
    elseif cmd == "disable" then
        sys.call("/etc/init.d/zapret disable >/dev/null 2>&1")
        http.write_json({ success = true })
    end
end

function action_control()
    local http = require "luci.http"
    local sys = require "luci.sys"
    
    local action = http.formvalue("action")
    local redirect = http.formvalue("redirect") or "status"
    
    if action == "start" then
        sys.call("/etc/init.d/zapret start >/dev/null 2>&1")
    elseif action == "stop" then
        sys.call("/etc/init.d/zapret stop >/dev/null 2>&1")
    elseif action == "restart" then
        sys.call("/etc/init.d/zapret restart >/dev/null 2>&1")
    elseif action == "enable" then
        sys.call("/etc/init.d/zapret enable >/dev/null 2>&1")
    elseif action == "disable" then
        sys.call("/etc/init.d/zapret disable >/dev/null 2>&1")
    end
    
    http.redirect(luci.dispatcher.build_url("admin/services/zapret2/" .. redirect))
end
