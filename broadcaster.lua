-- DATA
ID = os.getComputerID()
wired = "top"
wireless = "left"
forbiddenProtocols = {"p_arp"}

-- COMMON FUNCTIONS
function open(side)
	rednet.close(side)
	rednet.open(side)
end

function clear()
	term.clear()
	term.setCursorPos(1,1)
end

-- SPECIFIC FUNCTIONS
function redraw()
    clear()
    print("Broadcaster - Press [C] to clear screen!")
end

function close(side)
	rednet.close(side)
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function log(id,message,protocol,toWired)
	if toWired then
    		print("Wireless -> Wired broadcast:")
	else
		print ("Wired -> Wireless broadcast:")
	end
	print("   From ID: "..id)
    print("   With protocol: "..protocol)
    print("")
end
 
function send(id,message, protocol,receivedSide)
	if receivedSide == wired then
		close(wired)
		open(wireless)
		rednet.broadcast(message,protocol)
		log(id,senderMessage,senderProtocol,false)
	elseif receivedSide == wireless then
		close(wireless)
		open(wired)
		rednet.broadcast(message,protocol)
		log(id,senderMessage,senderProtocol,true)
	end
	
end 
 
 function warnMissingModem()
    clear()
 	print("##### ERROR #####")
	print("One or two modems are missing.")
	print("")
	print("I need the wired modem to be on "..wired.." side,")
	print("and the wireless modem to be on "..wireless.." side.")
	local event,side = os.pullEvent("peripheral")
	while (peripheral.getType(wired) ~= "modem" and peripheral.getType(wireless) ~= "modem") do
		local event,side = os.pullEvent("peripheral")
	end
	redraw()
 end
-- INIT
os.setComputerLabel("Broadcaster")
redraw()
if (peripheral.getType(wired) ~= "modem" or peripheral.getType(wireless) ~= "modem") then
	warnMissingModem()
end

-- LOOP
while true do
	open(wired)
	open(wireless)
    		
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	-- Received some modem message
	if event == "modem_message" then
		local modemSide = par1
		event, par1, par2, par3, par4, par5 = os.pullEvent()
		-- It was a rednet message
		if event == "rednet_message" then
			local senderID = tonumber(par1); senderMessage = par2; senderProtocol = par3
			if not has_value(forbiddenProtocols, senderProtocol) then
				send(senderID,senderMessage,senderProtocol,modemSide)
			end
		end
	 -- User pressed a key
	elseif event == "key" then
    		local keyCode = par1; beingHeld = par2
    	 	if keyCode == keys.c then
        		redraw()
    		end
	-- Detached peripheral
	elseif event == "peripheral_detach" then
		warnMissingModem()
	end
	
end