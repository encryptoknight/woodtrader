// EaselJS wrapper
SystemManager = {
    canvas: document.getElementById("canvas"),
    stage: new Stage(this.canvas),
    player: {
        idle: new Image(),
        walk: new Image()
    },
    playerWalkAnim: null,
    playerIdleAnim: null,
    numImagesLoaded: 0,
    screenWidth: null,

    /* Methods */

    init: function () {
        this.player.idle.onload = this.player.walk.onload = this.handleImageLoad;
        this.player.idle.onerror = this.player.walk.onerror = this.handleImageLoad;

        this.player.idle.src = "media/player/idle.png";
        this.player.walk.src = "media/player/run.png";

        // Set the stage to not autoClear
        // This keeps EaselJS from erasing all of what Impact has already drawn to canvas.
        this.stage.autoClear = false;

        this.startGame();
    },

    handleImageLoad: function () {
        if (this.numImagesLoaded == 2) {
            this.startGame();
        }

        this.numImagesLoaded++;
    },

    handleImageError: function (e) {
        console.log('Problem loading image: ' + e.target.src);
    },

    startGame: function () {
        // grab canvas width and height for later calculations
        this.screenWidth = this.canvas.width;

        // create spritesheet and assign the associated data
        var spriteSheetPlayerWalk = new SpriteSheet({
            images: [this.player.walk],
            frames: {width: 64, height: 64, regX: 32, regY: 32},
            animations: {
                walk: [0, 9, "walk", 4]
            }
        });

        var spriteSheetPlayerIdle = new SpriteSheet({
            images: [this.player.idle],
            frames: {width: 64, height: 64, regX: 32, regY: 32},
            animations: {
                idle: [0, 9, "idle", 4]
            }
        });

        SpriteSheetUtils.addFlippedFrames(spriteSheetPlayerWalk, true, false, false);

        // create a BitmapAnimation instance to display and play back the sprite sheet
        this.playerWalkAnim = new BitmapAnimation(spriteSheetPlayerWalk);
        this.playerIdleAnim = new BitmapAnimation(spriteSheetPlayerIdle);

        // start playing the first sequence
        this.playerWalkAnim.gotoAndPlay("walk_h");

        // Set up a shadow. Note that shadows are ridiculously expensive. You could display hundreds
        // of animated rats if you disabled the shadow
        this.playerWalkAnim.shadow = new Shadow("#454", 0, 5, 4);

        this.playerWalkAnim.name = "playerWalk";
        this.playerWalkAnim.direction = 90;
        this.playerWalkAnim.vX = 1;
        this.playerWalkAnim.x = this.playerIdleAnim.x = 16;
        this.playerWalkAnim.y = this.playerIdleAnim.y = 32;

        this.playerIdleAnim.name = "playerIdle";

        // have each monster start at a specific frame
        this.playerWalkAnim.currentFrame = 0;
        this.stage.addChild(this.playerWalkAnim);
    },

    // Update Easel in sync with Impact
    tick: function () {
        // We've reached the right side of our screen;
        // we need to walk left now to go back to our initial position
        if (this.playerWalkAnim.x >= this.screenWidth - 16) {
            this.playerWalkAnim.direction = -90;
            this.playerWalkAnim.gotoAndPlay("walk");
        }

        // We've reached the left side of our screen;
        // we need to walk right now
        if (this.playerWalkAnim.x < 16) {
            this.playerWalkAnim.direction = 90;
            this.playerWalkAnim.gotoAndStop("walk");
            this.stage.removeChild(this.playerWalkAnim);
            this.playerIdleAnim.gotoAndPlay("idle");
            this.stage.addChild(this.playerIdleAnim);
        }

        // Move the sprite based on the direction and speed
        var direction = this.playerWalkAnim.direction == 90 ? '+' : '-';

        this.playerWalkAnim.x += parseInt(direction + this.playerWalkAnim.vX);

        // Call Easel's update function to draw all of its queued changes
        // Before the frame ends and Impact takes control again
        this.stage.update();
    }
};