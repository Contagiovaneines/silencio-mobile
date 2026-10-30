# Animation guide

Plan state × facing × frame coverage before drawing. Typical states are idle, walk, run, attack,
hit, death, and interactions; only add states used by the game. List unavailable combinations
explicitly instead of silently reusing a misleading frame.

For locomotion, alternate weight-bearing legs and align the contact foot to the ground pivot.
Drive gait phase from distance travelled so movement speed and cadence agree; a stationary character
must use idle, not a running cycle. Keep the body center and shadow stable while limbs move. Review
facing changes, stop/start transitions, diagonal motion and low-stamina/low-health variants in-game.

Use a contact sheet with direction rows and frame columns. Verify timing from the actual game loop;
do not assume every action should loop. Attack, hit, interaction and death need deliberate one-shot
or locked-state behavior and must not replay because an atlas row ended.

The project currently has its own actor-frame selection logic. Read it before replacing anything.
Flame's `SpriteAnimation` is suitable for a new generic component/preview, but do not substitute it
for existing travelled-distance animation selection without a migration plan.
