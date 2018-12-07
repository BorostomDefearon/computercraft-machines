-- CONSTANTS
TEXT_SCALE = 0.5
TIMER_CYCLE = 10
SLEEP_AMOUNT = 0.5

-- DATA
ID = os.getComputerID()
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
peripheralList = {}
originalTerm = term.current()
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

-- SPECIFIC FUNCTIONS
function redraw()
	clear()
	print("##### ARP SERVER #####")
	print("")
	print("Active Machines:")
	
end

function writeARP(msg)
	local machine = msg.name; machineID = tonumber(msg.ID); machineProtocol = msg.protocol
	if machineID < 10 then
		print("\t[0"..machineID.."]\t"..machine)
	else
		print("\t["..machineID.."]\t"..machine)
	end
end

function sendARP(modem)
	rednet.broadcast("ARP message","p_arp")
end

-- INIT
os.setComputerLabel("ARP Server")
mapPeripherals()
modem = peripheralList.modem
open(modem)
timer = os.startTimer(TIMER_CYCLE)
sendARP(modem)

-- LOOP
while true do
	event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Received rednet message
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		if senderProtocol == "p_arp_reply" then
			writeARP(senderMessage)
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
		end
	elseif (event == "timer" and par1 == timer) then
		sendARP(modem)
		redraw()
		timer = os.startTimer(TIMER_CYCLE)
	-- Peripheral
	elseif event == "peripheral_detach" or event == "peripheral" then
		sleep(0.5)
		mapPeripherals()
	end
	
	
	event, par1, par2, par3, par4, part = nil
end
