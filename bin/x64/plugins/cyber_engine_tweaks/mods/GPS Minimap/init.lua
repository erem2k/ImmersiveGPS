----------------------------------------------------------------
-- GPS Minimap by MusicalAnvil
-- https://www.nexusmods.com/cyberpunk2077/mods/3239
----------------------------------------------------------------


-- For UI stuff
shouldDrawTimeout = 0

-- Minimap States:
-- 0: Modified behaviour, only show while driving
-- 1: On
-- 2: Off

minimapState = 0
uiState = true

InitTrackerMove = true
CornerMoveWait = 3.0

TrackerInCorner = false
TrackerInstance = nil

local config = require("config")
local settings = {}
local defaultSettings = {
	questMove = true
}

local function setupNativeSettingsUI()
    local nativeSettings = GetMod("nativeSettings")

    if not nativeSettings then 
        print("Error: NativeSettingsUI not found!")
        return
    end

    if not nativeSettings.pathExists("/GPSMinimap") then
		nativeSettings.addTab("/GPSMinimap", "GPS Minimap")
	end

    nativeSettings.addSubcategory("/GPSMinimap/Compatibility", "HUD Edit Compatibility")

    nativeSettings.addSwitch("/GPSMinimap/Compatibility", "Move Quest Tracker", "Moves the quest tracker HUD widget when turned on (requires reload).", settings.questMove, defaultSettings.questMove, function(state)
        settings.questMove = state
		config.saveFile("config.json", settings)
    end)
end


registerForEvent('onInit', function()

	config.tryCreateConfig("config.json", defaultSettings)
    config.backwardComp("config.json", defaultSettings)
    settings = config.loadFile("config.json")

	setupNativeSettingsUI()

	local isLoaded = Game.GetPlayer() and Game.GetPlayer():IsAttached() and not Game.GetSystemRequestsHandler():IsPreGame()

	Observe('QuestTrackerGameController', 'OnInitialize', function(self)
		if not isLoaded then
			print('Game Session Started')
			isLoaded = true
			InitTrackerMove = true
			CornerMoveWait = 3
			TrackerInstance = self
		end
	end)

	Observe('QuestTrackerGameController', 'OnUninitialize', function(self)
		if Game.GetPlayer() == nil then
			print('Game Session Ended')
			isLoaded = false
			TrackerInstance = nil
		end
	end)

end)

-- Update
registerForEvent('onUpdate', function(deltaTime)

	-- GPS Minimap Behaviour 
	if minimapState == 0 then
		if not (Game.GetBlackboardSystem():GetLocalInstanced(Game.GetPlayer():GetEntityID(), Game.GetAllBlackboardDefs().PlayerStateMachine):GetInt(Game.GetAllBlackboardDefs().PlayerStateMachine.Vehicle) == 0) then
			Game.GetSettingsSystem():GetVar('/interface/hud', 'minimap'):SetValue(true)
			if TrackerInCorner == true and settings.questMove == true then
				TrackerInCorner = false
				CornerMoveWait = 0.6
				TrackerInstance:OnMinimapToggle(TrackerInCorner)
			end
		else
			Game.GetSettingsSystem():GetVar('/interface/hud', 'minimap'):SetValue(false)
			if TrackerInCorner == false and CornerMoveWait > 0 and settings.questMove == true then
				CornerMoveWait = CornerMoveWait - deltaTime
				if CornerMoveWait <= 0 then
					TrackerInCorner = true
					CornerMoveWait = 0
					TrackerInstance:OnMinimapToggle(TrackerInCorner)
				end
			end
		end
	end
	
	-- UI Timeout
	if shouldDrawTimeout > 0 then
		shouldDrawTimeout = shouldDrawTimeout - deltaTime
		if shouldDrawTimeout <= 0 then
			shouldDrawTimeout = 0
		end
	end

	-- Init Behaviour
	if CornerMoveWait > 0 and InitTrackerMove == true then
		CornerMoveWait = CornerMoveWait - deltaTime
		if CornerMoveWait <= 0 then
			if minimapState == 0 then
				if not (Game.GetBlackboardSystem():GetLocalInstanced(Game.GetPlayer():GetEntityID(), Game.GetAllBlackboardDefs().PlayerStateMachine):GetInt(Game.GetAllBlackboardDefs().PlayerStateMachine.Vehicle) == 0) then
					if settings.questMove == true then
						TrackerInCorner = false
						TrackerInstance:OnMinimapToggle(TrackerInCorner)
					end
				else
					if settings.questMove == true then
						TrackerInCorner = true
						TrackerInstance:OnMinimapToggle(TrackerInCorner)
					end
				end
			end

			InitTrackerMove = false
			CornerMoveWait = 0
		end
	end
end)

-- Draw GUI
registerForEvent('onDraw', function()

	if shouldDrawTimeout > 0 then
		if ImGui.Begin("", bit32.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar )) then
			
			if minimapState == 0 then
				ImGui.Text("Minimap set to Driving Only")
			elseif minimapState == 1 then
				ImGui.Text("Minimap set to On")
			elseif minimapState == 2 then
				ImGui.Text("Minimap set to Off")
			else 
				ImGui.Text("Minimap state undefined")
			end
			
			ImGui.SetWindowSize(10, 10)
			local width, height = GetDisplayResolution()
			local x, y = ImGui.GetWindowSize()
			ImGui.SetWindowPos((width - 10) - x, 10)
		end
	else
		ImGui.End()
	end
	
end)

registerHotkey('gps_minimap_toggle', 'Change Minimap State', function()

	minimapState = minimapState + 1
	if minimapState > 2 then
		minimapState = 0
	end
	
	if minimapState == 1 then 
		Game.GetSettingsSystem():GetVar('/interface/hud', 'minimap'):SetValue(true)
		if settings.questMove == true then
			TrackerInCorner = false
			TrackerInstance:OnMinimapToggle(TrackerInCorner)
		end
	elseif minimapState == 2 then
		Game.GetSettingsSystem():GetVar('/interface/hud', 'minimap'):SetValue(false)
		if settings.questMove == true then
			TrackerInCorner = true
			TrackerInstance:OnMinimapToggle(TrackerInCorner)
		end
	end
	
	shouldDrawTimeout = 3
	
end)




