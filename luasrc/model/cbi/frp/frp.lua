local o=require"luci.dispatcher"
local e=require("luci.model.ipkg")
local s=require"nixio.fs"
local e=luci.model.uci.cursor()
local i="frp"
local a,t,e
local n={}
local running=(luci.sys.call("pidof frpc > /dev/null") == 0)

if running then
  a = Map(i,translate("Frp Setting"), "<b><font color=\"green\">" .. translate("Frpc is running!") .. "</font></b>")
else
  a = Map(i,translate("Frp Setting"), "<b><font color=\"red\">" .. translate("Frpc is not running!") .. "</font></b>")
end

t=a:section(NamedSection,"common","frp",translate("Global Setting"), translate("Frp is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet."))
t.anonymous=true
t.addremove=false

t:tab("base",translate("Basic Settings"))
t:tab("other",translate("Other Settings"))
t:tab("log",translate("Client Log"))

e=t:taboption("base",Flag, "enabled", translate("Enabled"))
e.rmempty=false

if not nixio.fs.access("/usr/bin/frpc") then
downloadfile=1    
end

if downloadfile==1 then

e = t:taboption("base", Button, "get_frp_version", translate("刷新版本"), translate("获取可下载的FRP文件版本."))
e.inputtitle = translate("刷新版本")
e.inputstyle = "apply"

function e.write(self, section)
  os.execute("curl -k -s https://github.com/fatedier/frp/tags | grep 'tag-name'|awk -F '[v]' '{print $2}'|awk -F '[\<]' '{print $1}' >/tmp/log/frp_version &")
  self.inputtitle = translate("刷新版本")
end

e = t:taboption("base", Value, "url", "执行文件下载网址")
e:value("git", "git下载")
e:value("blog", "默认下载")
e.placeholder = "git"

e = t:taboption("base", ListValue, "version_g","下载执行文件版本", "git下载时，需要先执行上面的获取版本，并刷新页面。")
for i_1 in io.popen("cat /tmp/log/frp_version", "r"):lines() do
    e:value(i_1)
end
e:depends("url", "git")

e = t:taboption("base", Value, "version_d","下载执行文件版本")
e:value("0.14.1", "0.14.1")
e:value("0.14.0", "0.14.0")
e:value("0.13.0", "0.13.0")
e.placeholder = "0.14.1"
e:depends("url", "blog")
end

e=t:taboption("base",Value, "server_addr", translate("Server"))
e.optional=false
e.rmempty=false

e=t:taboption("base",Value, "server_port", translate("Port"))
e.datatype = "port"
e.optional=false
e.rmempty=false

e=t:taboption("base",Value, "privilege_token", translate("Privilege Token"), translate("Time duration between server of frpc and frps mustn't exceed 15 minutes."))
e.optional=false
e.password=true
e.rmempty=false

e=t:taboption("base",Value, "vhost_http_port", translate("Vhost HTTP Port"))
e.datatype = "port"
e.rmempty=false

e=t:taboption("base",Value, "vhost_https_port", translate("Vhost HTTPS Port"))
e.datatype = "port"
e.rmempty=false

e=t:taboption("base",Value,"time",translate("Service registration interval"),translate("0 means disable this feature, unit: min"))
e.datatype="range(0,59)"
e.default=30
e.rmempty=false

e = t:taboption("base", Button, "del_frp", translate("del_frp"), translate("Sometims the download files is incorrect, you can delete them."))
e.inputtitle = translate("del_frp")
e.inputstyle = "apply"

function e.write(self, section)
  os.execute("[ -h '/usr/bin/frpc' ] && rm /usr/bin/frpc && rm -rf /var/frpc &")
  self.inputtitle = translate("del_frp")
end


e=t:taboption("other",Flag, "login_fail_exit", translate("Exit program when first login failed"),translate("decide if exit program when first login failed, otherwise continuous relogin to frps."))
e.default = "1"
e.rmempty=false

e=t:taboption("other",Flag, "tcp_mux", translate("TCP Stream Multiplexing"), translate("Default is Ture. This feature in frps.ini and frpc.ini must be same."))
e.default = "1"
e.rmempty=false

e=t:taboption("other",ListValue, "protocol", translate("Protocol Type"),translate("Frp support kcp protocol since v0.12.0"))
e.default = "tcp"
e:value("tcp",translate("TCP Protocol"))
e:value("kcp",translate("KCP Protocol"))

