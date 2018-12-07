-- DATA
ID = os.getComputerID()
peripheralList = {}
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
originalTerm = term.current()
textScale = 0.5
sleepAmount = 0.5
output = "top"
protocol = "p_fluid"
fluidID = "-1"

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
  return nil;
end

function warnMissingPeripheral(name)
	clear()
    print("##### ERROR #####")
	print("Peripheral '"..name.."' missing. Please attach and press any key to continue...")
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
	local monitor = peripheralList["monitor"]
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
   open(modem)
    local msg = {}
	msg["name"] = os.getComputerLabel()
	msg["ID"] = ID
	msg["protocol"] = protocol
    rednet.send(senderID,msg,"p_arp_reply")
end

-- SPECIFIC FUNCTIONS
 function redraw()
 	term.clear()
	term.setCursorPos(1,1)
	print("##### LISTENING on Fluid ID: "..fluidID.." - "..os.getComputerLabel().." #####")
 end
 
 function getID()
 	rednet.close(modem)
 	rednet.open(modem)
	rednet.broadcast(os.getComputerLabel(),"p_fluid_who")
end

function setID(msg)
	if msg["fluidName"] == os.getComputerLabel() then fluidID = msg["fluidID"] end
	redraw()
end
 
 function sendFluid(msg)
 	local id = msg["fluidID"]; qty = msg["quantity"]
            if tostring(id) == fluidID then
                for i = 1,qty do
                    redstone.setOutput(output,true)
                    sleep(sleepAmount)
                    redstone.setOutput(output,false)
                    sleep(sleepAmount)
                end
            end
 end
 
 -- INIT
mapPeripherals()
modem = peripheralList["modem"]
sleep(3)
redraw()

 -- LOOP
while true do
	
    if (fluidID == "-1" or  tonumber(fluidID) == nil) then getID() end
    open(modem)
   
    local event, par1, par2, par3, par4, par5 = os.pullEvent()
   
    -- Rednet message received
    if event == "rednet_message" then
        local senderID = par1; senderMessage = par2; senderProtocol = par3
        -- Fluid request
        if senderProtocol == "p_fluid_req" then
            sendFluid(senderMessage)
        --ARP protocol
        elseif senderProtocol == "p_arp" then replyARP(ID,senderID,os.getComputerLabel(),protocol)
		-- Replied getID()
		elseif senderProtocol == "p_fluid_who_reply" then
			setID(senderMessage)
        end
    -- Detached peripheral
	elseif event == "peripheral_detach" or event == "peripheral" then
		sleep(0.5)
		mapPeripherals()
	end

end
