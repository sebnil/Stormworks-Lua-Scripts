batteryStarPrev = 0
batteryPortPrev = 0
chargingMode = 2 -- 0:off 1:on 2:auto
chargingState = false
clutchStep = 0
clutch = 0
chargingModeUpPrev = false
chargingModeDown = false

function onTick()
    crank = input.getBool(3)
    chargingModeUp = input.getBool(1)
    chargingModeDown = input.getBool(2)
    batteryStar = input.getNumber(1) -- battery reading from 0 to 1, Small battery holds 800 units
    batteryPort = input.getNumber(2)
    generatorCurrent = input.getNumber(3)
    --chargingMode = input.getNumber(5)
    
    if (chargingModeUp and (not chargingModeUpPrev) and (chargingMode < 2)) then
        chargingMode = chargingMode + 1
    elseif (chargingModeDown and (not chargingModeDownPrev) and (chargingMode > 0)) then
        chargingMode = chargingMode - 1
    end
    
    if (chargingMode == 0) then
        chargingState = false
    end
    
    if (crank) then
        clutch = 0
    elseif ( ((batteryStar < 0.8 or batteryPort < 0.8 or chargingState == true) and chargingMode == 2) or (chargingMode == 1) ) then
        chargingState = true
        if (clutch < 0.98) then
            clutch = clutch + 0.01
        elseif (clutch >= 0.98) then
            clutch = 1
        end
        if ( (batteryStar > 0.99) and (batteryPort > 0.99) ) then
            chargingState = false
        end
    else
        clutch = 0
        clutchStep = 0
        chargingState = false
    end
    
    currentRate = (batteryStar+batteryPort)-(batteryStarPrev+batteryPortPrev)
    
    output.setBool(1, chargingState)
    output.setNumber(1, batteryPort)
    output.setNumber(2, batteryStar)
    output.setNumber(3, currentRate)
    output.setNumber(4, clutch)
    output.setNumber(5, chargingMode)
    batteryStarPrev = batteryStar
    batteryPortPrev = batteryPort
    chargingModeUpPrev = chargingModeUp
    chargingModeDownPrev = chargingModeDown
end
