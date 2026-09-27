-- MineWorldPulseUI: client banner/toast for World Pulse (keeps MineClient under local cap).

local MineWorldPulseUI = {}

local state = {
	banner = nil,
	event = nil,
	endsAt = 0,
	nextAt = 0,
	eligible = false,
	lockReason = nil,
	serverNow = 0,
	localAtRecv = 0,
	showToast = nil,
}

function MineWorldPulseUI.install(gui, GuiService, BG, FONT_M, TEXT, round, stroke)
	if state.banner then
		return state.banner
	end
	local banner = Instance.new("TextLabel")
	banner.Name = "WorldPulseBanner"
	banner.Visible = false
	banner.BackgroundColor3 = BG
	banner.BackgroundTransparency = 0.06
	banner.Font = FONT_M
	banner.TextSize = 15
	banner.TextColor3 = TEXT
	banner.Position = UDim2.new(0.5, -210, 0, 62 + GuiService:GetGuiInset().Y)
	banner.Size = UDim2.fromOffset(420, 44)
	banner.Text = ""
	banner.TextWrapped = true
	banner.Parent = gui
	if round then
		round(banner)
	end
	if stroke then
		stroke(banner)
	end
	state.banner = banner
	return banner
end

function MineWorldPulseUI.setToast(fn)
	state.showToast = fn
end

function MineWorldPulseUI.apply(payload)
	if type(payload) ~= "table" then
		return
	end
	state.event = payload.event
	state.endsAt = tonumber(payload.endsAt) or 0
	state.nextAt = tonumber(payload.nextAt) or 0
	state.eligible = payload.eligible == true
	state.lockReason = payload.lockReason
	state.serverNow = tonumber(payload.serverNow) or os.clock()
	state.localAtRecv = os.clock()
	local toast = state.showToast
	if toast then
		if payload.phase == "start" and payload.event then
			local name = payload.event.name or "World Pulse"
			if payload.eligible then
				toast("World Pulse: " .. name)
			else
				toast("World Pulse: " .. name .. " (locked)")
			end
		elseif payload.phase == "end" then
			toast("World Pulse ended")
		end
	end
end

function MineWorldPulseUI.refresh()
	local banner = state.banner
	if not banner then
		return
	end
	local ev = state.event
	if not ev or state.endsAt <= 0 then
		banner.Visible = false
		return
	end
	local left = state.endsAt - (state.serverNow + (os.clock() - state.localAtRecv))
	if left <= 0 then
		banner.Visible = false
		return
	end
	local sec = math.max(0, math.floor(left + 0.5))
	local clock = string.format("%d:%02d", math.floor(sec / 60), sec % 60)
	local tier = tonumber(ev.tier) or 1
	if state.eligible then
		banner.Text = string.format("T%d %s  ·  %s left", tier, ev.name or "Pulse", clock)
	else
		banner.Text = string.format("T%d %s  ·  LOCKED — %s", tier, ev.name or "Pulse", tostring(state.lockReason or "gated"))
	end
	banner.Visible = true
end

function MineWorldPulseUI.hookRender(RunService)
	RunService.RenderStepped:Connect(function()
		if state.banner and (state.banner.Visible or (state.event and state.endsAt > 0)) then
			MineWorldPulseUI.refresh()
		end
	end)
end

return MineWorldPulseUI
