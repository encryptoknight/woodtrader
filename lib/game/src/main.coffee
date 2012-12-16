WoodTraderGame = {}

# Cache all jQuery elements
elems =
    window: $(window)
    canvas: $('#canvas')
    guiContainer: $('#gui')
    gui:
        paused: $('#paused')

ig.module(
    'game.main'
)
.requires(
    'impact.game'
    'impact.font'

    # Debug
    'impact.debug.debug'

    # Plugins
    'plugins.impact-splash-loader'
    'plugins.director.director'

    # Levels
    'game.levels.market1'
    'game.levels.forest1'

    # Entities
    'game.entities.common.base-entity'
    'game.entities.common.particle-generator'
    'game.entities.common.particle'
    'game.entities.weapons.axe'
    'game.entities.weapons.fireball'
    'game.entities.inventory'
    'game.entities.inventory-item'
    'game.entities.player'
    'game.entities.trader'
    'game.entities.stall'
    'game.entities.tree'
    'game.entities.log'
    'game.entities.menu'
    'game.entities.enemy'
)
.defines ->

    # Override the loadLevel function to make the canvas lighter or darker, depending on which level
    # we're loading
    ig.Game.inject
        loadLevel: (level) ->
            @parent level

            levelName = switch level
                when LevelMarket1
                    elems.canvas.removeClass 'dark'
                    'Market1'
                when LevelForest1
                    elems.canvas.addClass 'dark'
                    'Forest1'

            # Position the player according to where he/she entered the level, or the default starting
            # position if the level was force-loaded. I add a bit of buffer room (30px) so the load level
            # triggers don't get triggered repeatedly
            if @playerLastPos?
                {x, y} = @playerLastPos
                x = if x > 30 then 30 else @mainBgMap.width * @mainBgMap.tilesize - 30
            else
                {x, y} = @playerStartingLevelPositions[levelName]

            @spawnEntity EntityPlayer, x, y

    MainGame = ig.Game.extend
        # Load a font
        info: new ig.Font 'media/fonts/04b03.font.png'

        # Preload music
        bgMusicMarket: new ig.Sound 'media/music/01-A-Night-Of-Dizzy-Spells.*'
        bgMusicForest: new ig.Sound 'media/music/02-Underclocked-Underunderclocked-Mix.*'

        # Preload sounds
        pauseFx: new ig.Sound 'media/sounds/pause.*'
        unpauseFx: new ig.Sound 'media/sounds/unpause.*'

        # Globally store the player entity for performance and ease of reference
        player: null

        # The main background map, used in camera and player positioning calculations
        mainBgMap: null

        # Store a global level director
        director: null

        # Sort all entities by their Y position
        autoSort: true
        sortBy: ig.Game.SORT.POS_Y

        playerStartingLevelPositions:
            Market1: x: 472, y: 292
            Forest1: x: 242, y: 202
        playerLastPos: null

        init: ->
            # Load EaselJS
#            SystemManager.init()

            # Auto-pause the game when leaving the browser tab
            $(window).blur -> ig.game.pause()

            # Toggle pausing the game if "P" or "ESC" are pressed. I do this by binding a keyup handler
            # to the document instead of listening for keypresses in ImpactJS because pausing stops
            # the game run loop, meaning when it's paused, it no longers pays attention to keypresses.
            # In other words, pausing would work, but unpausing wouldn't.
            $(document).keyup (e) ->
                ig.game.togglePause() if e.which in [27, 80]

            # Bind keys
            ig.input.bind ig.KEY.LEFT_ARROW, 'left'
            ig.input.bind ig.KEY.RIGHT_ARROW, 'right'
            ig.input.bind ig.KEY.UP_ARROW, 'up'
            ig.input.bind ig.KEY.DOWN_ARROW, 'down'
            ig.input.bind ig.KEY.SPACE, 'attack'
            ig.input.bind ig.KEY.TAB, 'switchWeapon'
            ig.input.bind ig.KEY.ENTER, 'confirm'
            ig.input.bind ig.KEY.I, 'inventory'

            # Bind mouse events
            ig.input.bind ig.KEY.MOUSE1, 'confirm'

            @director = new ig.Director @, [LevelMarket1, LevelForest1]

            # Decrease the volume so the sound effects are heard better
            ig.music.loop = true
            ig.music.volume = 0.5

            # Add and play music
            ig.music.add @bgMusicMarket, 'market'
            ig.music.add @bgMusicForest, 'forest'
            ig.music.play 'market'

            # Load the first level
            @director.jumpTo LevelMarket1

        update: ->
            # Update all entities and backgroundMaps
            @parent()

            @mainBgMap ?= ig.game.getMapByName 'main'

            if @player?
                # Store the player's last position so we can spawn him/her at an appropriate place
                # when loading a new level. E.g. walking through a door on the right edge of the map
                # and in the center of the screen should spawn the player at the left edge of the
                # next level's map and in the center
                @playerLastPos = @player.pos

                # Screen follows the player
                x = @player.pos.x - ig.system.width / 2
                y = @player.pos.y - ig.system.height / 2
                mapWidth = @mainBgMap.width * @mainBgMap.tilesize - ig.system.width
                mapHeight = @mainBgMap.height * @mainBgMap.tilesize - ig.system.height

                # Ensure that the screen doesn't scroll past the map limits
                x = if x < 0 then 0 else if x > mapWidth then mapWidth else x
                y = if y < 0 then 0 else if y > mapHeight then mapHeight else y

                @screen.x = x
                @screen.y = y

        draw: ->
            # Clear out the main canvas since Easel will have drawn things that Impact doesn’t know about
#            ctx = ig.system.context
#            ctx.setTransform 1, 0, 0, 1, 0, 0
#            ctx.clearRect 0, 0, ig.system.width, ig.system.height

            # Call draw on the parent object to make sure that all draws to the canvas are finalized
            # before telling Easel to update
            @parent()

            hudString = """
                        Weapon: #{@player.activeWeapon}
                        Health: #{@player.health}
                        Mana: #{@player.mana}
                        Logs: #{@player.inventory.getCount('log')}
                        """
            @info.draw(hudString, 20, 20)

            # Calls tick on our SystemManager object, which is the main EaselJS code
            # that handles drawing the non-gameplay elements
#            SystemManager.tick()

        pause: ->
            return if not ig.system or not ig.system?.running

            @pauseFx.play()
            ig.music.pause()
            ig.system.stopRunLoop()
            elems.canvas.addClass('inactive')

            # Center the paused text and show it
            elems.gui.paused.css(
                top: (elems.canvas.height() - elems.gui.paused.height()) / 2
                left: (elems.canvas.width() - elems.gui.paused.width()) / 2
            ).show()

        unpause: ->
            return if not ig.system or ig.system?.running

            @unpauseFx.play()
            ig.music.play()
            ig.system.startRunLoop()
            elems.canvas.removeClass('inactive')
            elems.gui.paused.hide()

        togglePause: ->
            if ig.system?.running
                ig.game.pause()
            else
                ig.game.unpause()

    StartScreen = ig.Game.extend
        instructText: new ig.Font 'media/fonts/04b03.font.png'

        init: ->
            ig.input.bind ig.KEY.SPACE, 'start'

        update: ->
            @parent()

            if ig.input.pressed('start')
                ig.system.setGame MainGame

        draw: ->
            @parent()

            x = ig.system.width / 2
            y = ig.system.height - 10
            @instructText.draw('Press Space To Start', x, y, ig.Font.ALIGN.CENTER)

    # Start the game
    ig.main '#canvas', StartScreen, 60, elems.canvas.width(), elems.canvas.height(), 1, ig.ImpactSplashLoader
