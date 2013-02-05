`/*`
Weaponizr = {}
`*/`

ig.module(
    'game.common.weaponizr'
).requires(
).defines ->
    Weaponizr = ig.Class.extend
        activeEntities: []

        init: ->
            # Store any entities that can use weapons, based on a property
            for entity in ig.game.entities
                if entity.canUseWeapons?
                    entity.manaRegenerateTimer = new ig.Timer()
                    entity.manaRegenerateDelayTimer = new ig.Timer()

                    @activeEntities.push entity

        # Update
        update: ->
            for entity in @activeEntities
                @regenerateMana(entity)
                @changeEntityAnimation(entity)
                @spawnWeapon(entity)

        getWeaponCoordinates: (weaponEntity, spawningEntity) ->
            pos = x: 0, y: 0

            switch spawningEntity.facing
                when 'Up'
                    pos.x = spawningEntity.pos.x
                    pos.y = spawningEntity.pos.y - weaponEntity.size.y
                when 'Down'
                    pos.x = spawningEntity.pos.x
                    pos.y = spawningEntity.pos.y + weaponEntity.size.y
                when 'Left'
                    pos.x = spawningEntity.pos.x - weaponEntity.size.x
                    pos.y = spawningEntity.pos.y
                when 'Right'
                    pos.x = spawningEntity.pos.x + spawningEntity.size.x
                    pos.y = spawningEntity.pos.y
                else
                    pos = x: 0, y: 0

            return pos

        # Regenerate mana every second
        regenerateMana: (entity) ->
            if entity.manaRegenerateDelayTimer?.delta() > entity.manaRegenerateDelay
                if entity.manaRegenerateTimer.delta() > 1
                    entity.mana += entity.manaRegenerateRate if entity.mana + entity.manaRegenerateRate <= entity.maxMana
                    entity.manaRegenerateTimer.reset()

        # Change the entity's animation based on the active weapon and the direction being faced
        changeEntityAnimation: (entity) ->
            return if not ig.input.pressed 'attack'

            entity.currentAnim = entity.anims[entity.weaponManager.activeWeapon + entity.facing]

        # Spawn the appropriate weapon at the entity's position
        spawnWeapon: (entity) ->
            return if not ig.input.pressed 'attack'

            entity.weaponManager.weaponAnimTimer = new ig.Timer()

            weaponEntity = ig.game.spawnEntity(
                'Entity' +
                entity.weaponManager.activeWeapon.substring(0, 1).toUpperCase() +
                entity.weaponManager.activeWeapon.substring(1),
                0,
                0,
                facing: entity.facing
            )
            weaponEntity.pos = @getWeaponCoordinates weaponEntity, entity

            manaAfterCast = if entity.mana? and weaponEntity.cost? then entity.mana - weaponEntity.cost else -1

            if (entity.weaponManager.activeWeapon is 'fireball' and manaAfterCast >= 0) or entity.weaponManager.activeWeapon is 'axe'
                if entity.weaponManager.activeWeapon is 'fireball'
                    entity.mana -= weaponEntity.cost
                    entity.manaRegenerateDelayTimer = new ig.Timer()

                    weaponEntity.fire()