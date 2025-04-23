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
        x = 0,
        y = 0
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
        x = 1,
        y = 0
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
        x = 2,
        y = 0
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
        x = 3,
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
            'If hand contains {C:attention}four scoring cards{}',
            'and {C:attention}one non-scoring card{}, change the',
            'suit of the non-scoring card into one',
            'of the scoring card\'s suit'
        }
    },
    atlas = 'alexyz_jokers',
    pos = {
        x = 4,
        y = 0
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

-- Challenges

SMODS.Challenge {
    name = "Real Run: Seeing Things",
    key = "real_carl",
    loc_txt = {
        ['name'] = 'Real Run: Seeing Things'
    },
    rules = {
        custom = {},
        modifiers = {}
    },
    jokers = {
        { id = 'j_alexyz_carl' },
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

SMODS.Challenge {
    name = "Test: Seeing Things",
    key = "test_carl",
    loc_txt = {
        ['name'] = 'Test: Seeing Things'
    },
    rules = {
        custom = {},
        modifiers = {
            { id = 'hands',            value = 999 },
            { id = 'consumable_slots', value = 5 }
        }
    },
    jokers = {
        { id = 'j_alexyz_carl' },
    },
    consumeables = {
        { id = 'c_magician' }
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

SMODS.Challenge {
    name = "Real Run: Bonus Paycheck",
    key = "real_bonus_paycheck",
    loc_txt = {
        ['name'] = 'Real Run: Bonus Paycheck'
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

SMODS.Challenge {
    name = "Test: Bonus Paycheck",
    key = "test_bonus_paycheck",
    loc_txt = {
        ['name'] = 'Test: Bonus Paycheck'
    },
    rules = {
        custom = {},
        modifiers = {
            { id = 'hands',            value = 999 },
            { id = 'consumable_slots', value = 5 }
        }
    },
    jokers = {
        { id = 'j_alexyz_bonus_paycheck' },
    },
    consumeables = {
        { id = 'c_heirophant' },
        { id = 'c_heirophant' },
        { id = 'c_heirophant' },
        { id = 'c_empress' },
        { id = 'c_empress' }
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

SMODS.Challenge {
    name = "Test: To the Stars",
    key = "test_to_the_stars",
    loc_txt = {
        ['name'] = 'Test: To the Stars'
    },
    rules = {
        custom = {},
        modifiers = {
            { id = 'hands', value = 999 },
        }
    },
    jokers = {
        { id = 'j_alexyz_to_the_stars' }
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

SMODS.Challenge {
    name = "Test: Peer Pressure",
    key = "test_peer_pressure",
    loc_txt = {
        ['name'] = 'Test: Peer Pressure'
    },
    rules = {
        custom = {},
        modifiers = {
            { id = 'hands', value = 999 },
        }
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
