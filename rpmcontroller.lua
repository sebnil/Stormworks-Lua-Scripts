function init()
	init_was_run = true

	iTerm = 0
	previousError = 0

	-- propeller speed observer
	propellerSpeedObserver = 0
	propellerSpeedObserverTick = 0.1

	previousTransmissionClutchOutput = 0
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
	crankingRequest = input.getBool(2)
	throttleOnly = input.getBool(3)
	leverRequest = input.getNumber(1)
	engineSpeed = input.getNumber(2)

	-- parameters
	neutralThreshold = 0.1--input.getNumber(3)
	neutralEngineSpeed = 3--input.getNumber(4)
	leverToEngineSpeedRatio = 20--input.getNumber(5)
	stoppedEngineSpeedThreshold = 0.5--input.getNumber(6)
	Kp = 3--input.getNumber(7)
	Ki = 0.1--input.getNumber(8)
	Kd = 3--input.getNumber(9)
	iTermAntiWindupGuard = 10--input.getNumber(10)
	stallingEngineSpeedThreshold = 2.5--input.getNumber(3) --3
	clutchTick = 0.003--input.getNumber(4)

	-- debug
	mode = "kill engine"

	-- output
	engineThrottleOutput = 0
	transmissionClutchOutput = 0
	reverseGearEnabledOutput = false
	
	if not ignitionRequest then 
		-- kill the engine
		mode = "kill engine"
		transmissionClutchOutput = 0
		engineSpeedSetpoint = 0 -- throttle will be set directly
	elseif crankingRequest then 
		-- cranking
		mode = "cranking"
		transmissionClutchOutput = 0
		engineSpeedSetpoint = 0 -- throttle will be set directly
	elseif engineSpeed < stallingEngineSpeedThreshold then
		-- cranking
		mode = "anti stall"
		transmissionClutchOutput = 0
		engineSpeedSetpoint = 0 -- throttle will be set directly
	elseif engineSpeed < stoppedEngineSpeedThreshold then
		mode = "stopped"
		transmissionClutchOutput = 0
		engineSpeedSetpoint = 0
	elseif ignitionRequest and math.abs(leverRequest) <= neutralThreshold then
		-- neutral
		mode = "neutral"
		transmissionClutchOutput = 0
		engineSpeedSetpoint = neutralEngineSpeed
	elseif ignitionRequest and math.abs(leverRequest) > neutralThreshold then
		-- regular or throttle only
		if throttleOnly then
			mode = "throttle only"
			transmissionClutchOutput = 0
		else
			mode = "regular"
			transmissionClutchOutput = 1
		end
		engineSpeedSetpoint = math.abs(leverRequest) * leverToEngineSpeedRatio
		engineSpeedSetpoint = clamp(neutralThreshold, 100, engineSpeedSetpoint)
	end

	-- gear switcher
	if leverRequest > 0 then
		gear = 1
		reverseGearEnabledOutput = false
	else
		gear = -1
		reverseGearEnabledOutput = true
	end

	-- PID controller
	if mode == "throttle only" or mode == "regular" or mode == "neutral" then
		error = engineSpeedSetpoint - engineSpeed
		deltaError = error - previousError
		previousError = error

		pTerm = Kp * error
		iTerm = iTerm + Ki * deltaError
		iTerm = clamp(-iTermAntiWindupGuard, iTermAntiWindupGuard, iTerm)
		dTerm = Kd * deltaError

		engineThrottleOutput = pTerm + iTerm + dTerm
		engineThrottleOutput = clamp(0, 1, engineThrottleOutput)
	elseif mode == "cranking" or mode == "anti stall" then
		iTerm = 0.2
		previousError = 0

		engineThrottleOutput = 0.2
	elseif mode == "kill engine" or mode == "stopped" then
		engineThrottleOutput = 0
	end

	-- limit clutch step
	if transmissionClutchOutput > previousTransmissionClutchOutput then
		--transmissionClutchOutput = clamp(0, previousTransmissionClutchOutput, previousTransmissionClutchOutput + clutchTick)
		transmissionClutchOutput = previousTransmissionClutchOutput + clutchTick
	end
	previousTransmissionClutchOutput = transmissionClutchOutput
		
	output.setNumber(1, transmissionClutchOutput)
	output.setNumber(2, engineThrottleOutput)
	output.setBool(1, reverseGearEnabledOutput)

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
		propellerSpeedObserver = gear * engineSpeed * transmissionClutchOutput
	end
end

function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	screen.setColor(0, 255, 0)
	screen.drawText(5, 5, "ignitionRequest: " .. tostring(ignitionRequest))
	screen.drawText(5, 15, "throttleOnly: " .. tostring(throttleOnly))
	screen.drawText(5, 25, "leverRequest: " .. tostring(leverRequest))
	screen.drawText(5, 35, "engineSpeed: " .. tostring(engineSpeed))

	screen.drawText(w/2, 5, "neutralThreshold: " .. tostring(neutralThreshold))
	screen.drawText(w/2, 15, "neutralEngineSpeed: " .. tostring(neutralEngineSpeed))
	screen.drawText(w/2, 25, "leverToEngineSpeedRat: " .. tostring(leverToEngineSpeedRatio))
	screen.drawText(w/2, 35, "stoppedEngineSpeedThr: " .. tostring(stoppedEngineSpeedThreshold))
	screen.drawText(w/2, 45, "Kp: " .. tostring(Kp))
	screen.drawText(w/2, 55, "Ki: " .. tostring(Ki))
	screen.drawText(w/2, 65, "Kd: " .. tostring(Kd))
	screen.drawText(w/2, 85, "iTermAntiWindupGuard: " .. tostring(iTermAntiWindupGuard))

	screen.drawText(w/2, 105, "propObs: " .. tostring(propellerSpeedObserver))
	screen.drawText(w/2, 115, "gear: " .. tostring(gear))


	screen.drawText(5, 45, "mode: " .. mode)
	screen.drawText(5, 55, "clutch: " .. tostring(transmissionClutchOutput))
	screen.drawText(5, 65, "engineSpeedSetpoint: " .. tostring(engineSpeedSetpoint))
	screen.drawText(5, 75, "reverseGear: " .. tostring(reverseGearEnabledOutput))

	screen.drawText(5, 95, "error: " .. tostring(error))
	screen.drawText(5, 105, "deltaError: " .. tostring(deltaError))
	
	screen.drawText(5, 115, "pTerm: " .. tostring(pTerm))
	screen.drawText(5, 125, "iTerm: " .. tostring(iTerm))
	screen.drawText(5, 135, "dTerm: " .. tostring(dTerm))
	screen.drawText(5, 145, "throttleOutput: " .. tostring(engineThrottleOutput))
end