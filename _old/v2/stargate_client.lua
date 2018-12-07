-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 18
TIMER_CYCLE = 10

-- DATA
ID = os.getComputerID()
requiredPeripherals = {"modem","stargate"}
optionalPeripherals = {"monitor"}
peripheralList = {}
originalTerm = term.current()
protocol="p_stargate"
state = "?"

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
	term.clear()
	term.setCursorPos(1,1)
	print("##### STARGATE #####")
	print("State: "..state)
end

function sendState()
	rednet.broadcast(state,"p_stargate_state")	
end 

function setState(str)
	state = str
end

function dial(address,conn_name,sg)
	setState("Connecting to "..conn_name.."...")
	sendState()
	redraw()
	
	sg.dial(address)
	sleep(SLEEP_AMOUNT)
	if sg.isConnected() then setState("Connected to "..conn_name..".")
	else setState("Inactive.")
	end
	
	redraw()
	sendState()
end

function disconnect(sg)
	if sg.isConnected() then
		sg.disconnect()
	end
	setState("Inactive.")
	redraw()
	sendState()
end

-- INIT
os.setComputerLabel("Stargate Client")
mapPeripherals()
modem = peripheralList.modem
open(modem)
sg = peripheral.wrap(peripheralList.stargate)
disconnect(sg)

-- LOOP
while true do
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Receive rednet message
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		-- ARP protocol
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		end
		-- Received connect commant
		if senderProtocol == "p_stargate_conn" then
			local address = senderMessage.address; conn_name = senderMessage.conn_name
			dial(address,conn_name,sg)
		end
		-- Received disconnect command
		if senderProtocol == "p_stargate_dc" then
			disconnect(sg)
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
		end
		-- Request for sending state
		if senderProtocol == "p_stargate_state_get" then
			sendState()
		end
	elseif event == "peripheral_detatch" or event == "peripheral" then
		sleep(0.5)
		mapPeripherals()
	end

end
