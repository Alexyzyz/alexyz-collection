SMODS.Atlas {
    key = "alexyz_jokers",
    path = "alexyz_jokers.png",
    px = 71,
    py = 95,
    atlas_table = "ASSET_ATLAS"
}

-- Jokers

SMODS.Joker { -- Chunter
    name = "The Hunter",
    key = "chunter",
    loc_txt = {
        ['name'] = 'The Hunter',
        ['text'] = {
            'Does absolutely',
            '{C:attention}nothing{}'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 0,
        x = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true
}

SMODS.Joker { -- Seeing Things
    name = "Seeing Things",
    key = "carl",
    loc_txt = {
        ['name'] = 'Seeing Things',
        ['text'] = {
            'After each played hand,',
            'turn a random {C:attention}Consumable{} card',
            'into a random {C:tarot}Tarot{} card',
            '{C:inactive}({C:green}1 in 15{C:inactive} chance of turning into',
            '{C:inactive}a random {C:spectral}Spectral{C:inactive} card instead){}'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 0,
        x = 1
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        local target_consumable

        if context.before and G.consumeables.cards[1] then
            local target = pseudorandom_element(G.consumeables.cards, pseudoseed('see_things_target'))
            if target ~= nil then
                target_consumable = target
                local event_flip_down = Event({
                    trigger = 'after',
                    delay = 0.2,
                    func = function()
                        play_sound('tarot1')
                        target:juice_up(0.3, 0.4)             -- Make the card throb a bit
                        target.children.center.pinch.x = true -- Flatten the card on its x-axis
                        return true
                    end
                })
                local event_swap = Event({
                    trigger = 'after',
                    delay = 0.4,
                    func = function()
                        swap_tarot(target)
                        return true
                    end
                })
                local event_flip_up = Event({
                    trigger = 'after',
                    delay = 0.6,
                    func = function()
                        target:juice_up(0.3, 0.4)              -- Another throb
                        target.children.center.pinch.x = false -- Unflatten the card
                        target = nil
                        return true
                    end
                })

                card_eval_status_text(target_consumable, 'extra', nil, nil, nil, { message = 'Swap!' })

                G.E_MANAGER:add_event(event_flip_down)
                G.E_MANAGER:add_event(event_swap)
                G.E_MANAGER:add_event(event_flip_up)
            end
        end
    end
}

SMODS.Joker { -- Bonus Paycheck
    name = "Bonus Paycheck",
    key = "bonus_paycheck",
    loc_txt = {
        ['name'] = 'Bonus Paycheck',
        ['text'] = {
            'Played {C:attention}Bonus{} and {C:attention}Mult{}',
            'cards give {C:money}$1{} when scored',
            '{C:inactive}({C:green}1 in 2{C:inactive} chance',
            '{C:inactive}to give {C:money}$2{C:inactive} instead)'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 0,
        x = 2
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_bonus
        info_queue[#info_queue + 1] = G.P_CENTERS.m_mult
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.individual and
            (SMODS.get_enhancements(context.other_card)["m_bonus"] == true or
                SMODS.get_enhancements(context.other_card)["m_mult"] == true) then
            local is_bonus = false
            local earned_money = 1
            if pseudorandom('bonus_paycheck') < G.GAME.probabilities.normal / 2 then
                is_bonus = true
                earned_money = 2
            end

            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + earned_money
            G.E_MANAGER:add_event(Event({
                func = (function()
                    G.GAME.dollar_buffer = 0; return true
                end)
            }))

            card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil,
                { message = is_bonus and 'Bonus!' or 'Paid!' })

            return {
                dollars = earned_money,
                card = context.other_card
            }
        end
    end
}

SMODS.Joker { -- To the Stars
    name = "To the Stars",
    key = "to_the_stars",
    loc_txt = {
        ['name'] = 'To the Stars',
        ['text'] = {
            'While {C:attention}inactive{}, {C:red}decrease{} level',
            'of played hand and activate{}.',
            'While {C:attention}active{}, {C:green}increase{} level',
            'of played hand and deactivate',
            '{C:inactive}(#1#){}'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 0,
        x = 3
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            is_active = false,
            state_text = 'Inactive'
        },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.state_text } }
    end,

    calculate = function(self, card, context)
        if context.before then
            local hand_name = context.scoring_name

            if card.ability.extra.is_active then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = 'Deposit!' })
                level_up_hand(nil, hand_name, nil, 1)
                card.ability.extra.state_text = 'Inactive'
                card.ability.extra.is_active = false
            elseif G.GAME.hands[hand_name].level > 1 then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = 'Withdraw!' })
                level_up_hand(nil, hand_name, nil, -1)
                card.ability.extra.state_text = 'Active!'
                card.ability.extra.is_active = true

                -- Make this Joker throb after withdrawing a level
                -- until it deposits the level
                local eval = function()
                    return card.ability.extra.is_active == true
                end
                juice_card_until(card, eval, true)
            end
        end
    end
}

SMODS.Joker { -- Peer Pressure
    name = "Peer Pressure",
    key = "peer_pressure",
    loc_txt = {
        ['name'] = 'Peer Pressure',
        ['text'] = {
            'If played hand contains {C:attention}four scoring cards{}',
            'and {C:attention}one non-scoring card{}, change the',
            'suit of the non-scoring card into one',
            'of the scoring card\'s suit'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 0,
        x = 4
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.before then
            -- Joker needs 5 played cards to trigger
            if #context.full_hand ~= 5 then
                return
            end

            -- Joker needs 1 non-scoring card to trigger
            if #context.scoring_hand ~= 4 then
                return
            end

            local non_scoring_card
            -- Find the non-scoring card
            for i = 1, #context.full_hand do
                local curr_card = context.full_hand[i]
                local curr_card_is_scoring = false
                for j = 1, #context.scoring_hand do
                    local curr_scoring_card = context.scoring_hand[j]
                    if curr_card == curr_scoring_card then
                        curr_card_is_scoring = true
                        break
                    end
                end
                if not curr_card_is_scoring then
                    non_scoring_card = curr_card
                    break
                end
            end

            -- Get the suit from a random scoring card
            local random_scoring_card = pseudorandom_element(context.scoring_hand, pseudoseed('peer_pressure'))
            local pressure_is_useful = random_scoring_card.base.suit ~= non_scoring_card.base.suit

            card_eval_status_text(random_scoring_card, 'extra', nil, nil, nil,
                { message = pressure_is_useful and 'Pressure!' or 'Conform!' })

            if pressure_is_useful then
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.2,
                    func = function()
                        non_scoring_card:juice_up(0.3, 0.3)
                        non_scoring_card:change_suit(random_scoring_card.base.suit)
                        return true
                    end
                }))
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = pressure_is_useful and 1.5 or 0.8,
                func = function()
                    return true
                end
            }))
        end
    end
}

