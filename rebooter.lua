-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 0.5

-- DATA
ID = os.getComputerID()
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
peripheralList = {}
originalTerm = term.current()
protocol = "p_public_reboot"

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
   open(modem)
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
	print("##### REBOOTER #####")
	print("Give me redstone signal to reboot machines on the network.")
 end
 
function sendReboot()
	open(modem)
	rednet.broadcast("Rebooting ya all!","p_public_reboot")
end

-- INIT
os.setComputerLabel("Rebooter")
mapPeripherals()
modem = peripheralList.modem
redraw()

-- LOOP
while true do
	open(modem)
	event, par1, par2, par3, par4, par5 = os.pullEvent()
	
	   -- Rednet message received
    if event == "rednet_message" then
        local senderID = par1; senderMessage = par2; senderProtocol = par3
		-- ARP msg
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		end
	elseif (event == "redstone" and par1 == timer) then
		sendReboot()
	elseif event == "peripheral_detach" or event == "peripheral"  then
		sleep(0.5)
		mapPeripherals()
	end

end