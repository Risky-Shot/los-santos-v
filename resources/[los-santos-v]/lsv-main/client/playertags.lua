local _gamerTags = { }

local function isPlayerCrewMemberAimingAt(ped)
	for member, _ in pairs(Player.CrewMembers) do
		if IsPlayerFreeAimingAtEntity(GetPlayerFromServerId(member), ped) then
			return true
		end
	end

	return false
end

AddEventHandler('lsv:init', function()
	while true do
		local playerPed = PlayerPedId()

		local players = GetActivePlayers()
		for _, id in ipairs(players) do
			Citizen.Wait(0)

			if id ~= PlayerId() and NetworkIsPlayerActive(id) then
				local ped = GetPlayerPed(id)

				local serverId = GetPlayerServerId(id)
				local playerData = PlayerData.Get(serverId)
				local isPlayerActive = playerData ~= nil

				local isPlayerDead = false
				local isPlayerCrewMember = false
				local isPlayerCrewLeader = false
				local isPlayerEnemyCrewMember = false
				local isPlayerEnemyCrewLeader = false
				local isPlayerBeast = false
				local isPlayerHotProperty = false
				local isPlayerKingOfTheCastle = false
				local isPlayerHasBounty = false
				local isPlayerOnMission = false
				local isHealthBarVisible = false
				local isPlayerTalking = false
				local isPlayerInPlane = false
				local isPlayerInHeli = false
				local patreonTier = 0

				local playerWeapon = 0

				local gamerTag = _gamerTags[id]

				if isPlayerActive then
					isPlayerDead = IsPlayerDead(id)
					isPlayerCrewMember = Player.CrewMembers[serverId]

					if Player.CrewLeader then
						if isPlayerCrewMember then
							isPlayerCrewLeader = serverId == Player.CrewLeader
						else
							local leader = playerData.crewLeader
							if leader then
								isPlayerEnemyCrewMember = leader ~= Player.CrewLeader
								if isPlayerEnemyCrewMember then
									isPlayerEnemyCrewLeader = leader == serverId
								end
							end
						end
					end

					isPlayerBeast = serverId == World.BeastPlayer
					isPlayerHotProperty = serverId == World.HotPropertyPlayer
					isPlayerKingOfTheCastle = serverId == World.KingOfTheCastlePlayer
					isPlayerHasBounty = playerData.killstreak >= Settings.bounty.killstreak
					isPlayerOnMission = MissionManager.IsPlayerOnMission(serverId)
					isHealthBarVisible = not isPlayerDead and (IsPlayerFreeAimingAtEntity(PlayerId(), ped) or isPlayerCrewMember or isPlayerCrewMemberAimingAt(ped))
					isPlayerTalking = NetworkIsPlayerTalking(id)
					isPlayerInPlane = IsPedInAnyPlane(ped)
					if not isPlayerInPlane then
						isPlayerInHeli = IsPedInAnyHeli(ped)
					end
					patreonTier = playerData.patreonTier

					playerWeapon = GetSelectedPedWeapon(ped)
				end

				if not gamerTag or gamerTag.ped ~= ped or not IsMpGamerTagActive(gamerTag.tag) then
					if gamerTag then
						RemoveMpGamerTag(gamerTag.tag)
					end

					gamerTag = {
						tag = CreateMpGamerTag(ped, '', false, false, '', 0),
						ped = ped,
					}

					local tag = gamerTag.tag
					SetMpGamerTagAlpha(tag, 0, 255)
					SetMpGamerTagAlpha(tag, 2, 255)
					SetMpGamerTagAlpha(tag, 4, 255)
					SetMpGamerTagAlpha(tag, 7, 255)

					_gamerTags[id] = gamerTag
				end

				local tag = gamerTag.tag

				local color = 0
				if isPlayerCrewMember then
					color = 10
				elseif isPlayerHotProperty or isPlayerBeast or isPlayerKingOfTheCastle or isPlayerHasBounty or isPlayerOnMission then
					color = 6
				elseif isPlayerEnemyCrewMember then
					color = 7
				elseif patreonTier ~= 0 then
					color = 15
				end

				-- https://runtime.fivem.net/doc/reference.html#_0x63BB75ABEDC1F6A0
				SetMpGamerTagName(tag, GetPlayerName(id))

				SetMpGamerTagColour(tag, 0, color)
				SetMpGamerTagColour(tag, 2, 0)
				SetMpGamerTagColour(tag, 4, color)
				SetMpGamerTagColour(tag, 7, color)
				SetMpGamerTagHealthBarColour(tag, 0)

				local isGamerTagVisible = isHealthBarVisible or HasEntityClearLosToEntity(playerPed, ped, 17)

				SetMpGamerTagVisibility(tag, 0, isGamerTagVisible) -- GAMER_NAME
				SetMpGamerTagVisibility(tag, 2, isHealthBarVisible) -- HEALTH/ARMOR
				SetMpGamerTagVisibility(tag, 4, isGamerTagVisible and isPlayerTalking) -- AUDIO_ICON
				SetMpGamerTagVisibility(tag, 7, isGamerTagVisible and patreonTier ~= 0) -- WANTED_STARS

				if ped ~= 0 then
					local blip = GetBlipFromEntity(ped)
					if not DoesBlipExist(blip) then
						blip = AddBlipForEntity(ped)
						SetBlipHighDetail(blip, true)
						ShowHeadingIndicatorOnBlip(blip, true)
					end

					local blipSprite = Blip.STANDARD
					if isPlayerDead then
						blipSprite = Blip.PLAYER_DEAD
					else
						if isPlayerHotProperty then blipSprite = Blip.HOT_PROPERTY
						elseif isPlayerKingOfTheCastle then blipSprite = Blip.CASTLE_KING
						elseif isPlayerBeast then blipSprite = Blip.BEAST
						elseif isPlayerOnMission then blipSprite = Blip.PLAYER_ON_MISSION
						elseif isPlayerHasBounty then blipSprite = Blip.BOUNTY_HIT
						elseif isPlayerInPlane then blipSprite = Blip.PLANE
						elseif isPlayerInHeli then blipSprite = Blip.HELI
						elseif isPlayerCrewLeader or isPlayerEnemyCrewLeader then blipSprite = Blip.CREW_LEADER
						end
					end
					if GetBlipSprite(blip) ~= blipSprite then
						SetBlipSprite(blip, blipSprite)
					end

					-- local rotation = 0.0
					-- if isPlayerInPlane or isPlayerInHeli then
					-- 	rotation = GetEntityHeading(ped)
					-- end
					-- SetBlipSquaredRotation(blip, rotation)

					local scale = 0.7
					if isPlayerHotProperty or isPlayerKingOfTheCastle or isPlayerOnMission or isPlayerBeast or isPlayerHasBounty then
						scale = 0.9
					elseif isPlayerInPlane or isPlayerInHeli then
						scale = 0.9
					end
					SetBlipScale(blip, scale)

					local blipColor = Color.BLIP_WHITE
					if isPlayerCrewMember then
						blipColor = Color.BLIP_BLUE
					elseif isPlayerHotProperty or isPlayerKingOfTheCastle or isPlayerBeast or isPlayerHasBounty or isPlayerOnMission then
						blipColor = Color.BLIP_RED
					elseif isPlayerEnemyCrewMember then
						blipColor = Color.BLIP_LIGHT_RED
					end
					SetBlipColour(blip, blipColor)

					local blipAlpha = isPlayerActive and 255 or 0
					if not isPlayerCrewMember then
						if not isPlayerHotProperty and not isPlayerBeast and not isPlayerKingOfTheCastle and not isPlayerHasBounty and not isPlayerOnMission and GetWeapontypeGroup(playerWeapon) ~= -1212426201 then
							if GetPedStealthMovement(ped) or GetPlayerInvincible(id) then
								blipAlpha = 0
							end
						end
					end
					if GetBlipAlpha(blip) ~= blipAlpha then
						SetBlipAlpha(blip, blipAlpha)
					end

					ShowCrewIndicatorOnBlip(blip, isPlayerCrewMember)

					SetBlipNameToPlayerName(blip, id)
				end
			elseif gamerTag then
				RemoveMpGamerTag(gamerTag.tag)
				_gamerTags[id] = nil
			end
		end

		Citizen.Wait(10)
	end
end)
