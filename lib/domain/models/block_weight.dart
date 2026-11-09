// Block Weight Class definitions according to PRD Section 11-14

enum BlockWeightClass {
  light(
    weight: 0.5,
    name: 'Light',
    elasticity: 0.85,
    friction: 0.4,
    settlementSpeedMs: 100,
    impactStrength: 0.3,
    shiftResistance: 0.2,
  ),
  normal(
    weight: 1.0,
    name: 'Normal',
    elasticity: 0.65,
    friction: 0.6,
    settlementSpeedMs: 160,
    impactStrength: 0.6,
    shiftResistance: 0.5,
  ),
  heavy(
    weight: 2.0,
    name: 'Heavy',
    elasticity: 0.4,
    friction: 0.8,
    settlementSpeedMs: 240,
    impactStrength: 1.0,
    shiftResistance: 0.85,
  ),
  ultra(
    weight: 4.0,
    name: 'Ultra',
    elasticity: 0.2,
    friction: 0.95,
    settlementSpeedMs: 320,
    impactStrength: 1.5,
    shiftResistance: 1.0,
  );

  final double weight;
  final String name;
  final double elasticity;
  final double friction;
  final int settlementSpeedMs;
  final double impactStrength;
  final double shiftResistance;

  const BlockWeightClass({
    required this.weight,
    required this.name,
    required this.elasticity,
    required this.friction,
    required this.settlementSpeedMs,
    required this.impactStrength,
    required this.shiftResistance,
  });
}