e=t:taboption("other",Flag, "enable_http_proxy", translate("Connect frps by HTTP PROXY"), translate("frpc can connect frps using HTTP PROXY"))
e.default = "0"
e.rmempty=false
e:depends("protocol","tcp")

e=t:taboption("other",Value, "http_proxy", translate("HTTP PROXY"))
e.datatype="uinteger"
e.placeholder="http://user:pwd@192.168.1.128:8080"
e:depends("enable_http_proxy",1)
e.optional=false

e=t:taboption("other",Flag, "enable_cpool", translate("Enable Connection Pool"), translate("This feature is fit for a large number of short connections."))
e.rmempty=false

e=t:taboption("other",Value, "pool_count", translate("Connection Pool"), translate("Connections will be established in advance."))
e.datatype="uinteger"
e.default = "1"
e:depends("enable_cpool",1)
e.optional=false

e=t:taboption("other",ListValue, "log_level", translate("Log Level"))
e.default = "warn"
e:value("trace",translate("Trace"))
e:value("debug",translate("Debug"))
e:value("info",translate("Info"))
e:value("warn",translate("Warning"))
e:value("error",translate("Error"))

e=t:taboption("other",Value, "log_max_days", translate("Log Keepd Max Days"))
e.datatype = "uinteger"
e.default = "3"
e.rmempty=false
e.optional=false


e=t:taboption("log",TextValue,"log")
e.rows=26
e.wrap="off"
e.readonly=true
e.cfgvalue=function(t,t)
return s.readfile("/var/etc/frp/frpc.log")or""
end
e.write=function(e,e,e)
end


t=a:section(TypedSection,"proxy",translate("Services List"))
t.anonymous=true
t.addremove=true
t.template="cbi/tblsection"
t.extedit=o.build_url("admin","services","frp","config","%s")
function t.create(e,t)
new=TypedSection.create(e,t)
luci.http.redirect(e.extedit:format(new))
end
function t.remove(e,t)
e.map.proceed=true
e.map:del(t)
luci.http.redirect(o.build_url("admin","services","frp"))
end
local o=""

e=t:option(DummyValue,"remark",translate("Service Remark Name"))
e.width="10%"

e=t:option(DummyValue,"type",translate("Frp Protocol Type"))
e.width="10%"

e=t:option(DummyValue,"custom_domains",translate("Domain/Subdomain"))
e.width="20%"
e.cfgvalue=function(t,n)
local t=a.uci:get(i,n,"domain_type")or""
local m=a.uci:get(i,n,"type")or""
if t=="custom_domains" then
local b=a.uci:get(i,n,"custom_domains")or"" return b end
if t=="subdomain" then
local b=a.uci:get(i,n,"subdomain")or"" return b end
if t=="both_dtype" then
local b=a.uci:get(i,n,"custom_domains")or""
local c=a.uci:get(i,n,"subdomain")or""
b="%s/%s"%{b,c} return b end
if m=="tcp" or m=="udp" then
local b=a.uci:get(i,"common","server_addr")or"" return b end
end

e=t:option(DummyValue,"remote_port",translate("Remote Port"))
e.width="10%"
e.cfgvalue=function(t,b)
local t=a.uci:get(i,b,"type")or""
if t==""or b==""then return""end
if t=="http" then
local b=a.uci:get(i,"common","vhost_http_port")or"" return b end
if t=="https" then
local b=a.uci:get(i,"common","vhost_https_port")or"" return b end
if t=="tcp" or t=="udp" then
local b=a.uci:get(i,b,"remote_port")or"" return b end
end

e=t:option(DummyValue,"local_ip",translate("Local Host Address"))
e.width="15%"

e=t:option(DummyValue,"local_port",translate("Local Host Port"))
e.width="10%"

e=t:option(DummyValue,"use_encryption",translate("Use Encryption"))
e.width="15%"
e.cfgvalue=function(t,n)
local t=a.uci:get(i,n,"use_encryption")or""
local b
if t==""or b==""then return""end
if t=="1" then b="ON"
else b="OFF" end
return b
end

e=t:option(DummyValue,"use_compression",translate("Use Compression"))
e.width="15%"
e.cfgvalue=function(t,n)
local t=a.uci:get(i,n,"use_compression")or""
local b
if t==""or b==""then return""end
if t=="1" then b="ON"
else b="OFF" end
return b
end

e=t:option(Flag,"enable",translate("Enable State"))
e.width="10%"
e.rmempty=false
return a