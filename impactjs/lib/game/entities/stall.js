ig.module(
    'game.entities.stall'
)
.requires(
    'impact.entity'
)
.defines(function () {
    EntityStall = ig.Entity.extend({
        size: {x: 128, y: 80},
        collides: ig.Entity.COLLIDES.FIXED,

        animSheet: new ig.AnimationSheet('media/stall.png', 128, 80),

        init: function (x, y, settings) {
            this.addAnim('idle', 1, [0]);

            this.parent(x, y, settings);
        },

        // Override the update function to get better performance, since nothing needs to happen here
        update: function () {}
    });
});
