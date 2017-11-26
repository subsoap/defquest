--
local M = {}
M.ntp = require("defquest.ntp")

M.time_now = 0


M.quests = {}
M.defsave = nil
M.defwindow = nil
M.use_defsave = false
M.use_defwindow = false
M.disconnected = true
M.retry_counter = 0
M.retry_timer = 10
M.retry_attempts = 0
M.retry_attempts_max = -1
M.verbose = false -- if true then successful connection events will be printed, if false only errors
M.use_server_time = true -- if true then NTP servers will be used to sync the current time with, if not then local time will be used only
M.allow_local_time = false -- if true then if NTP servers can't be reached then local time will be synced

function M.window_focus_update(self, event, data)
	if event == window.WINDOW_EVENT_FOCUS_GAINED then
		M.sync_ntp()
	end
end

function M.init()
	M.sync_ntp()
	
	if M.use_defsave == true then
		M.defsave = require("defsave.defsave")
	end
	if M.use_defwindow == true then
		M.defwindow = require("defwindow.defwindow")
		M.defwindow.init()
		M.defwindow.add_listener(M.window_focus_update)
	end
	
end

function M.add(id, time, data)
	local time_now = M.time_now
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

	local quest = {}
	quest.id = id
	quest.end_time = time_now
	quest.data = data
	if id == nil then
		table.insert(M.quests, quest)
	else
		M.quests[id] = quest
	end
end

function M.mark_finished()
end

function M.get_finished(number)
end

function M.clear_finished()
end

function M.clear_all()
end

function M.sync_ntp()
	if not pcall(M.ntp.update_time) then
		print("DefQuest: Warning cannot sync with NTP servers")
		M.disconnected = true
		return false
	else
		M.time_now = M.ntp.time_now
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
	M.time_now = M.time_now + dt
	if M.disconnected == true then
		M.retry_counter = M.retry_counter + dt
	end
	if M.retry_counter >= M.retry_timer then
		M.retry_counter = M.retry_counter - M.retry_timer
		if not M.sync_ntp() then
			M.retry_attempts = M.retry_attempts + 1
			print("DefQuest: NTP sync retry attempt " .. tostring(M.retry_attempts) .. " failed")
		end
	end
end

return M