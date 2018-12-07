-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 0.5
TIMER_CYCLE = 10

-- DATA
ID = os.getComputerID()
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
peripheralList = {}
originalTerm = term.current()
timer = nil
protocol = "p_energy"
current_energy = 0
total_energy = 0

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
  return nil
end

function warnMissingPeripheral(name)
	clear()
    print("##### ERROR #####")
	print("Peripheral '"..name.."' missing. Please attach to continue...")
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
		 monitor.setTextScale(TEXT_SCALE)
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
	clear()
	print("##### ENERGY SERVER #####")
	print("Energy Status:")
	print("")
	local percent = round(current_energy / total_energy * 100, 2)
	print("\t"..current_energy.."/ "..total_energy.." RF")
	print("")
	print("\tApprox. "..percent.."%")
end

function getEnergyStatus()
	current_energy = 0
	total_energy = 0
	rednet.broadcast("Getting energy status...","p_energy_status_get")
end

function calculateEnergy(msg)
	current_energy = current_energy + msg.current
	total_energy = total_energy + msg.total
end

function round(num, numDecimalPlaces)
  if numDecimalPlaces and numDecimalPlaces>0 then
    local mult = 10^numDecimalPlaces
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

-- INIT
os.setComputerLabel("Energy Server")
mapPeripherals()
modem = peripheralList.modem
open(modem)
getEnergyStatus()
timer = os.startTimer(TIMER_CYCLE)

-- LOOP
while true do


	event, par1, par2, par3, par4, par5 = os.pullEvent()
	
	   -- Rednet message received
    if event == "rednet_message" then
        local senderID = par1; senderMessage = par2; senderProtocol = par3
        -- Replyed status
        if senderProtocol == "p_energy_status_reply" then
           calculateEnergy(senderMessage)
		   redraw()
		-- ARP msg
		elseif senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
		end
	elseif (event == "timer" and par1 == timer) then
		getEnergyStatus()
		timer = os.startTimer(TIMER_CYCLE)
	elseif event == "peripheral_detach" or event == "peripheral"  then
		sleep(0.5)
		mapPeripherals()
	end
end