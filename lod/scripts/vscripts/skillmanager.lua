--[[
    Skill Managing Library for swapping skills during runtime
]]

-- Keeps track of what skills a given hero has
local currentSkillList = {}

-- Contains info on heroes
local heroListKV = LoadKeyValues("scripts/npc/npc_heroes.txt")

-- A list of sub abilities needed to give out when we add an ability
local subAbilities = LoadKeyValues("scripts/kv/abilityDeps.kv")

-- This object will be exported
local skillManager = {}

function skillManager:GetHeroSkills(heroClass)
    local skills = {}

    -- Build list of abilities
    for heroName, values in pairs(heroListKV) do
        if heroName == heroClass then
            for i = 1, 16 do
                local ab = values["Ability"..i]
                if ab and ab ~= 'attribute_bonus' then
                    table.insert(skills, ab)
                end
            end
        end
    end

    return skills
end

function skillManager:RemoveAllSkills(hero)
    -- Ensure the hero isn't nil
    if hero == nil then return end

    -- Check if we've touched this hero before
    if not currentSkillList[hero] then
        -- Grab the name of this hero
        local heroClass = hero:GetUnitName()

        -- Grab the skills
        local skills = self:GetHeroSkills(heroClass)

        -- Store it
        currentSkillList[hero] = skills
    end

    -- Remove all old skills
    for k,v in pairs(currentSkillList[hero]) do
        if hero:HasAbility(v) then
            hero:RemoveAbility(v)
        end
    end
end

function skillManager:ApplyBuild(hero, build)
    -- Ensure the hero isn't nil
    if hero == nil then return end

    -- Remove all the skills from this hero
    self:RemoveAllSkills(hero)

    -- Table to store all the extra skills we need to give
    local extraSkills = {}

    -- Give all the abilities in this build
    local abNum = 0
    for i=1,6 do
        local v = build[i]
        if v then
            abNum=abNum+1
            -- Check if this skill has sub abilities
            if subAbilities[v] then
                -- Store that we need this skill
                extraSkills[subAbilities[v]] = true
            end

            -- Add to build
            hero:AddAbility(v)
            currentSkillList[hero][abNum] = v

            -- Remove auras
            hero:RemoveModifierByName('modifier_'..v)
            hero:RemoveModifierByName('modifier_'..v..'_aura')
        end
    end

    -- Add missing abilities
    for k,v in pairs(extraSkills) do
        -- Move onto the next slot
        abNum = abNum + 1

        -- Add the ability
        hero:AddAbility(k)

        -- Remove auras
        hero:RemoveModifierByName('modifier_'..k)
        hero:RemoveModifierByName('modifier_'..k..'_aura')

        -- Store that we have it
        currentSkillList[hero][abNum] = k
    end
end

-- Define the export
SkillManager = skillManager
