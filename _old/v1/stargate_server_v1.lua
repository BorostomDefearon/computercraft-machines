-- DATA
ID = os.getComputerID()
input = "back"
modem = "?"
protocol="p_stargate"
addresses = {
	{"Otthon","DADYAE2AA"},
	{"Sziget","AAAOAAJAA"},
	{"Varazslo var","AAABACFAA"},
	{"Hold bazis","EAAQAARAA3"},
	{"Sivatagi var","AABJABWAA"}
}
stargate_state = "Unknown"

-- FUNCTIONS
function open(side)
	rednet.close(side)
	rednet.open(side)
end

function redraw()
	term.clear()
	term.setCursorPos(1,1)
	print("##### STARGATE  SERVER #####")
	print("State: "..stargate_state)
	print("0. Exit")
	
	for i = 1,table.getn(addresses) do
		print(i..". "..addresses[i][1])
	end
	local last = table.getn(addresses)+1
	print(last..". Disconnect gate")
end

function replyARP(myID,senderID,label, prot)
	open(modem)
	local msg = "ARP reply - "..myID..": ["..label.."] using protocol '"..prot.."'"
	rednet.send(senderID,msg,"p_arp_reply")
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

function stargateOpen(conn_name,address)
	local msg = conn_name..";"..address
	send(msg,"p_stargate_conn")
end

function stargateClose()
	send("Closing Stargate.","p_stargate_dc")
end

function send(msg, protocol)
	open(modem)
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
	open(modem)
	rednet.broadcast("","p_stargate_state_get")
end

function scanMonitor()
	monitor = peripheral.wrap(getDeviceSide("monitor"))
	if monitor ~= nil then
		clear()
		term.redirect(monitor)
	end
end

-- INIT
os.setComputerLabel("Stargate Server")
modem = getDeviceSide("modem")
scanMonitor()
getState()

-- LOOP
while true do
	if redstone.getInput(input) == true then
		break
	end
	
	open(modem)
	
	redraw()
	
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Received rednet_message
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		elseif senderProtocol == "p_stargate_state" then
			stargate_state = senderMessage
			redraw()
		end
		
	-- Received key press from user

	elseif event == "key" then 
		local choose = readIO_number(">> ",table.getn(addresses)+1)
		if choose ~= 0 then
			if choose == table.getn(addresses) + 1 then
				stargateClose()
			else
				stargateOpen(addresses[choose][1],addresses[choose][2])
			end
		else 
			exit()
		end
	end

end