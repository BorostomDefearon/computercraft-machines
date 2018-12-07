-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 0.5
TIMER_CYCLE = math.random(5,15)

-- DATA
ID = os.getComputerID()
peripheralList = {}
requiredPeripherals = {"modem","thermalexpansion_tank"}
optionalPeripherals = {"monitor"}
originalTerm = term.current()
output = "bottom"
protocol = "p_fluid"
fluidID = "-1"
fluids = nil
timer = nil

 -- COMMON FUNCTIONS
 function open(side)
	rednet.close(side)
	rednet.open(side)
end

function clear()
	term.clear()
	term.setCursorPos(1,1)
end

 function getDeviceSide(deviceType)
  local lstSides = {"left","right","top","bottom","front","back"};
  for i, side in pairs(lstSides) do
    if (peripheral.isPresent(side)) then
      if (peripheral.getType(side) == string.lower(deviceType)) then
        return tostring(side);
      end
    end
  end
  return nil;
end

function warnMissingPeripheral(name)
	clear()
    print("##### ERROR #####")
	print("Peripheral '"..name.."' missing. Please attach and press any key to continue...")
	local event,side = os.pullEvent("peripheral")
	mapPeripherals()
end

function mapPeripherals()
	for i,p in ipairs(requiredPeripherals) do
		if getDeviceSide(p) == nil then
			warnMissingPeripheral(p)
		else
			peripheralList[p] = getDeviceSide(p)
		end
	end
	
	for i,p in ipairs(optionalPeripherals) do
		peripheralList[p] = getDeviceSide(p) 
	end
	scanMonitor()
	redraw() 
end

function scanMonitor()
	local monitor = peripheralList.monitor
	if monitor ~= nil then
		 clear()
		 monitor = peripheral.wrap(monitor)
		 monitor.setTextScale(textScale)
		 term.redirect(monitor)
	else
		term.redirect(originalTerm)
	end
end

function replyARP(myID,senderID,label, prot)
    local msg = {}
	msg.name = os.getComputerLabel()
	msg.ID = ID
	msg.protocol = protocol
    rednet.send(senderID,msg,"p_arp_reply")
end

-- SPECIFIC FUNCTIONS
 function redraw()
 	term.clear()
	term.setCursorPos(1,1)
	print("##### LISTENING on Fluid ID: "..fluidID.." - "..os.getComputerLabel().." #####")
 end
 
 function getID()
	rednet.broadcast(os.getComputerLabel(),"p_fluid_array_get")
end

function setID(msg)
	if fluids == nil then
		fluids = msg.array
		for i,line in ipairs(fluids) do
			if (line.name == os.getComputerLabel()) then
				fluidID = line.fluidID
			end
		end
	end
	redraw()
end
 
 function sendInfo()
 	local t = tank.getTankInfo()
 	local tankCapacity = t[1].capacity; tankAmount = nil
	if pcall(function () return t[1].contents.amount end) then
		tankAmount = t[1].contents.amount
	else
		tankAmount = 0
	end
	local msg = {}
	msg.fluidID = fluidID; msg.capacity= tankCapacity; msg.amount = tankAmount
	rednet.broadcast(msg, "p_fluid_info_reply")
 end
 
 function servo(msg, bool)
 	if tonumber(msg.fluidID) == tonumber(fluidID) then
		redstone.setOutput(output, bool)
	end
 end
 
 -- INIT
mapPeripherals()
modem = peripheralList.modem
open(modem)
tank = peripheral.wrap(peripheralList.thermalexpansion_tank)
timer = os.startTimer(TIMER_CYCLE)

 -- LOOP
while true do
    local event, par1, par2, par3, par4, par5 = os.pullEvent()
    -- Rednet message received
    if event == "rednet_message" then
        local senderID = par1; senderMessage = par2; senderProtocol = par3
        -- Fluid request
        if senderProtocol == "p_fluid_servo_on" then
            servo(senderMessage, true)
		elseif senderProtocol == "p_fluid_servo_off" then
            servo(senderMessage, false)
        --ARP protocol
        elseif senderProtocol == "p_arp" then replyARP(ID,senderID,os.getComputerLabel(),protocol)
		-- Replied getID()
		elseif senderProtocol == "p_fluid_array" then
			setID(senderMessage)
		-- Capacity info
		elseif senderProtocol == "p_fluid_info" then
			sendInfo()
		-- Server sent a reboot
		elseif senderProtocol == "p_fluid_reboot" then
			os.reboot()
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
        end
    -- Detached peripheral
	elseif event == "peripheral_detach" or event == "peripheral" then
		sleep(0.5)
		mapPeripherals()
	elseif event == "timer" and par1 == timer then
		if fluidID == "-1" then
			getID()
		end
		timer = os.startTimer(TIMER_CYCLE)
	end

end
