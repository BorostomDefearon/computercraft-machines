-- DATA
ID = os.getComputerID()
input = "back"
protocol = "p_fluid"
modem = "?"
monitor = nil
fluids = {
	{"Water","1"},
	{"Lava","2"},
	{"Oil","3"},
	{"Redstone","4"},
	{"Etherium","5"},
	{"Enderium","6"},
	{"Milk","7"},
	{"Glowstone","8"},
	{"Kerosene","9"},
	{"LPG","10"},
	{"Diesel","11"},
	{"Fuel","12"},
	{"Lubricant","13"},
	{"Plastic","14"},
	{"XP","15"}
}

-- FUNCTIONS
function open(side)
	rednet.close(side)
	rednet.open(side)
end

function sendWho(fluidName)
	rednet.close(modem)
	rednet.open(modem)
	local fluidID = ""
	for i=1,table.getn(fluids) do
		if fluids[i][1] == fluidName then
			fluidID = fluids[i][2]
		end
	end
	local msg = fluidName..";"..fluidID
	rednet.broadcast(msg, "p_fluid_who_reply")
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
  return "No "..deviceType.." present.";
end

function exit()
			term.clear()
			term.setCursorPos(1,1)
			shell.run("startup")
end

function clear()
		term.clear()
		term.setCursorPos(1,1)
end

function redraw()
	term.setCursorPos(1,1)
	term.clear()
	print("##### FLUID SERVER #####")
	print("0. Exit")
	for i = 1,table.getn(fluids) do
		print(i..". "..fluids[i][1])
	end
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
	open(modem)
	local msg = fluidID..";"..qty
	rednet.broadcast(msg, "p_fluid_req")
	
	clear()
	print("Trying to send "..qty.." buckets of "..fluids[fluidID][1]..".")
	sleep(qty + qty/2)
	redraw()
end

function replyARP(myID,senderID,label, prot)
	open(modem)
	local msg = "ARP reply - "..myID..": ["..label.."] using protocol '"..prot.."'"
	rednet.send(senderID,msg,"p_arp_reply")
end

function scanMonitor()
	monitor = peripheral.wrap(getDeviceSide("monitor"))
	if monitor ~= nil then
		clear()
		term.redirect(monitor)
	end
end

-- INIT
os.setComputerLabel("Fluid Server")
modem = getDeviceSide("modem")
scanMonitor()
redraw()

-- LOOP
while true do
	if redstone.getInput(input) == true then
		break
	end
	
	open(modem)
	
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Received rednet_message
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		end
		if senderProtocol == "p_fluid_who" then
			sendWho(senderMessage)
		end
	-- Received key press from user
	elseif event == "key" then 
		local choose = readIO_number(">> ",table.getn(fluids))
		if choose ~= 0 then
			local qty = readIO_number(">> Number of buckets: ",10)
			if qty ~= 0 then
				local fluidID = tonumber(fluids[choose][2])
				send(fluidID,qty)
			else redraw()
			end
		else
			exit()
		end
	-- etc..
	end

end