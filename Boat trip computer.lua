-- Features: Calculates total fuel, fuel percentage, fuel rate, time to empty, distance to empty

function init()
	init_was_run = true

	previousFluidTotal = 0

	-- total fluid filter
	fluidTotalSampleIndex = 0
	fluidTotalSamples = {}
	fluidTotalMovingAverageFilterTaps = 600 -- filter parameter
	for i=0, fluidTotalMovingAverageFilterTaps do
		fluidTotalSamples[i] = fluidTotal -- warmup
	end

	-- speed filter
	speedSampleIndex = 0
	speedSamples = {}
	speedMovingAverageFilterTaps = 60 -- filter parameter
	for i=0, speedMovingAverageFilterTaps do
		speedSamples[i] = 0
	end
end

function onTick()
	-- inputs
	fluidMax = input.getNumber(1)
	fluidTotal = input.getNumber(2)
	speedInMetersPerSecond = input.getNumber(3)

	-- do init a bit later to warmup filters
	if not init_was_run then
		init()
	end

	-- total fluid filter
	fluidTotalSamples[fluidTotalSampleIndex] = fluidTotal
	fluidTotalSampleIndex = (fluidTotalSampleIndex + 1) % fluidTotalMovingAverageFilterTaps
	tot = 0
    for i=0, fluidTotalMovingAverageFilterTaps do
		tot = tot + fluidTotalSamples[i]
	end
	fluidTotalFiltered = tot / fluidTotalMovingAverageFilterTaps

	-- speed filter
	speedSamples[speedSampleIndex] = speedInMetersPerSecond
	speedSampleIndex = (speedSampleIndex + 1) % speedMovingAverageFilterTaps
	tot = 0
    for i=0, speedMovingAverageFilterTaps do
		tot = tot + speedSamples[i]
	end
	speedInMetersPerSecondFiltered = tot / speedMovingAverageFilterTaps

	-- trip computer calculations
	fluidPercentage = fluidTotalFiltered / fluidMax * 100

	fuelChange = previousFluidTotal - fluidTotalFiltered
	fuelRateInLitresPerMinute = fuelChange * 60 * 60 -- 60 ticks per second, 60 s in a minute
	previousFluidTotal = fluidTotalFiltered

	if fuelRateInLitresPerMinute > 0 then
		timeToEmptyInMinutes = fluidTotalFiltered / fuelRateInLitresPerMinute
	else
		timeToEmptyInMinutes = -1
	end
	timeToEmptyInSeconds = timeToEmptyInMinutes * 60

	speedInMetersPerMinute = speedInMetersPerSecondFiltered * 60

	if timeToEmptyInMinutes ~= -1 then
		distanceToEmptyInKilometers = speedInMetersPerMinute * timeToEmptyInMinutes / 1000
	else
		distanceToEmptyInKilometers = -1
	end

	-- outputs
	output.setNumber(1, fluidTotalFiltered)
	output.setNumber(2, fluidPercentage)
	output.setNumber(3, fuelRateInLitresPerMinute)
	output.setNumber(4, timeToEmptyInMinutes)
	output.setNumber(5, distanceToEmptyInKilometers)

end

function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	screen.setColor(0, 255, 0)
	screen.drawText(5, 5, "fluidMax: " .. tostring(fluidMax))
	screen.drawText(5, 15, "speed: " .. tostring(speedInMetersPerSecond))
	screen.drawText(5, 25, "speedF: " .. tostring(speedInMetersPerSecondFiltered))
	screen.drawText(5, 35, "fluid1: " .. tostring(fluid1))
	screen.drawText(5, 45, "fluid2: " .. tostring(fluid2))
	screen.drawText(5, 55, "fluid3: " .. tostring(fluid3))
	screen.drawText(5, 65, "fluid4: " .. tostring(fluid4))
	screen.drawText(5, 75, "fluid5: " .. tostring(fluid5))
	screen.drawText(5, 85, "fluid6: " .. tostring(fluid6))
	screen.drawText(5, 95, "fluid7: " .. tostring(fluid7))
	screen.drawText(5, 105, "fluid8: " .. tostring(fluid8))
	screen.drawText(5, 115, "fuelChange: " .. tostring(fuelChange))
	screen.drawText(5, 125, "previousFluidTotal: " .. tostring(previousFluidTotal))
	screen.drawText(5, 135, "timeToEmptyInSeconds: " .. tostring(timeToEmptyInSeconds))
	screen.drawText(5, 145, "speedInMetersPerMinute: " .. tostring(speedInMetersPerMinute))
	screen.drawText(w/2, 5, "fluidTotal: " .. tostring(fluidTotal))
	screen.drawText(w/2, 15, "fluidTotalF: " .. tostring(fluidTotalFiltered))
	screen.drawText(w/2, 35, "fluid%: " .. tostring(fluidPercentage))
	screen.drawText(w/2, 45, "fuelRateInLPM: " .. tostring(fuelRateInLitresPerMinute))
	screen.drawText(w/2, 55, "timeToEmptyInM: " .. tostring(timeToEmptyInMinutes))
	screen.drawText(w/2, 65, "distanceToEmptyInKm: " .. tostring(distanceToEmptyInKilometers))
end
