--
local M = {}
M.ntp = require("defquest.ntp")

M.utc_now = nil

M.quests = {}
M.defsave = nil
M.defwindow = nil
M.use_defsave = false
M.use_defwindow = false

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

function M.get_finished(number)
end

function M.clear_finished()
end

function M.clear_all()
end

function M.sync_ntp()
	M.utc_now = M.ntp.get_time()
end

function M.update(dt)
	M.utc_now = M.utc_now + dt
end

return M