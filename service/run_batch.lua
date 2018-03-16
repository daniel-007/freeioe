local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local cjson = require "cjson.safe"
local log = require 'utils.log'

local arg = table.pack(...)
assert(arg.n <= 2)
local batch_id = arg[1]

local tasks = {}

local function gen_task_id()
	local id = batch_id .. '.' .. #tasks
	tasks[#tasks + 1] = id
	return id
end

local batch_env = {
	INSTALL_APP = function(inst, name, version, sn, conf)
		local id = gen_task_id()
		assert(inst and name and version)
		local r, err = skynet.call("UPGRADER", "lua", "install_app", id, {
			name = name,
			inst = inst,
			version = version,
			sn = sn,
			conf = conf
		})
	end,
	REMOVE_APP = function(inst)
		local id = gen_task_id()
		local r, err = skynet.call("UPGRADER", "lua", "uninstall_app", id, {
			inst = inst,
		})
	end,
	UPGRADE_APP = function(inst, version, sn, conf)
		local id = gen_task_id()
		local r, err = skynet.call("UPGRADER", "lua", "upgrade_app", id, {
			inst = inst,
			version = version,
			sn = sn,
			conf = conf,
		})
	end,
	UPGRADE_SYS = function(version, skynet_version, need_ack)
		local id = gen_task_id()
		assert(version)
		local no_ack = need_ack and true or false
		local skynet_args = skynet_version and {version=skynet_version} or nil
		local r, err = skynet.call("UPGRADE", "lua", "upgrade_core", id, {
			version = version,
			no_ack = no_ack,
			skynet = skynet_args,
		})
	end,
	TEST = function(...)
		local id = gen_task_id()
		print(...)
		log.debug(...)
	end,
}

skynet.start(function()
	log.notice("Batch script: ", batch_id)
	local script = arg.n == 2 and arg[2] or datacenter.get("BATCH", batch_id, "script")
	assert(script)
	local f, err = load(script, nil, "bt", batch_env)
	if not f then
		log.error("Loading batch script failed", err)
	else
		local r, err = xpcall(f, debug.traceback)
		print(cjson.encode(tasks))
		if not r then
			log.warning("BATCH run error", err)
			datacenter.set("BATCH_RESULT", batch_id, err)
		else
			datacenter.set("BATCH_RESULT", batch_id, "DONE")
		end
		datacenter.set("BATCH", batch_id, nil)
	end
end)