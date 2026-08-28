pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	init_deck={}
	
	grabbed_card = nil

    max_column = 8
    max_row = 12
	
	state = {
		hover = 1,
		move = 2,
	}
	
    card_space = {
        filled = 1,
        empty = 2,
    }

	tables = {
		deck = 1,
		slots = 2,
		foundations = 3,
		dragons = 4
	}

    card_type = {
        empty = 74,
        num = {
            black = 1,
            red = 3,
            green = 5
        },
        dragon = {
            black = 9,
            red = 11,
            green = 13
        },
        flower = 7
    }

    local dragons = {
        {sprite = 11, col = 8},
        {sprite = 9,  col = 1},
        {sprite = 13, col = 3},
    }

    local suits = {
        {sprite = 1, col = 1},
        {sprite = 3, col = 8},
        {sprite = 5, col = 3}
    }

	-- add numbers
	for suit in all(suits) do
        for num = 1, 9 do
            local card = {
                val = num,
                type = suit.sprite,
                col = suit.col,
            }

            add(init_deck, card)
        end
    end
	-- add dragons
	for dragon in all (dragons) do
		for num=1,4 do
			local card = {
				val = "dragon",
				type = dragon.sprite,
				col = dragon.col,
			}
			add(init_deck,card)
		end
	end
	-- add flower
	local card = {
				val = "flower",
				type = 7,
				col = 8,
			}
	add(init_deck, card)
	
	deck = randomise_deck(init_deck)
	layout_deck(deck)
	
	-- create table for top slots
	card_slots = {}
	local card_spacing = 3
	local card_slot_height = 4
	local card_deck_height = 32
	local card_width = 14
	
	for i=1,3 do
		slot = {
			sprite=64,
			type=card_type.empty,
			x=card_spacing,
			y=card_slot_height,
			w=2,
			h=3,
		}
		add(card_slots,slot)
		card_spacing += card_width+1
	end
	
	-- create table for dragon buttons
	dragon_buttons = {}
	dragon_sprites = {66,82,98}
	card_spacing += 2
	
	for i=1,#dragon_sprites do
		dragon = {
			sprite=dragon_sprites[i],
			x=card_spacing,
			y=card_slot_height,
			w=1,
			h=1,
		}
		add(dragon_buttons,dragon)
		card_slot_height += 8
	end
	
	card_slot_height = 4
	
	-- create object for flower slot
	card_spacing += 10
	flower_slot = {
		sprite=67,
		x=card_spacing,
		y=card_slot_height,
		w=2,
		h=3,
	}
	
	-- create table for foundation slots
	card_spacing += card_width+4
	foundation_slots = {}
		for i=1,3 do
			slot = {
				sprite=69,
				x=card_spacing,
				y=card_slot_height,
				w=2,
				h=3,
			}
			add(foundation_slots,slot)
			card_spacing += card_width+1
		end
		
		sel={}
		init_selection()
		
		t = 0 -- animation tick counter
		f = 1 -- frame index
		s = 16 -- frame speed
end

