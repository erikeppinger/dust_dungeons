/// Smallest and largest base points a chore can have.
const minBasePoints = 5;
const maxBasePoints = 100;

/// Points awarded for completing a chore once.
///
/// Overdue and streak bonuses plug in here in 0.3.0.
int pointsForCompletion({required int basePoints}) =>
    basePoints.clamp(minBasePoints, maxBasePoints);
