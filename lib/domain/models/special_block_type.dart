// Special Block Types according to PRD Section 17 & 252-275

enum SpecialBlockType {
  none(
    displayName: 'Standard',
    description: 'A standard puzzle block.',
    iconName: 'circle',
  ),
  anchor(
    displayName: 'Anchor Block',
    description: 'Resists dynamic grid shifts and anchors adjacent cells.',
    iconName: 'anchor',
  ),
  gravity(
    displayName: 'Gravity Block',
    description: 'Exerts downwards gravitational pull on empty spaces below.',
    iconName: 'arrow_downward',
  ),
  magnet(
    displayName: 'Magnet Block',
    description: 'Attracts isolated floating cells horizontally.',
    iconName: 'grain',
  ),
  pulse(
    displayName: 'Pulse Block',
    description: 'Triggers a radial 3x3 resonance pulse when cleared.',
    iconName: 'flare',
  ),
  voidBlock(
    displayName: 'Void Block',
    description: 'Dissolves itself and immediate 4-orthogonal neighbors on placement.',
    iconName: 'blur_circular',
  ),
  bloom(
    displayName: 'Bloom Block',
    description: 'Doubles combo score and propagates particle flowers on clear.',
    iconName: 'spa',
  ),
  split(
    displayName: 'Split Block',
    description: 'Splits into single autonomous units upon partial line clear.',
    iconName: 'call_split',
  ),
  bomb(
    displayName: 'TNT Bomb Block',
    description: 'Triggers a devastating 3x3 explosive radius upon placement.',
    iconName: 'local_fire_department',
  ),
  laser(
    displayName: 'Laser Beam Block',
    description: 'Discharges horizontal and vertical beam blasts across intersecting lines.',
    iconName: 'flash_on',
  ),
  rainbow(
    displayName: 'Prism Rainbow Block',
    description: 'Chromatic wildcard block that counts towards any line clear and emits prismatic beams.',
    iconName: 'looks',
  ),
  lightning(
    displayName: 'Tesla Lightning Block',
    description: 'Discharges chain-reaction electric arcs to 3 random occupied blocks upon line clear.',
    iconName: 'bolt',
  ),
  ice(
    displayName: 'Frozen Ice Block',
    description: 'Enclosed in an ice shell. Cracks on first clear, shatters and awards 2x score on second clear.',
    iconName: 'ac_unit',
  ),
  coin(
    displayName: 'Treasure Coin Block',
    description: 'Clearing this block awards in-game Gold Coins to refill boosters.',
    iconName: 'monetization_on',
  ),
  timeBomb(
    displayName: 'Time-Bomb Block',
    description: 'Ticks down each turn. Clear within 5 moves for a double blast and huge bonus points!',
    iconName: 'alarm',
  ),
  geode(
    displayName: 'Crystal Geode Block',
    description: 'Triple-layer gem block. Cracks twice, then shatters into diamond crystals with 3x score multiplier!',
    iconName: 'diamond',
  ),
  portal(
    displayName: 'Wormhole Portal Block',
    description: 'Cosmic gateway that channels line clear energy across distant portal nodes.',
    iconName: 'all_inclusive',
  ),
  morph(
    displayName: 'Morphing Block',
    description: 'Chameleon piece in tray that shifts into alternative shapes each turn.',
    iconName: 'transform',
  );

  final String displayName;
  final String description;
  final String iconName;

  const SpecialBlockType({
    required this.displayName,
    required this.description,
    required this.iconName,
  });
}