function _update()
	-- animate idle cursor
	if sel.state == state.hover then
		t += 1
		
		if t%s == 0 then
			-- true/false flip
			f = not f
			if f then
				sel.y -= 1
			else
				sel.y = og_y
			end
		end
	end
	
	-- x to toggle move/hover
	if btnp(❎) then
		if sel.state == state.hover then 
			sel.state = state.move
		elseif sel.state == state.move then 
			sel.state = state.hover
		end
		set_grabbed_card()
	end
	
	if sel.state == state.hover then
	sel.sprite = 71
	elseif sel.state == state.move then
	sel.sprite = 87
	end
	
	-- move cursor
	-- left
	if btnp(⬅️) then 
		local new_i = sel.idx-1
		if sel.table == tables.deck and (sel.idx-1)%max_column ~= 0 then
			if sel.state == state.hover then
				update_sel(new_i,tables.deck)
			elseif sel.state == state.move then
				-- new_i needs to be last row in current column
				local last_row = find_last_row_in_column(new_i)
				update_sel(last_row,tables.deck)
			end
		elseif sel.table == tables.slots and sel.idx>1 then
			update_sel(new_i,tables.slots)
		end
	end
	-- right
	if btnp(➡️) then 
		local new_i = sel.idx+1
		if sel.table == tables.deck and (new_i)%max_column ~= 1 then
			if sel.state == state.hover then
				update_sel(new_i,tables.deck)
			elseif sel.state == state.move then
				-- new_i needs to be last row in current column
				local last_row = find_last_row_in_column(new_i)
				update_sel(last_row,tables.deck)
			end
		elseif sel.table == tables.slots and (card_slots[new_i])~=nil then
			update_sel(new_i,tables.slots)
		end
	end
	-- up
	if btnp(⬆️) then
		-- traverse within deck
		if sel.state == state.hover and sel.table == tables.deck then
			if sel.idx > max_column then
				local new_i = sel.idx-max_column
				update_sel(new_i,tables.deck) 
			else
				sel.table = tables.slots
				local new_i = 1
				update_sel(new_i,tables.slots) 
			end
		end
		-- if moving, up takes you straight to slots
		if sel.state == state.move and sel.table == tables.deck then
			sel.table = tables.slots
			local new_i = 1
			update_sel(new_i,tables.slots) 
		end
	end
	-- down
	if btnp(⬇️) then
		if sel.table == tables.slots or sel.table == tables.dragons or sel.table == tables.foundations then
			if sel.state == state.hover then
				local new_i = 1
				update_sel(new_i,tables.deck) 
			elseif sel.state == state.move then
				local new_i = find_last_row_in_column(1)
				update_sel(new_i,tables.deck)
			end 
		elseif sel.state == state.hover and (deck[sel.idx+max_column].type ~= card_type.empty) then
			local new_i = sel.idx+max_column
			update_sel(new_i,tables.deck) 
		end
	end
end

function find_last_row_in_column(idx)
    local new_i = ((idx - 1) % max_column) + 1

    while deck[new_i] ~= nil and deck[new_i].type ~= card_type.empty do
        new_i += max_column
    end

    return new_i
end

function _draw()
	cls(3) -- background color
	
	local card_width = 14
	local card_spacing = 3
	
	local card_slot_height = 4
	local card_deck_height = 32
	
	-- draw card slots
	for slot in all(card_slots) do
		spr(slot.sprite,slot.x,slot.y,slot.w,slot.h)
	end
	
	-- draw dragon buttons
	for button in all(dragon_buttons) do
		spr(button.sprite,button.x,button.y,button.w,button.h)
	end
	
	-- draw flower slot
	spr(flower_slot.sprite,flower_slot.x,flower_slot.y,flower_slot.w,flower_slot.h)
	
	-- draw foundation slots
	for slot in all(foundation_slots) do
		spr(slot.sprite,slot.x,slot.y,slot.w,slot.h)
	end
	
	-- draw deck
	for card in all(deck) do
		-- draw card
		spr(card.type,card.x,card.y,card.w,card.h)
		
		-- draw number
		if type(card.val) == "number" then
			print(card.val,card.x+2,card.y+2,card.col)
		end
	end

	-- draw grabbed card
	if grabbed_card != nil then
		spr(grabbed_card.type,sel.x-7,sel.y,grabbed_card.w,grabbed_card.h)

		if type(grabbed_card.val) == "number" then
			print(grabbed_card.val,sel.x-5,sel.y+2,grabbed_card.col)
		end
	end
	
	-- draw menu
	rectfill(0,115,127,127,1)
	rectfill(0,0,1,127,1)
	rectfill(126,0,127,127,1)
	
	-- new game button
	rect(89,117,125,125,6)
	rect(90,117,124,117,8)
	print("new game",92,119,6)
	
	-- score counter
	rect(2,117,42,125,6)
	print("win count",5,119,6)
	rect(42,117,62,125,6)
	
	-- print randomized deck
