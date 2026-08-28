pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	foundflower = false

	animating_card = nil
	animating_card_start_x = 0
	animating_card_start_y = 0
	animating_card_end_x = 0
	animating_card_end_y = 0
	animating_card_t = 0

	init_deck={}
	
	grabbed_card = nil

	is_initial_autoplay_done = false

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
			x=card_spacing,
			y=card_slot_height,
			card = {
				type = card_type.empty,
				x=card_spacing,
				y=card_slot_height,
				w=2,
				h=3,
			},
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
		card = {
			type = card_type.empty,
			x=card_spacing,
			y=card_slot_height,
			w=2,
			h=3,
		},
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
				card = {
					type = card_type.empty,
					x=card_spacing,
					y=card_slot_height,
					w=2,
					h=3,
				},
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
		if sel.state == state.hover and check_grabbable() then
			sel.state = state.move
			set_grabbed_cards()
		elseif sel.state == state.move then 
			if check_placeable() == true then
				-- place and clear grabbed cards
				place_grabbed_cards(sel.idx)
				sel.state = state.hover
			end
		end
	end
	if btnp(🅾️) then
		-- cancel move
		if sel.state == state.move then 
			sel.state = state.hover
			-- return cards to original position
			place_grabbed_cards(grabbed_card_idx)
		end
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
				local last_row = find_last_row_in_column(new_i)-max_column
				update_sel(last_row,tables.deck)
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
				local last_row = find_last_row_in_column(new_i)-max_column
				update_sel(last_row,tables.deck)
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
		-- if moving, up takes you straight to slots (if not holding stack of cards)
		if sel.state == state.move and sel.table == tables.deck and #grabbed_card == 1 then
			sel.table = tables.slots
			local new_i = 1
			update_sel(new_i,tables.slots) 
		end
	end
	-- down
	if btnp(⬇️) then
		if sel.table == tables.slots or sel.table == tables.dragons or sel.table == tables.foundations then
			if sel.state == state.hover then
				local new_i = find_last_row_in_column(1)
				update_sel(new_i-max_column,tables.deck) 
			elseif sel.state == state.move then
				local new_i = find_last_row_in_column(1)
				update_sel(new_i,tables.deck)
			end 
		elseif sel.state == state.hover and (deck[sel.idx+max_column].type ~= card_type.empty) then
			local new_i = sel.idx+max_column
			update_sel(new_i,tables.deck) 
		end
	end

	if is_initial_autoplay_done == false then 
		autoplay_tables()
		is_initial_autoplay_done = true
	end

	if animating_card ~= nil then
		animating_card_t += 0.08

		if animating_card_t >= 1 then
			animating_card_t = 1

			animating_card.x = animating_card_end_x
			animating_card.y = animating_card_end_y

			flower_slot.card = animating_card
			animating_card = nil

		else
			animating_card.x = lerp(
				animating_card_start_x,
				animating_card_end_x,
				animating_card_t
			)

			animating_card.y = lerp(
				animating_card_start_y,
				animating_card_end_y,
				animating_card_t
			)
		end
	end
end

-- linear interpolation for smooth animation
function lerp(start_x,end_x,t)
    return start_x+(end_x-start_x)*t
end

-- check if there is a card to go into the foundation or flower slots
-- and move it automatically (animated)
function autoplay_tables()
	-- get lowest nonempty row of each column
	local column = 1

	while column <= max_column do
		local i = find_last_row_in_column(column)-max_column

		if deck[i].type == card_type.flower then
			foundflower = true
			start_card_animation(i, flower_slot)
			break
		end

		column += 1
	end
end

function start_card_animation(i, slot)
    animating_card = {
        val = deck[i].val,
        type = deck[i].type,
        col = deck[i].col,
        x = deck[i].x,
        y = deck[i].y,
        w = deck[i].w,
        h = deck[i].h
    }

    animating_card_start_x = deck[i].x
    animating_card_start_y = deck[i].y

    animating_card_end_x = slot.x
    animating_card_end_y = slot.y

    animating_card_t = 0

    -- remove it from the deck logically
    deck[i].type = card_type.empty
end

function find_last_row_in_column(idx)
    local new_i = ((idx - 1) % max_column) + 1

    while deck[new_i] ~= nil and deck[new_i].type ~= card_type.empty do
        new_i += max_column
    end

    return new_i
end

-- check if column to grab is alternating colours and descending in number by 1
function check_grabbable()
	local is_grabbable = false
	local next_card = sel.idx + max_column
	local curr_card = sel.idx

	if sel.table == tables.slots and sel.card.type ~= card_type.empty then return true
	
	elseif sel.table == tables.deck then
		-- grabbable if next row's slot is empty
		if deck[next_card].type == card_type.empty then return true
		-- not grabbable if current card isnt a number
		elseif type(deck[curr_card].val) ~= "number" then return false

		else
			-- check if next card: is a number, a different suit, and is less than current card by 1
			while deck[next_card].type ~= card_type.empty do
				if type(deck[next_card].val) == "number" and 
				deck[next_card].type ~= deck[curr_card].type and 
				deck[next_card].val == deck[curr_card].val-1 then
					is_grabbable = true
				else
					is_grabbable = false
				end

				-- move down one card
				curr_card = next_card
				next_card += max_column
			end
		end
		return is_grabbable
	end
end

