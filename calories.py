"""
Repo: https://codeberg.org/jannis/FitoTrack
commit: bd78b065cbe6083b2fee4c151f9125304392e21d
filepath: https://codeberg.org/jannis/FitoTrack/src/commit/bd78b065cbe6083b2fee4c151f9125304392e21d/app/src/main/java/de/tadris/fitness/util/CalorieCalculator.java

Java calories calc code:
public static int calculateCalories(Context context, Workout workout, double weight) {
        double mins = (double) (workout.duration / 1000) / 60;
        int ascent = (int) workout.ascent; // 1 calorie per meter
        return (int) (mins * (getMET(context, workout) * 3.5 * weight) / 200) + ascent;
    }
"""