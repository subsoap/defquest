--
local M = {}
M.ntp = require("defquest.ntp")
M.mt = require("defquest.mt")

M.time_now = 0 -- the current time, check if defos.isconnected is true to trust this or not
M.time_offset = 0 -- a time offset option which is applied to time_now whenever syncing happens - mostly only useful to control timezone offset for midnight/noon


M.quests = {} -- 
M.defsave = nil -- if defsave is used it's loaded here
M.defwindow = nil -- if defwindow is used it's loaded here
M.use_defsave = true -- to use defsave or not
M.use_defwindow = true -- to use defwindow or not
M.disconnected = true -- if disconnected is true then you should not trust synced time / temp disable time based features
M.retry_counter = 0 -- current counter value of disconnected retry timer
M.retry_timer = 10 -- total time in seconds between disconnected retry attemps
M.retry_attempts = 0 -- current counter value of number of retry attempts
M.retry_attempts_max = -1 -- maximum retry attempts allow (currently not used)
M.verbose = true -- if true then successful connection events will be printed, if false only errors

M.use_ntp = true
M.use_http = true
M.use_http_for_html5 = true
M.sysinfo = sys.get_sys_info()

M.use_server_time = true -- if true then NTP servers will be used to sync the current time with, if not then local time will be used only
M.allow_local_time = false -- if true then if NTP servers can't be reached then local time will be synced (could have BAD results)
M.defsave_filename = "defquest"
M.keep_finalized = false -- set to false if you want finalized quests not stored in a finalized table, otherwise they are lost forever once game session closes
M.check_timer = 60 -- number of seconds in between automatic checks to see if any quests are finished
M.check_timer_counter = 0 -- current check counter value in seconds
M.paused = false -- if paused most automatic features do not continue to happen when they normally would, pause when not needed
M.default_tags = {}

M.ACTIVE = 1
M.FINISHED = 2
M.EITHER = 3

local function round(x)
	local a = x % 1
	x = x - a
	if a < 0.5 then a = 0
	else a = 1 end
	return x + a
end

function M.sync_time()
	if M.sysinfo.system_name ~= "HTML5" then
		M.sync_ntp()
	else
		M.sync_http()
	end	
end

local function http_result(self, _, response)
	if response.status == 200 then
    	M.time_now = response.response
    	print(response.response)
    	M.disconnected = false
		M.retry_counter = 0
		M.retry_attempts = 0    	
    else
    	M.disconnected = true
    end
end


function M.sync_http()
	http.request("https://www.timestampnow.com/", "GET", http_result)
end



function M.difference_from_now(seconds)
	return seconds - M.time_now
end

function M.get_time_left(id)
	return M.difference_from_now(M.quests[id].end_time)
end

function M.format_time(total_seconds)

	if total_seconds <= 0 then
		 M.check_timer_counter = M.check_timer
		return "0m 0s"
	elseif total_seconds < 60 * 60 then -- less than an hour
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60)
		return tostring(minutes) .. "m " .. tostring(seconds) .. "s"
	elseif total_seconds < 60 * 60 * 24 then -- less than a day
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60) % 60
		local hours = math.floor(total_seconds / 3600)
		return tostring(hours) .. "h " .. tostring(minutes) .. "m " .. tostring(seconds) .. "s"		
	elseif total_seconds < 60 * 60 * 24 * 365 then -- less than a year
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60) % 60
		local hours = math.floor(total_seconds / 3600) % 24
		local days = math.floor(total_seconds / (3600 * 24))
		return tostring(days) .. "d " .. tostring(hours) .. "h " .. tostring(minutes) .. "m " .. tostring(seconds) .. "s"		
	else
		local seconds = round(total_seconds % 60)
		local minutes = math.floor(total_seconds / 60) % 60
		local hours = math.floor(total_seconds / 3600) % 24 
		local days = math.floor(total_seconds / (3600 * 24)) % 365 
		local years = math.floor(total_seconds / (3600 * 24 * 365))
		return tostring(years) .. "y " .. tostring(days) .. "d " .. tostring(hours) .. "h " .. tostring(minutes) .. "m " .. tostring(seconds) .. "s"				
	end
end

function M.window_focus_update(self, event, data)
	if event == window.WINDOW_EVENT_FOCUS_GAINED then
		M.sync_time()
	end
end

function M.init()
	M.sync_time()
	M.mt.seed_mt(os.time())
	
	if M.use_defsave == true then
		M.defsave = require("defsave.defsave")
		M.defsave.load("defquest")
		--pprint(M.defsave.loaded)
		M.quests = M.defsave.get(M.defsave_filename, "defquest") or {}
		--pprint(M.quests)
	end
	if M.use_defwindow == true then
		M.defwindow = require("defwindow.defwindow")
		M.defwindow.init()
		M.defwindow.add_listener(M.window_focus_update)
	end
	
end

function M.generate_random_id()
	local number = M.mt.random(1, 1000000)
	while M.quests["random_id_" .. tostring(number)] ~= nil do
		number = M.mt.random(1, 1000000)
	end
	return "random_id_" .. tostring(number)
end

