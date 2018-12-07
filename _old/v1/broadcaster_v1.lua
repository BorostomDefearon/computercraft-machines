-- DATA
ID = os.getComputerID()
wired = "right"
wireless = "left"
 
-- FUNCTIONS
function open(side)
    rednet.close(side)
    rednet.open(side)
end
 
function close(side)
    rednet.close(side)
end
 
function redraw()
    term.clear()
    term.setCursorPos(1,1)
    print("Broadcaster - Press [C] to clear screen!")
end
 
function log(id,message,protocol,toWired)
    if toWired then
            print("Wireless -> Wired broadcast:")
    else
        print ("Wired -> Wireless broadcast:")
    end
    print("   From ID: "..id)
    print("   Message: "..message)
    print("   Protocol: "..protocol)
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
 
-- INIT
term.clear()
term.setCursorPos(1,1)
os.setComputerLabel("Broadcaster")
redraw()
 
 
-- LOOP
while true do
    open(wired)
    open(wireless)
           
    local event, par1, par2, par3, par4, par5 = os.pullEvent()
    if event == "modem_message" then
        local modemSide = par1
        event, par1, par2, par3, par4, par5 = os.pullEvent()
        if event == "rednet_message" then
            local senderID = tonumber(par1); senderMessage = par2; senderProtocol = par3
            send(senderID,senderMessage,senderProtocol,modemSide)
        end
 
    elseif event == "key" then
            local keyCode = par11; beingHeld = par21
            if keyCode == keys.c then
                redraw()
            end
    end
   
end