SMODS.Joker { -- Spotlight
    name = "Spotlight",
    key = "spotlight",
    loc_txt = {
        ['name'] = 'Spotlight',
        ['text'] = {
            'Force a card to be selected.',
            'If that card scores in a {C:attention}five-card hand{},',
            'turn that card into a {C:attention}Bonus{} or {C:attention}Mult{} card'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 1,
        x = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            spotlit_card = nil,
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_bonus
        info_queue[#info_queue + 1] = G.P_CENTERS.m_mult
    end,

    calculate = function(self, card, context)
        if context.hand_drawn then
            -- The following code is copy-pasted from Cerulean Bell's
            local any_forced = nil
            for k, v in ipairs(G.hand.cards) do
                if v.ability.forced_selection then
                    any_forced = true
                end
            end
            if not any_forced then
                G.hand:unhighlight_all()
                local target_card = pseudorandom_element(G.hand.cards, pseudoseed('spotlight'))
                target_card.ability.forced_selection = true
                G.hand:add_to_highlighted(target_card)
                card.ability.extra.spotlit_card = target_card
            end
        end
        if context.cardarea == G.jokers and context.before then
            -- Joker needs 5 scoring cards to trigger
            if #context.scoring_hand < 5 then
                return
            end

            -- See if the spotlit card is involved in scoring
            for k, v in ipairs(context.scoring_hand) do
                if v == card.ability.extra.spotlit_card then
                    local possible_enhancements = {
                        m_bonus = { G.P_CENTERS.m_bonus, 'Bonus Up!' },
                        m_mult = { G.P_CENTERS.m_mult, 'Mult Up!' }
                    }
                    local random_enhancement = pseudorandom_element(possible_enhancements,
                        pseudoseed('spotlight_enhancement'))

                    -- card_eval_status_text(v, 'extra', nil, nil, nil, { message = random_enhancement[2] })
                    v:set_ability(random_enhancement[1], nil, true)

                    G.E_MANAGER:add_event(Event({
                        func = function()
                            v:juice_up()
                            return true
                        end
                    }))

                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.8,
                        func = function()
                            return true
                        end
                    }))
                end
            end
        end
    end
}