function M.add(id, time, data, tags)
	tags = tags or M.default_tags
	local time_now = M.time_now
	if time.midnight == true then
		time_now = (round(time_now / 86400) + 1) * 86400
	elseif time.noon == true then
		local past_noon_check = (round(time_now / 86400)) * 86400 + 43200
		if M.time_now >= past_noon_check then
			time_now = (round(time_now / 86400) + 1) * 86400 + 43200
		else
			time_now = (round(time_now / 86400)) * 86400 + 43200
		end
	else
	
		time.seconds = time.seconds or 0
		time.minutes = time.minutes or 0
		time.hours = time.hours or 0
		time.days = time.days or 0
		time.years = time.years or 0
		
		time_now = time_now + time.seconds
		time_now = time_now + time.minutes * 60
		time_now = time_now + time.hours * 60 * 60
		time_now = time_now + time.days * 60 * 60 * 24
		time_now = time_now + time.years * 60 * 60 * 24 * 365
	end
	if time.offset ~= nil then
		time_now = time_now + time.offset
	end
	

	local quest = {}
	quest.id = id
	quest.end_time = time_now
	quest.data = data
	quest.tags = tags
	if id == nil then
		M.quests[M.generate_random_id()] = quest
	else
		M.quests[id] = quest
	end
	M.defsave.set(M.defsave_filename, "defquest", M.quests )
end

function M.quest_exists(id)
	if M.quests[id] ~= nil then
		return true
	else
		return false
	end
end

function M.mark_finished()
	local quests_finished = {}
	for key, value in pairs(M.quests) do
		if M.quests[key].finished ~= true then
			if M.quests[key].end_time <= M.time_now then
				M.quests[key].finished = true
				table.insert(quests_finished, key)
			end
		end
	end
	return quests_finished
end

function M.get_active()
	M.mark_finished()
	local quests_active = {}
	for key, value in pairs(M.quests) do
		if M.quests[key].finished ~= true then
			table.insert(quests_active, key)
		end
	end
	return quests_active
end

function M.get_finished()
	local quests_finished = {}
	for key, value in pairs(M.quests) do
		if M.quests[key].finished == true then
			table.insert(quests_finished, key)
		end
	end
	return quests_finished
end

function M.get_tagged(tag, filter)
	local tagged = {}
	filter = filter or M.EITHER
	local quest_table = {}
	if filter == M.FINISHED then
		for key, value in pairs(M.get_finished()) do
			quest_table[value] = M.quests[value]
		end
	elseif filter == M.ACTIVE then
		for key, value in pairs(M.get_active()) do
			quest_table[value] = M.quests[value]
		end
	elseif filter == M.EITHER then
		quest_table = M.quests
	else
		print("DefQuest: Warning! Bad filter option!")
		return {}
	end
	
	for key, value in pairs(quest_table) do
		if quest_table[key].tags ~= nil then
			for kkey, vvalue in pairs(quest_table[key].tags) do
				if vvalue == tag then
					table.insert(tagged, key)
				end
			end
		end
	end
	return tagged
end

function M.shift_end_time(quests, seconds)
	for key, value in pairs(quests) do
		M.quests[value].end_time = M.quests[value].end_time + seconds
	end
end

function M.clear(id)
	M.quests[id] = nil
	M.defsave.set(M.defsave_filename, "defquest", M.quests )
end

function M.clear_finished()
	for key, value in pairs(M.get_finished()) do
		M.quests[value] = nil
	end
	M.defsave.set(M.defsave_filename, "defquest", M.quests )
end

function M.clear_all()
	M.quests = {}
	M.defsave.set(M.defsave_filename, "defquest", M.quests )
end

function M.sync_ntp()
	if not pcall(M.ntp.update_time) then
		print("DefQuest: Warning cannot sync with NTP servers")
		M.disconnected = true
		return false
	else
		M.time_now = M.ntp.time_now + M.time_offset
		if M.verbose then print("DefQuest: Time synced - " .. tostring(M.time_now)) end
		M.disconnected = false
		if M.retry_counter > 0 then
			print("DefQuest: NTP servers have successfully synced after a disconnect")
		end
		M.retry_counter = 0
		M.retry_attempts = 0
		return true
	end
end

function M.update(dt)
	M.check_timer_counter = M.check_timer_counter + dt
	if M.check_timer_counter >= M.check_timer then
		M.check_timer_counter = M.check_timer_counter - M.check_timer
		local quests_finished = M.mark_finished()
		if M.verbose == true then print("DefQuest: Checking for any finished quests... " .. tostring(#quests_finished) ) end
	end
	
	M.time_now = M.time_now + dt
	if M.disconnected == true then
		M.retry_counter = M.retry_counter + dt
	end
	if M.retry_counter >= M.retry_timer then
		M.retry_counter = M.retry_counter - M.retry_timer
		if not M.sync_time() then
			M.retry_attempts = M.retry_attempts + 1
			if M.sysinfo.system_name ~= "HTML5" then
				print("DefQuest: NTP sync retry attempt " .. tostring(M.retry_attempts) .. " failed")
			else
				print("DefQuest: HTTP sync retry attempt " .. tostring(M.retry_attempts) .. " failed")
			end
		end
	end
	if M.sysinfo.system_name == "HTML5" then
		M.defsave.verbose = false
		M.defsave.save_all()
	end
end

function M.final()
	M.defsave.save_all()
end

return M