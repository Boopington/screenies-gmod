// Clientside
if not CLIENT then return end
local bleigh
local temptime = RealTime( )
local tmptbl = {}
local rc = render.Capture
local nStart = net.Start
local nTbl = net.WriteTable
local nSts = net.SendToServer

function doScreenshot( len )
	if ( RealTime() - temptime ) > 3 then
		bleigh = rc( { format = "jpeg", x = 0, y = 0, w = ScrW(), h = ScrH(), quality = 20 } )
		bleigh = util.Base64Encode(bleigh)
	end
	
	local block = 60000
	local i = 0
	
	if bleigh != nil then
		while (true) do
			local tmp = string.sub(bleigh, (i * block + 1), ((i+1)*block) )
			if tmp == "" then
				break
			else
				table.insert(tmptbl, tmp)
				i = i + 1
			end
		end
		
		//MsgN("Screenshot being sent in "..#tmptbl.." parts.")
		for k, v in pairs(tmptbl) do
			nStart("sSS")
			nTbl( { v, k } )
			nSts()
		end
		
		nStart("sSSComplete")
		nSts()
		
		tmptbl = {}
	end
end
net.Receive( "sSS", doScreenshot )

local screenshot = {}
local total = 0

function recSS( len )
	local tmp = net.ReadTable()
	if tmp != nil then
		screenshot[tmp[2]] = tmp[1]
		total = total + 1
	end
end
net.Receive( "chunkReceive", recSS )

function callDerma( len )
	local blarg = net.ReadString()
	local ss = table.concat(screenshot)
	showSS(blarg, total, ss)
	total = 0
	screenshot = {}
end
net.Receive( "finishedChunk", callDerma)

function ssInterrupt( len )
	total = 0
	screenshot = {}
end
net.Receive( "sSSInterrupted", ssInterrupt )

function showSS(name, frames, ss)
	local html = [[ 
	<html><body> 
	<img src="data:image/jpeg;base64, ]] .. ss .. [[" />
	</body></html>
	]]
	
	ssDisplay = vgui.Create('DFrame')
	ssDisplay:SetSize(ScrW() * 0.95, ScrH() * 0.899)
	ssDisplay:Center()
	ssDisplay:SetTitle( "Screenshot from "..name.." received in "..frames.." messages" )
	ssDisplay:SetSizable(false)
	ssDisplay:ShowCloseButton(true)
	ssDisplay:MakePopup()
		
	ssHtml = vgui.Create('HTML')
	ssHtml:SetParent(ssDisplay)
	ssHtml:SetSize(ScrW() * 0.929, ScrH() * 0.84)
	ssHtml:SetPos(ScrW() * 0.01, ScrH() * 0.04)
	ssHtml:SetHTML( html )
end

