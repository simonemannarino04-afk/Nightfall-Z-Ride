# Boston: Apocalypse — Production Art Direction

## Visual target
A premium 2D/2.5D mobile zombie action game: grounded Boston-inspired streets, cinematic dusk/night lighting, readable silhouettes, realistic proportions with slightly stylized shapes, grime, emergency lighting, smoke and weather.

## Player asset set
Create a modular survivor with idle, 8-direction movement, rifle aim, fire, reload, hit, downed and revive animations. Weapon layer must remain separate from body/arms so rifles can be swapped without replacing the character.

## Zombie families
Walker, Drifter, Infected, Biter, Stalker, Runner and Tank. Each family needs idle, locomotion, attack, hit reaction and death variants. Runner uses a low forward posture and fast stride. Tank is 30–35% larger with heavy stagger animation.

## Environment kit
Boston brick facades, asphalt modules, sidewalks, barriers, abandoned civilian cars, police/emergency vehicles, street lamps, quarantine fencing, trash/debris, road signs, storefronts and distant skyline silhouettes. Keep foreground collision props separate from background dressing.

## FX layers
Muzzle flash, tracer, shell casing, impact spark, dust, glass, blood mist, smoke, fire embers, rain and emergency-light glow. FX should be short and pooled for mobile performance.

## Asset integration
Future textures belong under `assets/characters`, `assets/zombies`, `assets/weapons`, `assets/environment`, `assets/fx`, and `assets/ui`. Gameplay scripts should reference scenes/resources rather than hard-coded texture paths wherever possible.

## Mobile performance target
Use atlases, compressed textures, limited overdraw, pooled particles and enemies, and LOD-like reduction of animation/detail for distant actors. Gameplay must remain legible at 720p and scale cleanly to modern Android aspect ratios.
