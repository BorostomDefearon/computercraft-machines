-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 18
TIMER_CYCLE = 60

-- DATA
ID = os.getComputerID()
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
peripheralList = {}
originalTerm = term.current()
textScale = 0.5
timer = nil
protocol="p_stargate"
addresses = {
	{name = "Otthon",			address = "DADYAE2AA"},
	{name = "Sziget",				address = "AAAOAAJAA"},
	{name = "Varazslo var",	address = "AAABACFAA"},
	{name = "Hold bazis",		address = "EAAQAARA3"},
	{name = "Sivatagi var",	address = "AABJABWAA"},
	{name = "Expedicio",		address = "DAT-AHGAA"}
}
stargate_state = "Unknown"

-- FUNCTIONS
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
	print("##### STARGATE  SERVER #####")
	print("State: "..stargate_state)
	print("0. Exit")
	
	for i = 1,table.getn(addresses) do
		print(i..". "..addresses[i].name)
	end
	local last = table.getn(addresses)+1
	print(last..". Disconnect gate")
end

function exit()
			term.clear()
			term.setCursorPos(1,1)
			shell.run("startup")
end

function stargateOpen(conn_name,address)
	local msg = {}
	msg.conn_name = conn_name; msg.address = address
	send(msg,"p_stargate_conn")
end

function stargateClose()
	send("Closing Stargate.","p_stargate_dc")
end

function send(msg, protocol)
	rednet.broadcast(msg,protocol)
end

function readIO_number(line, maxvalue)
	io.write(line)
	local num = io.read()
	maxvalue = tonumber(maxvalue)
	while tonumber(num) == nil or tonumber(num) > maxvalue or tonumber(num) < 0 do
		redraw()
		print("\nInvalid input!")
		io.write(line)
		num = io.read()
	end
	return tonumber(num)
end

function getState()
	rednet.broadcast("","p_stargate_state_get")
end

-- INIT
os.setComputerLabel("Stargate Server")
mapPeripherals()
modem = peripheralList.modem
open(modem)
getState()
timer = os.startTimer(TIMER_CYCLE)

-- LOOP
while true do
	
	redraw()
	
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Received rednet_message
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		-- ARP protocol
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		-- Stargate client sent it's state
		elseif senderProtocol == "p_stargate_state" then
			stargate_state = senderMessage
			redraw()
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
		end
	-- Timer event
	elseif (event == "timer" and par1 == timer) then
		getState()
		timer = os.startTimer(TIMER_CYCLE)	
	-- Received key press from user
	elseif event == "key" then 
		local choose = readIO_number(">> ",table.getn(addresses)+1)
		if choose ~= 0 then
			if choose == table.getn(addresses) + 1 then
				stargateClose()
			else
				stargateOpen(addresses[choose].name,addresses[choose].address)
			end
		else 
			exit()
		end
	
	-- Peripheral
	elseif event == "peripheral_detach" or event == "peripheral" then
		sleep(0.5)
		mapPeripherals()
	end

end