SMODS.Joker { -- Setting Up Shop
    name = "Setting Up Shop",
    key = "setting_up_shop",
    loc_txt = {
        ['name'] = 'Setting Up Shop',
        ['text'] = {
            'After {C:attention}2{} rounds, sell this',
            'Joker and get {C:attention}Bargain Sale{}',
            '{C:inactive}(#1#){}'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 1,
        x = 1
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            rounds_remaining = 2,
            state_text = '2 rounds remaining'
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = { key = 'j_alexyz_bargain_sale', set = 'Other' }
        return { vars = { card.ability.extra.state_text } }
    end,

    calculate = function(self, card, context)
        if context.selling_self then
            if card.ability.extra.rounds_remaining == 0 then
                local bargain_sale = create_card('Joker', G.jokers, nil, 0.99, nil, nil, 'j_alexyz_bargain_sale',
                    'setting_up_shop')
                bargain_sale:add_to_deck()
                G.jokers:emplace(bargain_sale)

                -- TODO:
                -- This logic should've been in Bargain Sale,
                -- but I haven't found a signal that triggers when a card is created
                -- so for now I've performed a sin and put it here
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.GAME.current_round.free_rerolls = 2
                        calculate_reroll_cost(true)
                        return true
                    end
                }))
            end
        end

        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            if card.ability.extra.rounds_remaining > 0 then
                card.ability.extra.rounds_remaining = card.ability.extra.rounds_remaining - 1
            end
            local rounds_remaining = card.ability.extra.rounds_remaining

            if rounds_remaining > 1 then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = rounds_remaining .. '!' })
                card.ability.extra.state_text = rounds_remaining .. ' rounds remaining'
            elseif rounds_remaining == 1 then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = 'Open soon!' })
                card.ability.extra.state_text = rounds_remaining .. ' round remaining'
            elseif rounds_remaining == 0 then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = 'Ready!' })
                card.ability.extra.state_text = 'Ready!'

                -- Just keep throbbing until the card is removed
                local eval = function(card)
                    return not card.REMOVED
                end
                juice_card_until(card, eval, true)
            end
        end
    end
}

