-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 0.5
TIMER_CYCLE = 15

-- DATA
ID = os.getComputerID()
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
peripheralList = {}
originalTerm = term.current()
protocol = "p_fluid"
timer = nil
fluids = {
	{fluidID="1",		name="Water",			amount="",	capacity=""},
	{fluidID="2",		name="Lava",				amount="",	capacity=""},
	{fluidID="3",		name="Oil",					amount="",	capacity=""},
	{fluidID="4",		name="Redstone",		amount="",	capacity=""},
	{fluidID="5",		name="Etherium",		amount="",	capacity=""},
	{fluidID="6",		name="Enderium",		amount="",	capacity=""},
	{fluidID="7",		name="Milk",				amount="",	capacity=""},
	{fluidID="8",		name="Glowstone",	amount="",	capacity=""},
	{fluidID="9",		name="Kerosene",		amount="",	capacity=""},
	{fluidID="10",		name="LPG",					amount="",	capacity=""},
	{fluidID="11",	name="Diesel",				amount="",	capacity=""},
	{fluidID="12",	name="Fuel",				amount="",	capacity=""},
	{fluidID="13",	name="Lubricant",		amount="",	capacity=""},
	{fluidID="14",	name="Plastic",			amount="",	capacity=""},
	{fluidID="15",	name="XP",					amount="",	capacity=""},
	{fluidID="16",	name="Cryotheum",					amount="",	capacity=""},
	{fluidID="17",	name="Aerotheum",					amount="",	capacity=""}
}

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
	term.setCursorPos(1,1)
	term.clear()
	print("##### FLUID SERVER #####")
	print("0.  Exit")
	for i=1,table.getn(fluids) do
		if (i < 10) then
			print(i..".  "..fluids[i].name.." ["..fluids[i].amount.."/"..fluids[i].capacity.."]")
		else
			print(i..". "..fluids[i].name.." ["..fluids[i].amount.."/"..fluids[i].capacity.."]")
		end
	end
end

function exit()
			clear()
			shell.run("startup")
end

function sendArray()
	local msg = {}
	msg.array = fluids
	rednet.broadcast(msg, "p_fluid_array")
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

function send(fluidID,qty)
	local msg = {}
	msg.fluidID = fluidID; msg.quantity = qty
	rednet.broadcast(msg, "p_fluid_req")
	
	clear()
	print("Trying to send "..qty.." buckets of "..fluids[fluidID].name..".")
	sleep(qty + qty/2)
	redraw()
end

function getInfo()
	rednet.broadcast("Getting tank info...","p_fluid_info")
end

function setInfo(msg)
	local fluidID = msg.fluidID; capacity = msg.capacity; amount = msg.amount
	for i=1,table.getn(fluids) do
		if fluids[i].fluidID == fluidID then
			fluids[i].amount = tonumber(amount)/1000
			fluids[i].capacity = tonumber(capacity)/1000
		end
	end
	redraw()
end

function rebootClients()
	rednet.broadcast("Rebooting clients...","p_fluid_reboot")
end

-- INIT
os.setComputerLabel("Fluid Server")
mapPeripherals()
modem = peripheralList.modem
open(modem)
sendArray()
timer = os.startTimer(TIMER_CYCLE)

-- LOOP
while true do
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Received rednet_message
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		-- ARP protocol
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		-- Fluid ID request
		elseif senderProtocol == "p_fluid_array_get" then
			sendArray()
		-- Tank information replied by client
		elseif senderProtocol == "p_fluid_info_reply" then
			setInfo(senderMessage)
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
		end
	-- Timer event
	elseif (event == "timer" and par1 == timer) then
		getInfo()
		timer = os.startTimer(TIMER_CYCLE)
	-- Received key press from user
	elseif event == "key" then 
		local choose = readIO_number(">> ",table.getn(fluids))
		if choose ~= 0 then
			local qty = readIO_number(">> Number of buckets: ",10)
			if qty ~= 0 then
				local fluidID = tonumber(fluids[choose].fluidID)
				send(fluidID,qty)
			else redraw()
			end
		else
			exit()
		end
	-- Peripheral
	elseif event == "peripheral_detach" or event == "peripheral"  then
		sleep(0.5)
		mapPeripherals()
	end

end

