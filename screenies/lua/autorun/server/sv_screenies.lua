// Serverside
if not SERVER then return end

util.AddNetworkString( "sSS" )
util.AddNetworkString( "chunkReceive" )
util.AddNetworkString( "finishedChunk" )
util.AddNetworkString( "sSSComplete" )
util.AddNetworkString( "sSSInterrupted" )

local waiting = {}
local remtbl = {}
local storedSS = {}

function registerScreeny( caller, victim )
	if !storedSS[victim:UniqueID()] then
		table.insert(waiting, { caller, victim, RealTime() } )
		storedSS[victim:UniqueID()] = { 0 }
		net.Start("sSS")
		net.Send(victim)
	else
		if storedSS[victim:UniqueID()][1] == 0 then
			table.insert(waiting, { caller, victim, RealTime() } )
			evolve:Notify(caller, evolve.colors.blue, "Waiting on current screenshot to transfer.")
		else
			evolve:Notify(caller, evolve.colors.blue, "Found screenshot from " .. math.Round((RealTime() - storedSS[victim:UniqueID()][1]), 4) .. " seconds ago.")
			for k,v in pairs(storedSS[victim:UniqueID()]) do
				if storedSS[victim:UniqueID()][k] == nil then return end
				if k != 1 then
					if IsValid(caller) then
						net.Start( "chunkReceive" )
						net.WriteTable( { v, (k - 1) } )
						net.Send( caller )
					end
				end
			end
			net.Start( "finishedChunk" )
			net.WriteString( victim:Nick() )
			net.Send( caller )
		end
	end
end

function serverRecSS(len, ply)
	local image = net.ReadTable()
	table.insert(storedSS[ply:UniqueID()], image[1])
end
net.Receive( "sSS", serverRecSS )

function serverFinishedSS(len, ply)
	if not ssValid(ply) then return end
	storedSS[ply:UniqueID()][1] = RealTime()
	
	for z, wait in pairs(waiting) do
		if waiting[z] == nil then return end
		if wait[2] == ply then
			if IsValid(wait[1]) then
				for k,v in pairs(storedSS[ply:UniqueID()]) do
					if storedSS[ply:UniqueID()][k] == nil then return end
					if k != 1 then
						net.Start( "chunkReceive" )
						net.WriteTable( { v, (k - 1) } )
						net.Send( wait[1] )
					end
				end
				net.Start( "finishedChunk" )
				net.WriteString( wait[2]:Nick() )
				net.Send( wait[1] )
				table.insert(remtbl, z)
			end
		end
	end
	remtblDo()
end
net.Receive( "sSSComplete", serverFinishedSS )

function remtblDo()
	for k,v in pairs(remtbl) do
		table.remove(waiting, v)
	end
	remtbl = {}
end

function ssValid( ply )
	for _,v in pairs(waiting) do
		if v[2] == ply then
			return true
		end
	end
	return false
end

function saveSS( vic, screenshot )
	local bleh = file.Open("hue.txt", "wb", "DATA")
	bleh:Write(screenshot)
	bleh:Close()
end

hook.Add("PlayerDisconnected", "checkwaiting", function( ply )
	for k,v in pairs(waiting) do
		if waiting[k] == nil then return end
		if v[2] == ply then
			table.insert(remtbl, k)
			if IsValid(v[1]) then
				evolve:Notify(v[1], evolve.colors.red, ply:Nick().." has disconnected, screenshot interrupted.")
				net.Start( "sSSInterrupted" )
				net.Send(v[1])
			end
		end
	end
	remtblDo()
end)

function timercheck()
	for k,v in pairs(waiting) do
		if waiting[k] == nil then return end
		if (RealTime() - v[3] ) > 10 then
			if IsValid(v[1]) and IsValid(v[2]) then
				evolve:Notify(v[1], evolve.colors.red, v[2]:Nick().." timed out sending screenshot.")
				net.Start( "sSSInterrupted" )
				net.Send(v[1])
			end
			table.insert(remtbl, k)
		end
	end
	
	remtblDo()
end
timer.Create("checkSS", 10, 0, timercheck )

function screenshotReset()
	for k,v in pairs(storedSS) do
		if v != false and v[1] != 0 then
			if (RealTime() - v[1] ) > 5 then
				storedSS[k] = false
			end
		end
	end
end
timer.Create("screenshotReset", 1, 0, screenshotReset)