--	local y = 4
--	for card in all(deck) do
--		print("n:"..card[1]..", s:"..card[2], 4, y, 7)
--		y += 8 
--	end
	-- draw selection
	spr(sel.sprite,sel.x,sel.y)

end

function randomise_deck(deck)
	randomised_deck = {}
	local total_cards = #deck
	
	for x=1,total_cards do
		local idx = flr(rnd(#deck))+1
		local chosen = deli(deck,idx)
		add(randomised_deck,chosen)
	end
	
	return randomised_deck
end

function layout_deck(deck)
	-- todo: to each card, add 
	-- x,y,w,h for use in draw
	-- and for getting its value
	local card_deck_height = 31
	local card_spacing = 3
	local card_width = 2
	local card_height = 3
	local i = 1

    local column = 1
    local row = 1
	
	for card in all(deck) do
		-- where to draw card
        card.column = column
        card.row = row
		card.x = card_spacing
		card.y = card_deck_height
		card.w = 2
		card.h = 3

        -- draw next card to right
		card_spacing += (card_width*8)-1

		-- setup next row
		if i%max_column == 0 then
			column = 1
			row += 1

            card_deck_height += 7
			card_spacing = 3
        end
        
        i += 1
        column += 1
	end

	-- fill remaining slots with empty cards
    while (row <= max_row) do
        local empty_card = {
            type = card_type.empty,
			column = column,
			row = row,
			x = card_spacing,
			y = card_deck_height,
			w = 2,
			h = 3,
        }
		add(deck,empty_card)

		-- draw next card to right
		card_spacing += (card_width*8)-1

		-- setup next row
		if i%max_column == 0 then
			column = 1
			row += 1

            card_deck_height += 7
			card_spacing = 3
        end
        
        i += 1
        column += 1
    end
end

function init_selection()
	-- defaults to selecting 
	-- first card in front row
	local idx = (max_column*4)+1
	local front_card = deck[idx]
	front_card.idx = idx
	
	sel = {
		sprite=71,
		x=front_card.x+((front_card.w*8)/2)-1,
		y=front_card.y,
		card=front_card,
		idx=idx,
		state=state.hover,
		table=tables.deck
	}
	
	og_y = sel.y
end

function update_sel(i,table)
	local new
	if table == tables.deck then
		new = deck[i]
	elseif table == tables.slots then
		new = card_slots[i]
	elseif table == tables.dragons then
		new = dragon_buttons[i]
	elseif table == tables.foundations then
		new = foundation_slots[i]
	end

	local st = sel.state
	local sp = sel.sprite
	if new ~= nil then
		sel = {
			sprite=sp,
			x=new.x+((new.w*8)/2)-1,
			y=new.y,
			card=new,
			idx=i,
			state=st,
			table=table
		}
		og_y = sel.y
	end	
end

-- set selected card index to empty
function set_empty_card(idx)
    deck[idx].type = card_type.empty
	deck[idx].val = nil
end

function set_grabbed_card()
    if sel.table == tables.deck and sel.state == state.move then

        grabbed_card = {}
		grabbed_card_idx = sel.idx

        -- copy selected card information (since tables are passed by reference)
		grabbed_card.val = sel.card.val
		grabbed_card.type = sel.card.type
		grabbed_card.col = sel.card.col
        grabbed_card.x = sel.card.x
        grabbed_card.y = sel.card.y
        grabbed_card.column = sel.card.column
        grabbed_card.row = sel.card.row
		grabbed_card.w = sel.card.w
        grabbed_card.h = sel.card.h

        -- set selected card from deck to empty
        set_empty_card(sel.idx)

        -- move selection down one row
        sel.idx += 8

        update_sel(sel.idx, tables.deck)

    elseif grabbed_card ~= nil and sel.state == state.hover then

        -- cancel movement
        deck[grabbed_card_idx] = grabbed_card

		-- clear grabbed card
        grabbed_card = nil

		update_sel(sel.idx-8,tables.deck)
    end
end