SMODS.Joker { -- Bargain Sale
    name = "Bargain Sale",
    key = "bargain_sale",
    loc_txt = {
        ['name'] = 'Bargain Sale',
        ['text'] = {
            '{C:green}Rerolls{} always cost {C:money}$1{}',
            '{C:red,E:2}Self-destructs{} after exiting shop'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 1,
        x = 2
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    -- This Joker never appears in the shop naturally
    -- and can only be obtained through Setting Up Shop
    yes_pool_flag = 'never',

    calculate = function(self, card, context)
        if context.end_of_round then
            G.GAME.current_round.free_rerolls = 2
            calculate_reroll_cost(true)
        end
        if context.buying_card then
            G.GAME.current_round.free_rerolls = 2
            calculate_reroll_cost(true)
        end
        if context.reroll_shop then
            G.GAME.current_round.free_rerolls = 2
            calculate_reroll_cost(true)
        end

        if context.ending_shop then
            G.GAME.current_round.free_rerolls = 0
            calculate_reroll_cost(true)
            card:start_dissolve()
        end
        if context.selling_self then
            G.GAME.current_round.free_rerolls = 0
            calculate_reroll_cost(true)
        end
    end
}

SMODS.Joker { -- Union
    name = "Union Rally",
    key = "union_rally",
    loc_txt = {
        ['name'] = 'Union Rally',
        ['text'] = {
            'If played hand contains:',
            'A {C:attention}Bonus{} card, {C:mult}+1{} Mult',
            'A {C:attention}Mult{} card, {C:chips}+3{} Chips',
            'Both cards, gain {X:mult,C:white}X0.1{} Mult',
            '{C:inactive}(Currently {C:blue}+#1#{C:inactive} Chips, {C:red}+#2#{C:inactive} Mult, {X:mult,C:white}X#3#{C:inactive} Mult)'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 0,
        x = 2
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            chips = 0,
            mult = 0,
            xmult = 1,
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_bonus
        info_queue[#info_queue + 1] = G.P_CENTERS.m_mult
        return { vars = { card.ability.extra.chips, card.ability.extra.mult, card.ability.extra.xmult } }
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.before and context.scoring_hand then
            local hand_contains_bonus = false
            local hand_contains_mult = false

            for k, v in ipairs(context.scoring_hand) do
                if v.ability.name == 'Bonus' then
                    hand_contains_bonus = true
                end
                if v.ability.name == 'Mult' then
                    hand_contains_mult = true
                end
            end

            if hand_contains_mult and hand_contains_bonus then
                card.ability.extra.chips = card.ability.extra.chips + 3
                card.ability.extra.mult = card.ability.extra.mult + 1
                card.ability.extra.xmult = card.ability.extra.xmult + 0.1
                return {
                    message = 'Triple Up!',
                    colour = G.C.PURPLE,
                    card = card
                }
            elseif hand_contains_mult then
                card.ability.extra.chips = card.ability.extra.chips + 3
                return {
                    message = 'Chip Up!',
                    colour = G.C.CHIPS,
                    card = card
                }
            elseif hand_contains_bonus then
                card.ability.extra.mult = card.ability.extra.mult + 1
                return {
                    message = 'Mult Up!',
                    colour = G.C.RED,
                    card = card
                }
            end
        end

        if context.cardarea == G.jokers and context.joker_main then
            return {
                message = 'Rally!',
                chip_mod = card.ability.extra.chips,
                mult_mod = card.ability.extra.mult,
                Xmult_mod = card.ability.extra.xmult,
            }
        end
    end
}

SMODS.Joker { -- Reckless Shot
    name = "Reckless Shot",
    key = "reckless_shot",
    loc_txt = {
        ['name'] = 'Reckless Shot',
        ['text'] = {
            'Destroy a random card',
            'held in hand at {C:attention}end of round{}',
            '{C:inactive}({C:green}1 in 2{C:inactive} chance of destroying',
            '{C:attention}an additional{C:inactive} card)'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        y = 1,
        x = 3
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        if not G.hand.cards then
            return
        end
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            -- This code is copy-pasted from Immolate's
            -- Get the cards to destroy
            local destroy_count = 1
            if pseudorandom('reckless_shot_bonus') < G.GAME.probabilities.normal / 2 then
                destroy_count = 2
            end

            local destroyed_cards = {}
            local temp_hand = {}
            for k, v in ipairs(G.hand.cards) do
                temp_hand[#temp_hand + 1] = v
            end

            local sort_eval = function(a, b)
                return not a.playing_card or not b.playing_card or a.playing_card < b.playing_card
            end
            table.sort(temp_hand, sort_eval)

            pseudoshuffle(temp_hand, pseudoseed('reckless_shot'))

            for i = 1, destroy_count do
                destroyed_cards[#destroyed_cards + 1] = temp_hand[i]
            end

            -- Destroy the cards
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    for i = #destroyed_cards, 1, -1 do
                        local card = destroyed_cards[i]
                        if card.ability.name == 'Glass Card' then
                            card:shatter()
                        else
                            card:start_dissolve(nil, i == #destroyed_cards)
                        end
                    end
                    return true
                end
            }))
            delay(0.5)
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end
    end
}

SMODS.Joker { -- Brian
    name = "Brian",
    key = "brian",
    loc_txt = {
        ['name'] = 'Brian',
        ['text'] = {
            'Debuff {C:attention}2{} random cards',
            'held in hand at {C:attention}end of round',
            'and this Joker gains {X:mult,C:white}X0.2{} Mult',
            '{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 2,
        y = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            xmult = 1,
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        return { vars = { card.ability.extra.xmult } }
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual and G.hand.cards then
            -- This code is copy-pasted from Immolate's
            -- Get the cards to debuff
            local debuffed_cards = {}
            local temp_hand = {}
            for k, v in ipairs(G.hand.cards) do
                temp_hand[#temp_hand + 1] = v
            end

            local sort_eval = function(a, b)
                return not a.playing_card or not b.playing_card or a.playing_card < b.playing_card
            end
            table.sort(temp_hand, sort_eval)
            pseudoshuffle(temp_hand, pseudoseed('socket_man'))

            local xmult_gain = 0
            for i = 1, 2 do
                if not temp_hand[i].perma_debuff then
                    xmult_gain = xmult_gain + 0.2
                end
                debuffed_cards[#debuffed_cards + 1] = temp_hand[i]
            end
            card.ability.extra.xmult = card.ability.extra.xmult + xmult_gain

            -- Debuff the cards
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.3,
                func = function()
                    for i = #debuffed_cards, 1, -1 do
                        local target_card = debuffed_cards[i]
                        target_card.ability.perma_debuff = true
                        target_card:set_debuff(true)
                        target_card:juice_up(0.3, 0.3)
                    end
                    return true
                end
            }))
            delay(1.5)
        end

        if context.cardarea == G.jokers and context.joker_main then
            return {
                message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.xmult } },
                Xmult_mod = card.ability.extra.xmult,
            }
        end
    end
}

SMODS.Joker { -- Seal of Approval
    name = "Seal of Approval",
    key = "seal_of_approval",
    loc_txt = {
        ['name'] = 'Seal of Approval',
        ['text'] = {
            'Each played {C:attention}7{} and {C:attention}Lucky{} card',
            'without a seal have a {C:green}1 in 2{}',
            'chance to gain a random {C:attention}seal{}',
            'when scored'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 2,
        y = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.individual then
            local card_is_a_7 = context.other_card:get_id() == 7
            local card_is_lucky = SMODS.get_enhancements(context.other_card)["m_lucky"] == true
            local card_has_no_seal = not context.other_card:get_seal()
            local approved = pseudorandom('seal_of_approval') < G.GAME.probabilities.normal / 2

            if (card_is_a_7 or card_is_lucky) and card_has_no_seal and approved then
                local seal_type_num = pseudorandom(pseudoseed('seal_of_approval_sealtype' .. G.GAME.round_resets.ante))
                local seal_type = 'Purple'

                if seal_type_num > 0.75 then
                    seal_type = 'Red'
                elseif seal_type_num > 0.5 then
                    seal_type = 'Blue'
                elseif seal_type_num > 0.25 then
                    seal_type = 'Gold'
                end

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.6,
                    func = function()
                        context.other_card:juice_up(0.3, 0.3)
                        context.other_card:set_seal(seal_type, nil, true)
                        return true
                    end
                }))
            end
        end
    end
}

SMODS.Joker { -- Hiking Bag
    name = "Hiking Bag",
    key = "hiking_bag",
    loc_txt = {
        ['name'] = 'Hiking Bag',
        ['text'] = {
            '{C:attention}+1{} consumable slot for',
            'every empty {C:attention}Joker{} slot'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 2,
        y = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            -- The update() method gets called too many times before add_to_cek() finishes properly
            -- so we need this flag to prevent the Joker from adding thousands of consumable slots
            initialized = false,
            added_slot_count = 0
        },
    },

    update = function(self, card, dt)
        if not card.ability.extra.initialized then
            return
        end

        local curr_added_slot_count = G.jokers.config.card_limit - #G.jokers.cards
        local delta_added_slot_count = curr_added_slot_count - card.ability.extra.added_slot_count

        if delta_added_slot_count == 0 then
            return
        end
        G.consumeables.config.card_limit = G.consumeables.config.card_limit + delta_added_slot_count
        card.ability.extra.added_slot_count = curr_added_slot_count
    end,

    add_to_deck = function(self, card, from_debuff)
        G.E_MANAGER:add_event(Event({
            func = function()
                local curr_added_slot_count = G.jokers.config.card_limit - #G.jokers.cards
                G.consumeables.config.card_limit = G.consumeables.config.card_limit + curr_added_slot_count
                card.ability.extra.added_slot_count = curr_added_slot_count
                card.ability.extra.initialized = true
                return true
            end
        }))
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.consumeables.config.card_limit = G.consumeables.config.card_limit - card.ability.extra
                    .added_slot_count
                return true
            end
        }))
    end
}

SMODS.Joker { -- Socket Man
    name = "Socket Man",
    key = "socket_man",
    loc_txt = {
        ['name'] = 'Socket Man',
        ['text'] = {
            'If {C:attention}first hand{} of round',
            'has only {C:attention}1{} card,',
            'that card becomes {C:dark_edition}Negative{}'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 2,
        y = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.before and G.GAME.current_round.hands_played == 0 and context.scoring_hand and #context.scoring_hand == 1 then
            context.scoring_hand[1]:set_edition({ negative = true })
        end
    end
}

SMODS.Joker { -- Abduction
    name = "Abduction",
    key = "abduction",
    loc_txt = {
        ['name'] = 'Abduction',
        ['text'] = {
            'On {C:attention}first hand{} of round,',
            'discard a random card held in hand and',
            'this Joker gains that card\'s {C:attention}rank{} in {C:chips}Chips{}',
            '{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 2,
        y = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
            chips = 0
        },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.before and G.GAME.current_round.hands_played == 0 and G.hand.cards and #G.hand.cards > 0 then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local any_selected = nil
                    local hand_cards = {}
                    for k, v in ipairs(G.hand.cards) do
                        hand_cards[#hand_cards + 1] = v
                    end

                    local selected_card, selected_card_key = pseudorandom_element(hand_cards, pseudoseed('abduction'))
                    G.hand:add_to_highlighted(selected_card, true)
                    table.remove(hand_cards, selected_card_key)
                    any_selected = true
                    play_sound('card1', 1)

                    if any_selected then
                        G.FUNCS.discard_cards_from_highlighted(nil, true)
                        card.ability.extra.chips = card.ability.extra.chips + selected_card.base.nominal
                    end

                    return true
                end
            }))

            return {
                message = localize('k_upgrade_ex'),
                card = card,
                colour = G.C.CHIPS
            }
        end

        if context.cardarea == G.jokers and context.joker_main and card.ability.extra.chips > 0 then
            return {
                message = localize { type = 'variable', key = 'a_chips', vars = { card.ability.extra.chips } },
                chip_mod = card.ability.extra.chips
            }
        end
    end
}

SMODS.Joker { -- Template
    name = "Test",
    key = "test",
    loc_txt = {
        ['name'] = 'Test',
        ['text'] = {
            ''
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 2,
        y = 0
    },
    cost = 1,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,

    config = {
        extra = {
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_bonus
        info_queue[#info_queue + 1] = G.P_CENTERS.m_mult
    end,

    calculate = function(self, card, context)
    end
}

-- Helper functions

function swap_tarot(target_card)
    local tarot_keys = {
        'c_fool',
        'c_magician',
        'c_high_priestess',
        'c_empress',
        'c_emperor',
        'c_heirophant',
        'c_lovers',
        'c_chariot',
        'c_justice',
        'c_hermit',
        'c_wheel_of_fortune',
        'c_strength',
        'c_hanged_man',
        'c_death',
        'c_temperance',
        'c_devil',
        'c_tower',
        'c_star',
        'c_moon',
        'c_sun',
        'c_judgement',
        'c_world',
    }

    local spectral_keys = {
        'c_familiar',
        'c_grim',
        'c_incantation',
        'c_talisman',
        'c_aura',
        'c_wraith',
        'c_sigil',
        'c_ouija',
        'c_ectoplasm',
        'c_immolate',
        'c_ankh',
        'c_deja_vu',
        'c_hex',
        'c_trance',
        'c_medium',
        'c_cryptid',
        'c_soul',
        'c_black_hole',
    }

    local original_pool = tarot_keys
    local is_spectral = false
    if pseudorandom('spectral') < G.GAME.probabilities.normal / 15 then
        original_pool = spectral_keys
        is_spectral = true
    end

    -- Make a copy of the table to pass by value
    local pool = shallow_copy(original_pool)

    -- Make sure Seeing Things doesn't convert a card into the same card
    for i, v in ipairs(pool) do
        if v == target_card.config.center_key then
            pool[i] = nil
        end
    end

    if is_spectral then
        pool[17] = nil -- Exclude The Soul because that'd make this Joker too good
        pool[18] = nil -- and Black Hole too
    end

    -- Fall back to Strength
    local new_center_key = 'c_strength'
    if get_table_length(pool) > 0 then
        new_center_key = pseudorandom_element(pool, pseudoseed('see_things_swap'))
    end
    local new_center = G.P_CENTERS[new_center_key]

    target_card = overwrite_card(new_center, target_card)
end

function overwrite_card(ref_center, new_card, card_scale, playing_card, strip_edition)
    local new_card = new_card

    new_card:set_ability(ref_center)
    new_card.ability.type = ref_center.config.type or ''

    -- START: Emulate what Card:set_ability does
    local ref_ability

    ref_ability = {
        name = ref_center.name,
        effect = ref_center.effect,
        set = ref_center.set,
        mult = ref_center.config.mult or 0,
        h_mult = ref_center.config.h_mult or 0,
        h_x_mult = ref_center.config.h_x_mult or 0,
        h_dollars = ref_center.config.h_dollars or 0,
        p_dollars = ref_center.config.p_dollars or 0,
        t_mult = ref_center.config.t_mult or 0,
        t_chips = ref_center.config.t_chips or 0,
        x_mult = ref_center.config.Xmult or 1,
        h_size = ref_center.config.h_size or 0,
        d_size = ref_center.config.d_size or 0,
        extra = copy_table(ref_center.config.extra) or nil,
        extra_value = 0,
        type = ref_center.config.type or '',
        order = ref_center.order or nil,
        forced_selection = ref_ability and ref_ability.forced_selection or nil,
        perma_bonus = ref_ability and ref_ability.perma_bonus or 0,
    }

    if ref_center.consumeable then
        ref_ability.consumeable = ref_center.config
    end
    -- END: Emulate what Card:set_ability does

    for k, v in pairs(ref_ability) do
        if type(v) == 'table' then
            new_card.ability[k] = copy_table(v)
        else
            new_card.ability[k] = v
        end
    end

    return new_card
end

-- Utility functions

function print_table(t)
    for k, v in pairs(t) do
        print(k .. ':')
        print(v)
    end
end

function get_table_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function shallow_copy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

-- Challenges

SMODS.Challenge { -- DEMO: Seeing Things
    name = "DEMO: Seeing Things",
    key = "demo_carl",
    loc_txt = {
        ['name'] = 'DEMO: Seeing Things'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_carl' }
    },
    consumeables = {
        { id = 'c_strength' }
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Bonus Paycheck
    name = "DEMO: Bonus Paycheck",
    key = "demo_bonus_paycheck",
    loc_txt = {
        ['name'] = 'DEMO: Bonus Paycheck'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_bonus_paycheck' },
    },
    consumeables = {
        { id = 'c_heirophant' },
        { id = 'c_empress' },
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: To the Stars
    name = "DEMO: To the Stars",
    key = "demo_to_the_stars",
    loc_txt = {
        ['name'] = 'DEMO: To the Stars'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_to_the_stars' }
    },
    consumeables = {
        { id = 'c_mercury' },
        { id = 'c_mercury' }
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Peer Pressure
    name = "DEMO: Peer Pressure",
    key = "demo_peer_pressure",
    loc_txt = {
        ['name'] = 'DEMO: Peer Pressure'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_peer_pressure' }
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Bargain Sale
    name = "DEMO: Bargain Sale",
    key = "demo_bargain_sale",
    loc_txt = {
        ['name'] = 'DEMO: Bargain Sale'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_setting_up_shop' },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Spotlight
    name = "DEMO: Spotlight",
    key = "demo_spotlight",
    loc_txt = {
        ['name'] = 'DEMO: Spotlight'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_spotlight' }
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Union Rally
    name = "DEMO: Union Rally",
    key = "demo_union_rally",
    loc_txt = {
        ['name'] = 'DEMO: Union Rally'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_union_rally' },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Brian
    name = "DEMO: Brian",
    key = "demo_brian",
    loc_txt = {
        ['name'] = 'DEMO: Brian'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_brian' }
    },
    consumeables = {
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Reckless Shot
    name = "DEMO: Reckless Shot",
    key = "demo_reckless_shot",
    loc_txt = {
        ['name'] = 'DEMO: Reckless Shot'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_reckless_shot' }
    },
    consumeables = {
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Hiking Bag
    name = "DEMO: Hiking Bag",
    key = "demo_hiking_bag",
    loc_txt = {
        ['name'] = 'DEMO: Hiking Bag'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_hiking_bag' }
    },
    consumeables = {
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Socket Man
    name = "DEMO: Socket Man",
    key = "demo_socket_man",
    loc_txt = {
        ['name'] = 'DEMO: Socket Man'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_socket_man' }
    },
    consumeables = {
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Abduction
    name = "DEMO: Abduction",
    key = "demo_abduction",
    loc_txt = {
        ['name'] = 'DEMO: Abduction'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_abduction' },
    },
    consumeables = {
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}

SMODS.Challenge { -- DEMO: Template
    name = "DEMO: Template",
    key = "demo_template",
    loc_txt = {
        ['name'] = 'DEMO: Template'
    },
    rules = {
        custom = {},
        modifiers = {
            { id = "dollars",          value = 1000000 },
            { id = "hands",            value = 1000 },
            { id = "discards",         value = 1000 },
            { id = "joker_slots",      value = 1000 },
            { id = "consumable_slots", value = 1000 }
        }
    },
    jokers = {
        { id = 'j_alexyz_reckless_shot' },
    },
    consumeables = {
    },
    vouchers = {},
    deck = {
        type = 'Challenge Deck'
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {}
    }
}
