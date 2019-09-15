local canShow = true

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end

		enum.destructor = nil
		enum.handle = nil
	end
}

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function GetVehicles()
	local vehicles = {}

	for vehicle in EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle) do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end

function GetVehiclesInArea(coords, area)
	local vehicles       = GetVehicles()
	local vehiclesInArea = {}

	for i=1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance      = GetDistanceBetweenCoords(vehicleCoords, coords.x, coords.y, coords.z, true)

		if distance <= area then
			table.insert(vehiclesInArea, vehicles[i])
		end
	end

	return vehiclesInArea
end

Citizen.CreateThread(function ()
    while true do
    	Citizen.Wait(10)
    	local canSleep = true
    	local playerPed = GetPlayerPed(-1)
        if IsPedInAnyVehicle(playerPed, false) then
            local myVehicle = GetVehiclePedIsIn(playerPed, false)
            local myVehicleHash = GetEntityModel(myVehicle)
            if myVehicleHash == 1044954915 then
            	if canShow then
            		showNotification("Press ~INPUT_CONTEXT~ to use the magnet")
            		canShow = false
            	end
            	canSleep = false
            	if IsControlJustPressed(1, 38) then
	                local nearbyVehicles = GetVehiclesInArea(GetEntityCoords(myVehicle), 20.0)
	                for k, vehicle in pairs(nearbyVehicles) do
	                    if vehicle ~= myVehicle then
	                        if IsEntityAttachedToAnyVehicle(vehicle) then
	                            if IsEntityAttachedToEntity(vehicle, myVehicle) then
	                                DetachEntity(vehicle, true, true)
	                            end
	                        else
	                            local vehicleHash = GetEntityModel(vehicle)
	                            if IsThisModelACar(vehicleHash) or IsThisModelABike(vehicleHash) or IsThisModelATrain(vehicleHash) or IsThisModelABicycle(vehicleHash) or IsThisModelAQuadbike(vehicleHash) then
	                                local vehiclePos = GetEntityCoords(vehicle)
	                                local myVehiclePos = GetEntityCoords(myVehicle)
	                                local pDist = GetDistanceBetweenCoords(vehiclePos.x, vehiclePos.y, vehiclePos.z, myVehiclePos.x, myVehiclePos.y, myVehiclePos.z, true)
	                                if pDist <= 7.0 then
	                                    AttachEntityToEntity(vehicle, myVehicle, 0, 0.0, -3.0, -1.0, 0.0, 0.0, 0.0, true, true, true, true, 1, true)
	                                end
	                            end 
	                        end
	                    end
	                end
	            end
            end
        else
        	canShow = true
        end
        if canSleep then 
        	Citizen.Wait(500)
        end
    end
end)

function showNotification(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, 0, 1, 5000)
end
