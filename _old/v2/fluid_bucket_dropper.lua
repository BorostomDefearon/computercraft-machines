-- CONSTANTS
TEXT_SCALE = 0.5
SLEEP_AMOUNT = 0.3

-- DATA
ID = os.getComputerID()
peripheralList = {}
requiredPeripherals = {"modem"}
optionalPeripherals = {"monitor"}
originalTerm = term.current()
protocol = "p_fluid"
output = "back"

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
	print("##### BUCKET DROPPER #####")
 end
 
 function alertClient(prot, id)
 	local msg = {}
	msg.state = on_off; msg.fluidID = id
 	open(modem)
	rednet.broadcast(msg, prot)
 end
 
 function countBuckets(msg)
 	local id = msg.fluidID; qty = msg.quantity
	alertClient("p_fluid_servo_on", id)
	print(id)
	for i = 1,qty do
		redstone.setOutput(output,true)
		sleep(SLEEP_AMOUNT)
		redstone.setOutput(output,false)
		sleep(SLEEP_AMOUNT)
	end
	sleep(1)
	alertClient("p_fluid_servo_off", id)
	
 end
 
 
 -- INIT
mapPeripherals()
modem = peripheralList.modem
open(modem)
os.setComputerLabel("Bucket Dropper")

 -- LOOP
while true do
   
    local event, par1, par2, par3, par4, par5 = os.pullEvent()
   
    -- Rednet message received
    if event == "rednet_message" then
        local senderID = par1; senderMessage = par2; senderProtocol = par3
        -- Fluid request
        if senderProtocol == "p_fluid_req" then
            countBuckets(senderMessage)
        --ARP protocol
        elseif senderProtocol == "p_arp" then replyARP(ID,senderID,os.getComputerLabel(),protocol)

		elseif senderProtocol == "p_fluid_reboot" then
			os.reboot()
		-- Reboot all machines
		elseif senderProtocol == "p_public_reboot" then
			os.reboot()
        end
    -- Detached peripheral
	elseif event == "peripheral_detach" or event == "peripheral" then
		sleep(0.5)
		mapPeripherals()
	end

end
