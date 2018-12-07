-- DATA
ID = os.getComputerID()
input = "front"
output = "top"
modem = "?"
sg = "?"
protocol="p_stargate"

state = "?"
sleepAmount = 18
separator = ";"


-- FUNCTIONS
function open(side)
	rednet.close(side)
	rednet.open(side)
end

function sendState()
	open(modem)
	rednet.broadcast(state,"p_stargate_state")	
end 

function setState(str)
	state = str
end

function redraw()
	term.clear()
	term.setCursorPos(1,1)
	print("##### STARGATE #####")
	print("State: "..state)
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

function dial(address,conn_name)
	setState("Connecting to "..conn_name.."...")
	sendState()
	redraw()
	
	sg.dial(address)
	sleep(sleepAmount)
	if sg.isConnected() then setState("Connected to "..conn_name..".")
	else setState("Inactive.")
	end
	
	redraw()
	sendState()
end

function disconnect()
	if sg.isConnected() then
		sg.disconnect()
	end
	setState("Inactive.")
	redraw()
	sendState()
end

function replyARP(myID,senderID,label, prot)
    open(modem)
    local msg = "ARP reply - "..myID..": ["..label.."] using protocol '"..prot.."'"
    rednet.send(senderID,msg,"p_arp_reply")
end

function separate(str)
    if separator == nil then
        separator = ";"
    end
    local t={}; i = 1
    for part in string.gmatch(str, "([^"..separator.."^]+)") do
        t[i] = part
        i = i + 1
    end
    return t
end

-- INIT
os.setComputerLabel("Stargate Client")
modem = getDeviceSide("modem")
sg = peripheral.wrap(getDeviceSide("stargate"))

disconnect()

-- LOOP
while true do
	open(modem)

	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		end
		if senderProtocol == "p_stargate_conn" then
			local t = separate(senderMessage)
			local conn_name = t[1]; address = t[2]
			dial(address,conn_name)
		end
		if senderProtocol == "p_stargate_dc" then
			disconnect()
		end
		if senderProtocol == "p_stargate_state_get" then
			sendState()
		end
	end

end