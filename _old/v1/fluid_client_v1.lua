-- DATA
ID = os.getComputerID()
sleepAmount = 0.5
input = "front"
output = "top"
protocol = "p_fluid"
separator = ";"
modem = "?"
fluidID = "-1"

 -- FUNCTIONS
 function open(side)
	rednet.close(side)
	rednet.open(side)
end

 function getID()
 	rednet.close(modem)
 	rednet.open(modem)
	rednet.broadcast(os.getComputerLabel(),"p_fluid_who")
end

function setID(id)
	fluidID = id
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

function separate(str)
    if separator == nil then
        separator = "%s"
    end
    local t={}; i = 1
    for part in string.gmatch(str, "([^"..separator.."^]+)") do
        t[i] = part
        i = i + 1
    end
    return t
end
 
function replyARP(myID,senderID,label, prot)
   open(modem)
    local msg = "ARP reply - "..myID..": ["..label.."] using protocol '"..prot.."'"
    rednet.send(senderID,msg,"p_arp_reply")
end
 
 function redraw()
 	term.clear()
	term.setCursorPos(1,1)
	print("##### LISTENING on Fluid ID: "..fluidID.." - "..os.getComputerLabel().." #####")
 end
 
 -- INIT
modem = getDeviceSide("modem")
sleep(3)

--[[local event, par1,par2,par3,par4,par5 = os.pullEvent()
while (event ~= "rednet_message" and par3 ~= "p_fluid_who_reply") do
	getID()
	event, par1,par2,par3,par4,par5 = os.pullEvent()
end
setID(par2)
]]--


 -- LOOP
while true do
	redraw()
	
	if (fluidID == "-1" or  tonumber(fluidID) == nil) then getID() end
	
    if redstone.getInput(input) == true then
        term.clear()
        term.setCursorPos(1,1)
        print("##### TERMINATED #####")
        print("______________________")
        print("Listener program terminated!")
        print("Please reset redstone signal, and restart 'startup' program!")
        break
    end
   
    open(modem)
   
    local event, par1, par2, par3, par4, par5 = os.pullEvent()
   
    -- Rednet message received
    if event == "rednet_message" then
        local senderID = par1; senderMessage = par2; senderProtocol = par3
        -- Fluid protocol
        if senderProtocol == "p_fluid_req" then
            local t = separate(senderMessage)
            if t[1] == fluidID then
                qty = t[2]
                for i = 1,qty do
                    redstone.setOutput(output,true)
                    sleep(sleepAmount)
                    redstone.setOutput(output,false)
                    sleep(sleepAmount)
                end
            end
        --ARP protocol
        elseif senderProtocol == "p_arp" then replyARP(ID,senderID,os.getComputerLabel(),protocol)
		elseif senderProtocol == "p_fluid_who_reply" then
			local t = separate(senderMessage)
			if t[1] == os.getComputerLabel() then setID(t[2]) end
        end
    end

end