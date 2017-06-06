local PLUGIN = {}
PLUGIN.Title = "Screenshot"
PLUGIN.Description = "Take a screenshot."
PLUGIN.Author = "Boopington"
PLUGIN.ChatCommand = "screenshot"
PLUGIN.Usage = "[players]"
PLUGIN.Privileges = { "Screenshot" }

function PLUGIN:Call( ply, args )
	if ( ply:EV_HasPrivilege( "Screenshot" ) ) then
		local players = evolve:FindPlayer( args, ply, nil, true )
		
		if #players > 1 then
			evolve:Notify( ply, evolve.colors.red, "More than one player found with that name." )
		elseif #players == 0 then
			evolve:Notify( ply, evolve.colors.red, "No players found with that name." )
		elseif #players == 1 then
			for k,v in pairs(player.GetAll()) do
				if v:IsAdmin() then
					evolve:Notify(v, evolve.colors.red, "(Admins) ", evolve.colors.blue, ply:Nick(), evolve.colors.white, " requested a screenshot from ", evolve.colors.blue, players[1]:Nick(), evolve.colors.white, ".")
				end
			end
			registerScreeny( ply, players[1] )
		end		
	else
		evolve:Notify( ply, evolve.colors.red, evolve.constants.notallowed )
	end
end

function PLUGIN:Menu( arg, players )
	if ( arg ) then
		RunConsoleCommand( "ev", "screenshot", unpack( players ) )
	else
		return "Screenshot", evolve.category.punishment
	end
end

evolve:RegisterPlugin( PLUGIN )