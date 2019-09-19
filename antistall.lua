function init()
	init_was_run = true
	
	powerSetpoint = 0
	requestedGear = 1
	actualGear = 1
	gearSwitchSignal = false
	propellerSpeedObserver = 0
	
	neutral_area = 0.1
	neutral_idle_throttle = 0.2
	lowspeed_idle_throttle = 0.2
	anti_stall_throttle = 0.7
	anti_stall_engine_speed_threshold = 4
	stopped_engine_speed_threshold = 0.5
	propellerSpeedObserverTick = 0.1
	
	transmissionClutchOutput = 1
	engineThrottleOutput = 0
	transmissionGearMode = 0

	mode = "kill engine"
end

function clamp(l, u, value)
	if value < l then
		return l
	elseif value > u then
		return u
	else
		return value
	end
end

function onTick()
	if not init_was_run then
		init()
	end
	
	-- inputs
	ignitionRequest = input.getBool(1)
	lowSpeedRequest = input.getBool(2)
	throttleRequest = input.getNumber(1)
	engineSpeed = input.getNumber(2)
	
	if not ignitionRequest then 
		-- kill the engine
		mode = "kill engine"
		transmissionClutchOutput = 0
		powerSetpoint = 0
	elseif engineSpeed < stopped_engine_speed_threshold then
		mode = "stopped"
		transmissionClutchOutput = 0
		powerSetpoint = neutral_idle_throttle
	elseif engineSpeed < anti_stall_engine_speed_threshold then
		-- anti stall
		mode = "anti stall"
		transmissionClutchOutput = 0
		powerSetpoint = anti_stall_throttle	
	elseif ignitionRequest and math.abs(throttleRequest) <= neutral_area then
		-- neutral
		mode = "neutral"
		transmissionClutchOutput = 0
		powerSetpoint = neutral_idle_throttle
	elseif ignitionRequest and math.abs(throttleRequest) > neutral_area then
		-- regular and lowspeed control
		if lowSpeedRequest then
			mode = "lowspeed"
			transmissionClutchOutput = clamp(0, 1, math.abs(throttleRequest) - neutral_area)
			powerSetpoint = lowspeed_idle_throttle
			if throttleRequest > 0 then
				requestedGear = 1
			else
				requestedGear = -1
			end
		else
			mode = "regular"
			transmissionClutchOutput = 1
			powerSetpoint = math.abs(throttleRequest)
			if throttleRequest > 0 then
				requestedGear = 1
			else
				requestedGear = -1
			end
		end
	end
	engineSpeedSetpoint = clamp(2, 20, powerSetpoint * 20)
	
	-- gear switcher
	if requestedGear ~= actualGear then
		
		if propellerSpeedObserver ~= 0 then
			mode = "crash stop"
			transmissionClutchOutput = 0
			engineThrottleOutput = neutral_idle_throttle
		else
			actualGear = requestedGear
		end
	end
	if actualGear == -1 then
		gearSwitchSignal = true
	else
		gearSwitchSignal = false
	end

	-- propeller speed observer
	if transmissionClutchOutput == 0 then
		if propellerSpeedObserver > propellerSpeedObserverTick then
			propellerSpeedObserver = propellerSpeedObserver - propellerSpeedObserverTick
		elseif propellerSpeedObserver < -propellerSpeedObserverTick then
			propellerSpeedObserver = propellerSpeedObserver + propellerSpeedObserverTick
		else
			propellerSpeedObserver = 0	
		end
	else
		propellerSpeedObserver = actualGear * engineSpeed
	end
		
	output.setNumber(1, transmissionClutchOutput)
	output.setNumber(2, engineSpeedSetpoint)
	output.setBool(1, gearSwitchSignal)
end

function onDraw()
	w = screen.getWidth()				  -- Get the screen's width and height
	h = screen.getHeight()					
	screen.setColor(0, 255, 0)			 -- Set draw color to green
	screen.drawText(5, 5, "ignitionRequest: " .. tostring(ignitionRequest))
	screen.drawText(5, 15, "throttleRequest: " .. tostring(throttleRequest))
	screen.drawText(5, 25, "engineSpeed: " .. tostring(engineSpeed))

	screen.drawText(5, 45, "mode: " .. mode)
	screen.drawText(5, 55, "transmissionClutchOutput: " .. tostring(transmissionClutchOutput))
	screen.drawText(5, 65, "engineThrottleOutput: " .. tostring(engineThrottleOutput))
	screen.drawText(5, 75, "requestedGear: " .. tostring(requestedGear))
	screen.drawText(5, 85, "actualGear: " .. tostring(actualGear))
	screen.drawText(5, 95, "gearSwitchSignal: " .. tostring(gearSwitchSignal))
	
	screen.drawText(5, 105, "propellerSpeedObserver: " .. tostring(propellerSpeedObserver))
	screen.drawText(5, 115, "powerSetpoint: " .. tostring(powerSetpoint))
	screen.drawText(5, 125, "engineSpeedSetpoint: " .. tostring(engineSpeedSetpoint))
end