-- check if grabbed cards can be placed on the selected slot
function check_placeable() 
	if sel.table == tables.slots and sel.card.type == card_type.empty then 
		return true
	elseif sel.table == tables.deck then
		local prev_card = sel.idx - max_column
		-- if not holding number card, cant place in deck
		if type(grabbed_card[1].val) ~= "number" then return false
		-- check if previous card: is a number, a different suit, and is higher than 1st grabbed card by 1
		elseif type(deck[prev_card].val) == "number" and 
		deck[prev_card].type ~= grabbed_card[1].type and 
		deck[prev_card].val == grabbed_card[1].val+1 then
			return true
		end
	end
	return false
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
		if slot.card.val ~= nil then 
			-- draw card
			spr(slot.card.type,slot.card.x,slot.card.y,slot.card.w,slot.card.h)
			
			-- draw number
			if type(slot.card.val) == "number" then
				print(slot.card.val,slot.card.x+2,slot.card.y+2,slot.card.col)
			end
		end
	end
	
	-- draw dragon buttons
	for button in all(dragon_buttons) do
		spr(button.sprite,button.x,button.y,button.w,button.h)
	end
	
	-- draw flower slot
	spr(flower_slot.sprite,flower_slot.x,flower_slot.y,flower_slot.w,flower_slot.h)
	if flower_slot.card.val ~= nil then 
		-- draw card
		spr(flower_slot.card.type,flower_slot.card.x,flower_slot.card.y,flower_slot.card.w,flower_slot.card.h)
	end
	
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

	-- draw grabbed cards relative to selection cursor
	if grabbed_card != nil then
		local y_offset = 0
		for card in all(grabbed_card) do
			spr(card.type,sel.x-7,sel.y+y_offset,card.w,card.h)

			if type(card.val) == "number" then
				print(card.val,sel.x-5,sel.y+y_offset+2,card.col)
			end

			y_offset += 7
		end
	end
	
	-- draw menu
	rectfill(0,115,127,127,1)
	rectfill(0,0,1,127,1)
	rectfill(126,0,127,127,1)
	
	-- new game button
	rectfill(89,117,125,125,6)
	-- rect(89,117,125,117,8)
	print("new game",92,119,1)
	
	-- score counter
	print("win count:000",2,119,6)
	
	-- print randomized deck
--	local y = 4
--	for card in all(deck) do
--		print("n:"..card[1]..", s:"..card[2], 4, y, 7)
--		y += 8 
--	end
	-- draw selection
	spr(sel.sprite,sel.x,sel.y)

	if foundflower then print("found flower",45,100,1) end

	if animating_card ~= nil then
		spr(
			animating_card.type,
			animating_card.x,
			animating_card.y,
			animating_card.w,
			animating_card.h
		)

		if type(animating_card.val) == "number" then
			print(
				animating_card.val,
				animating_card.x + 2,
				animating_card.y + 2,
				animating_card.col
			)
		end
	end
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
		new = card_slots[i].card
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
	if sel.table == tables.deck then 
		deck[idx].type = card_type.empty
		deck[idx].val = nil
	elseif sel.table == tables.slots then
		card_slots[idx].card.type = card_type.empty
		card_slots[idx].card.val = nil
	end
end

function set_grabbed_cards()
	if sel.state == state.move then
		grabbed_card = {}
		grabbed_card_idx = sel.idx

		if sel.table == tables.deck then
			local gc_i = 1
			local dc_i = sel.idx
			while deck[dc_i].type ~= card_type.empty do
				-- copy selected card information (since tables are passed by reference)
				grabbed_card[gc_i] = {}
				grabbed_card[gc_i].val = deck[dc_i].val
				grabbed_card[gc_i].type = deck[dc_i].type
				grabbed_card[gc_i].col = deck[dc_i].col
				grabbed_card[gc_i].x = deck[dc_i].x
				grabbed_card[gc_i].y = deck[dc_i].y
				grabbed_card[gc_i].column = deck[dc_i].column
				grabbed_card[gc_i].row = deck[dc_i].row
				grabbed_card[gc_i].w = deck[dc_i].w
				grabbed_card[gc_i].h = deck[dc_i].h

				-- set selected card from deck to empty
				set_empty_card(dc_i)

				dc_i += max_column
				gc_i += 1
			end

			-- move selection down one row
			sel.idx += max_column

			update_sel(sel.idx, tables.deck)

		elseif sel.table == tables.slots then 
			local gc_i = 1
			local sc_i = sel.idx

			-- copy selected card information (since tables are passed by reference)
			grabbed_card[gc_i] = {}
			grabbed_card[gc_i].val = card_slots[sc_i].card.val
			grabbed_card[gc_i].type = card_slots[sc_i].card.type
			grabbed_card[gc_i].col = card_slots[sc_i].card.col
			grabbed_card[gc_i].x = card_slots[sc_i].card.x
			grabbed_card[gc_i].y = card_slots[sc_i].card.y
			grabbed_card[gc_i].column = card_slots[sc_i].card.column
			grabbed_card[gc_i].row = card_slots[sc_i].card.row
			grabbed_card[gc_i].w = card_slots[sc_i].card.w
			grabbed_card[gc_i].h = card_slots[sc_i].card.h

			-- set selected card from slot to empty
			set_empty_card(sc_i)
		end
	end
end

function place_grabbed_cards(idx)
	if grabbed_card ~= nil then
		local i = idx
		-- place grabbed cards at index
		if sel.table == tables.slots then 
			grabbed_card[1].x = card_slots[i].x
			grabbed_card[1].y = card_slots[i].y
			grabbed_card[1].column = 1
			grabbed_card[1].row = 1

			card_slots[i].card = grabbed_card[1]
		elseif sel.table == tables.deck then
			for card in all(grabbed_card) do
				card.x = deck[i].x
				card.y = deck[i].y
				card.column = deck[i].column
				card.row = deck[i].row

				deck[i] = card
				i += max_column
			end
		end

		-- clear grabbed cards
        grabbed_card = nil
		grabbed_card_idx = nil

		-- cancel movement
		update_sel(i-max_column,tables.deck)
    end
end
