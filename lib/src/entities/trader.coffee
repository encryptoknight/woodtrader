`/*`
EntityTrader = {}
`*/`

ig.module(
    'game.entities.trader'
)
.requires(
    'game.entities.common.static-entity'
    'game.entities.inventory'
    'game.entities.dialog'
)
.defines ->
    EntityTrader = EntityStaticEntity.extend
        size:
            x: 29
            y: 35
        offset:
            x: 10
            y: 28
        collides: ig.Entity.COLLIDES.FIXED
        type: ig.Entity.TYPE.A
        animSheet: new ig.AnimationSheet 'media/characters/trader.png', 48, 64

        bubble: new ig.Image 'media/dialogs/ellipsis.png'
        bubbleRelativePos: x: -2, y: -43
        playerIsNear: false

        dialogs: []
        dialogVisible: false
        dialogRelativePos: x: -2, y: -100

        # The possible states this entity can be in
        states:
            DEFAULT: 1
            IN_INVENTORY: 2

        # The current state for this entity
        state: null

        # Last direction the player was facing, so the correct idle animation is shown
        facing: 'Down'

        # Default moving velocity
        velocity: 200

        # Maximum velocity
        maxVel:
            x: 500
            y: 500

        idleAnimSpeed: 1
        movingAnimSpeed: 0.06

        # Whether the entity is allowed to move
        movementAllowed: true

        # Store the inventory entity
        inventory: null

        init: (x, y, settings) ->
            # Add animations for the animation sheet
            @addAnim 'idleDown', @idleAnimSpeed, [0]
            @addAnim 'idleUp', @idleAnimSpeed, [8]
            @addAnim 'idleRight', @idleAnimSpeed, [16]
            @addAnim 'idleLeft', @idleAnimSpeed, [24]
            @addAnim 'walkDown', @movingAnimSpeed, [0, 1, 2, 3, 4, 5, 6, 7]
            @addAnim 'walkUp', @movingAnimSpeed, [8, 9, 10, 11, 12, 13, 14, 15]
            @addAnim 'walkRight', @movingAnimSpeed, [16, 17, 18, 19, 20, 21, 22, 23]
            @addAnim 'walkLeft', @movingAnimSpeed, [24, 25, 26, 27, 28, 29, 30, 31]

            # Set the entity's default state
            @state = @states.DEFAULT

            # Spawn the inventory at 0, 0 and store it, but only if we're not in Weltmeister
            if not ig.global.wm
                @inventory = ig.game.spawnEntity EntityInventory

                # Set inventory position to the center of the screen
                @inventory.pos.x = (ig.system.width - @inventory.size.x) / 2
                @inventory.pos.y = (ig.system.height - @inventory.size.y) / 2

            # Call the parent constructor
            @parent x, y, settings

            # Spawn the dialogs
            dialog = ig.game.spawnEntity(
                EntityDialog
                @pos.x + @dialogRelativePos.x
                @pos.y + @dialogRelativePos.y
                text: ["I enjoy purchasing\nvarious species of\ntrees!"]
            )
            @dialogs.push dialog

        update: ->
            @playerIsNear = @distanceTo(ig.game.player) < 110

            @parent()

        draw: ->
            # Set the inventory's visibility based on whether we're in Weltmeister and the
            # player is trying to access the inventory
            if not ig.global.wm
                @inventory.isVisible = @state == @states.IN_INVENTORY

            if ig.input.pressed('confirm') and @playerIsNear
                @dialogVisible = @playerIsNear and not @dialogVisible
                ig.game.player.movementAllowed = not @dialogVisible

            if @playerIsNear
                if @dialogVisible
                    # Update the dialog position according to the trader position and screen offset
                    @dialogs[0].visible = true
                    @dialogs[0].pos = x: @pos.x - ig.game.screen.x + @dialogRelativePos.x, y: @pos.y - ig.game.screen.y + @dialogRelativePos.y
                else
                    @dialogs[0].visible = false
                    @bubble.draw @pos.x - ig.game.screen.x + @bubbleRelativePos.x, @pos.y - ig.game.screen.y + @bubbleRelativePos.y

            @parent()