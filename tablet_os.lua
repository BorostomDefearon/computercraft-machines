-- DATA
ID = os.getComputerID()
apps = {
	{name = "Fluid Server",			file = "fluid_server",pasteID = "yYqTHNdh"},
	{name = "Stargate Server", 	file = "sg_server",		pasteID = "UZs9sJqD"},
	{name = "Energy Server", 	file = "energy_server",		pasteID = "QXDArL3u"}
}
modem = "?"
owner = ""
protocol = "p_tablet"

-- FUNCTIONS
function open(side)
	rednet.close(side)
	rednet.open(side)
end

function setOwner()
	term.clear()
	term.setCursorPos(1,1)
	if (fs.exists("_owner")) then
		local f = fs.open("_owner", "r")
		owner = f.readLine()
		f.close()
	else
		local f = fs.open("_owner","w")
		print("Welcome to Tablet OS!")
		io.write("Who are You? >> ")
		owner = io.read()
		while (owner == nil or owner == "" or string.len(owner) < 3 or string.len(owner)>10) do
			term.clear()
			term.setCursorPos(1,1)
			print("Name cannot be empty,")
			print("shorter than 3, or")
			print("longer than 10 characters.")
			io.write("Who are You? >> ")
			owner = io.read()
		end
		f.write(owner)
		f.close()
	end
	
end

function runApp(i)
	shell.run("rm",apps[i].file)
	shell.run("pastebin","get",apps[i].pasteID,apps[i].file)
	shell.run(apps[i].file)
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

function redraw()
	term.clear()
	term.setCursorPos(1,1)
	print("## "..owner.."'s Tablet ##")
	print("")
	for i = 1,table.getn(apps) do
		print(i..". "..apps[i].name)
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

function replyARP(myID,senderID,label, prot)
   open(modem)
    local msg = {}
	msg.name = os.getComputerLabel()
	msg.ID = ID
	msg.protocol = protocol
    rednet.send(senderID,msg,"p_arp_reply")
end

-- INIT
modem = getDeviceSide("modem")
setOwner()
os.setComputerLabel(owner.."'s Tablet")

-- LOOP
while true do
	open(modem)
	
	redraw()
	
	local event, par1, par2, par3, par4, par5 = os.pullEvent()
	
	-- Received key press from user
	if event == "rednet_message" then
		local senderID = par1; senderMessage = par2; senderProtocol = par3
		if senderProtocol == "p_arp" then
			replyARP(ID,senderID,os.getComputerLabel(),protocol)
		end
	elseif event == "key" then
		local choose = readIO_number(">> ",table.getn(apps))
		if choose ~= 0 then
			runApp(choose)
		else redraw()
		end
	end
	
	event, par1, par2, par3, par4, part = nil
end

