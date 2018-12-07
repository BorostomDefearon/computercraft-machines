-- DATA
ID = os.getComputerID()
wired = "left"
wireless = "right"
forbidden_ids = {}
protocol = "p_wl2wd"

-- FUNCTIONS
local function has_value (tab, val)
    for i=1,table.getn(forbidden_ids) do
        if forbidden_ids[i] == val then
            return true
        end
    end
    return false
end

function redraw()
	term.clear()
	term.setCursorPos(1,1)
	print("WL2WD Broadcaster - Press [C] to clear screen!")
end

function log(id,message,protocol)
		print("Message broadcasted:")
		print("   Sender: "..id)
		print("   Message: "..message)
		print("   Protocol: "..protocol)
		print("")
end

function send(id, message, protocol)
		rednet.close(wireless)
		
		rednet.close(wired)
		rednet.open(wired)

		rednet.broadcast(message, protocol)		
		rednet.close(wired)
end

-- INIT
rednet.host(protocol,"WD2WL Broadcaster")

term.clear()
term.setCursorPos(1,1)
os.setComputerLabel("WL2WD Broadcaster")
redraw()


-- LOOP
while true do
if table.getn(forbidden_ids) == 0 then
		forbidden_ids = {rednet.lookup("p_wd2wl")}
		print(forbidden_ids[1])
		print(forbidden_ids[2])
	end
	
	-- listening on wireless modem
	rednet.close(wireless)
	rednet.open(wireless)
	
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	
	if event == "rednet_message" then
	
		local senderID = tonumber(par1); senderMessage = par2; senderProtocol = par3
		if not has_value(forbidden_ids,senderID) then
			send(senderID,senderMessage,senderProtocol)
			log(senderID,senderMessage,senderProtocol)
		end
		
	elseif event == "key" then
		local keyCode = par1; beingHeld = par2
		if keyCode == keys.c then
			redraw()
		end
	end
	
	event, par1, par2, par3, par4, part = nil
end