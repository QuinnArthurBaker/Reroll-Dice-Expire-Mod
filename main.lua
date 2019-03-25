--[[ 

Copyright 2019 Zackary Baker

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-- ]]

-- Register the mod
local DiceExpire = RegisterMod("Dice Run Out",1)
local game = Game()

-- create variables used to track each item's usage
local d4_uses = 0
local d100_uses = 0
local dinf_uses = 0

-- constant used for odds calculation. This is equivalent to a 10% chance per roll.
local PERSIST_CHANCE = 0.9

--rng engine used for random values
local rng_obj = RNG()

function DiceExpire:ExpireChance(item, rng)
	--get the player and their active item
	player = game:GetPlayer(0)
	playerItem = player:GetActiveItem()
	-- create a variable to track the odds of losing the die on this roll
	cur_chance = 1
	--get the room seed to help seed the rng
	roomseed = game:GetRoom():GetSpawnSeed()

	if(playerItem==CollectibleType.COLLECTIBLE_D100)
	then
		--increment the item use count
		d100_uses = d100_uses + 1
		-- use the item use count in a loop to calculate the "roll to avoid" to keep the die, stored in cur_chance
		for i=1,d100_uses do 
			cur_chance = cur_chance*PERSIST_CHANCE
		end
	--these pieces use the same logic as the above for the d infinity and d4
	elseif(playerItem==CollectibleType.COLLECTIBLE_DINF)
	then
		dinf_uses = dinf_uses + 1
		for i=1,dinf_uses do
			cur_chance = cur_chance*PERSIST_CHANCE
		end

	else
		d4_uses = d4_uses + 1
		for i=1,d4_uses do
			cur_chance=cur_chance*PERSIST_CHANCE
		end
	end

	cur_chance = 1-cur_chance
	-- set the rng seed each roll, to "randomize" the results
	rng_obj:SetSeed(rng_obj:RandomInt(math.maxinteger)*roomseed,1)
	--generate the roll
	roll = rng_obj:RandomFloat()
	-- if the rng value rolled is less than the cur_chance generated in the loop above, remove the item and reset the item use count in case the item is found in the future
	if(roll<cur_chance)
	then
		player:RemoveCollectible(playerItem)
		if(playerItem==CollectibleType.COLLECTIBLE_D100)
		then
			d100_uses = 0
		elseif(playerItem==CollectibleType.COLLECTIBLE_DINF)
		then
			dinf_uses = 0
		else
			d4_uses = 0
		end	
	end


end

-- using the d100 with this kind of callback also calls it for the d6, d4 and d20, so we only have to call the function when the game registers a d4 use.
DiceExpire:AddCallback(ModCallbacks.MC_USE_ITEM,DiceExpire.ExpireChance,CollectibleType.COLLECTIBLE_D4)
