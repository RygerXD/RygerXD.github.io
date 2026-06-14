# AI Workout JSON Guide

Use this guide when asking another AI assistant to turn an existing workout into
a `.json` file that can be imported into this app from the Library screen with
`Import Workout JSON`.

The app imports one workout plan per JSON file. A plan contains reusable
exercises plus one or more workouts. Workouts contain sets. Sets contain moves.
Each move points back to one reusable exercise by `exerciseId`.

## Copy-paste prompt

Paste this prompt into the other AI assistant, then replace the bracketed
sections with the workout you want converted.

```text
Convert the workout below into an importable Workout App JSON file.

Output rules:
- Return only valid JSON. Do not wrap it in Markdown.
- Use schemaVersion 2.
- Create one root object with planId, name, description, author, tags,
  exercises, and workouts.
- Use stable lowercase kebab-case IDs for planId, workoutId, setId, moveId,
  and exerciseId.
- Define every distinct exercise exactly once in exercises.
- Every move.exerciseId must match an exerciseId from exercises.
- Omit optional fields when unknown. Do not use null.
- Use integer seconds for all time values.
- Use type "reps" for counted movements and include repCount.
- Use type "duration" for timed countdown movements and include
  durationSeconds.
- Use type "stopwatch" only when the athlete should count up manually; do not
  include durationSeconds for stopwatch moves.
- For each set, set lapCount to the number of rounds and
  restBetweenLapsSeconds to the rest between repeated rounds.
- If a single move should be performed for multiple sets before advancing, add
  setCount with the number of sets for that move.
- Include prepTimeSeconds and finishTimeSeconds on moves only when the workout
  specifies setup or transition time.
- If weights are prescribed, use targetWeight with targetWeightUnit "kg" or
  "lb".
- If a duration move needs a cadence cue, use metronomeSpeed from 20 to 300 BPM.

Existing workout to convert:
[paste the workout here]

Plan metadata:
- Plan name: [name]
- Author: [author or source]
- Intended tags: [tag list]
- Optional plan image URL: [URL or leave blank]
```

## Required JSON shape

```json
{
  "schemaVersion": 2,
  "planId": "plan-id",
  "name": "Plan name",
  "description": "Short description",
  "author": "Author name",
  "imageUrl": "https://example.com/plan-image.jpg",
  "tags": ["strength", "beginner"],
  "exercises": [
    {
      "exerciseId": "exercise-id",
      "name": "Exercise name",
      "imageUrl": "https://example.com/exercise-image.jpg",
      "description": "How to perform the exercise"
    }
  ],
  "workouts": [
    {
      "workoutId": "workout-id",
      "title": "Workout title",
      "imageUrl": "https://example.com/workout-image.jpg",
      "sets": [
        {
          "setId": "set-id",
          "name": "Optional set name",
          "lapCount": 3,
          "restBetweenLapsSeconds": 60,
          "moves": [
            {
              "moveId": "move-id",
              "exerciseId": "exercise-id",
              "type": "reps",
              "repCount": 12,
              "setCount": 3,
              "prepTimeSeconds": 10,
              "finishTimeSeconds": 5,
              "targetWeight": 20,
              "targetWeightUnit": "lb"
            }
          ]
        }
      ]
    }
  ]
}
```

Optional fields can be omitted when they do not apply: `description`, `author`,
`imageUrl`, `tags`, set `name`, `prepTimeSeconds`, `finishTimeSeconds`,
`setCount`, `repeatEachSide`, `targetWeight`, `targetWeightUnit`, and
`metronomeSpeed`.

## Move types

Use exactly one of these `type` values for every move:

- `reps`: A counted movement. Must include `repCount`.
- `duration`: A countdown movement. Must include `durationSeconds`.
- `stopwatch`: A count-up movement. Do not include `durationSeconds`.

`prepTimeSeconds` and `finishTimeSeconds` default to `0` when omitted.
`setCount` defaults to `1`; use a larger value when one exercise should be
completed for multiple sets before moving to the next exercise.

Use `repeatEachSide: true` on any move where the listed target should run once
for the left side and once for the right side. For example, a 30-second lunge
with `repeatEachSide: true` counts as 60 active seconds, and a 10-rep split
squat displays as 10 reps per side. Do not create separate left and right
exercise entries for the same sided movement unless they need different names
or settings; the workout player expands the move into separate left and right
executions.

`metronomeSpeed` is only for `duration` moves and must be between `20` and
`300`.

## Import checks

Before importing, check that:

- The file is valid JSON with one root object.
- `schemaVersion` is `2`.
- `planId`, `name`, `workouts`, and `exercises` are present.
- `workouts` has at least one workout.
- `exercises` has at least one exercise.
- Every workout has at least one set.
- Every set has `lapCount` of at least `1` and at least one move.
- Every `move.exerciseId` exists in the top-level `exercises` list.
- If present, move `setCount` is at least `1`.
- Reps moves have `repCount` of at least `1`.
- Duration moves have `durationSeconds` of at least `1`.
- Stopwatch moves do not have `durationSeconds`.

The canonical schema is in `docs/schemas/workout-plan.schema.json`, and a
minimal working example is in `docs/schemas/examples/valid.plan.json`.

## Example

If the source workout is:

```text
Beginner full body workout.
3 rounds:
- 12 bodyweight squats
- 30 second plank
Rest 60 seconds between rounds.
```

The importable JSON can be:

```json
{
  "schemaVersion": 2,
  "planId": "beginner-full-body",
  "name": "Beginner Full Body",
  "description": "Three-round beginner full body workout.",
  "author": "AI generated",
  "tags": ["beginner", "full-body"],
  "exercises": [
    {
      "exerciseId": "bodyweight-squat",
      "name": "Bodyweight Squat",
      "description": "Squat using bodyweight only."
    },
    {
      "exerciseId": "plank",
      "name": "Plank",
      "description": "Hold a forearm plank."
    }
  ],
  "workouts": [
    {
      "workoutId": "full-body-a",
      "title": "Full Body A",
      "sets": [
        {
          "setId": "main-circuit",
          "name": "Main Circuit",
          "lapCount": 3,
          "restBetweenLapsSeconds": 60,
          "moves": [
            {
              "moveId": "squat-12",
              "exerciseId": "bodyweight-squat",
              "type": "reps",
              "repCount": 12
            },
            {
              "moveId": "plank-30",
              "exerciseId": "plank",
              "type": "duration",
              "durationSeconds": 30
            }
          ]
        }
      ]
    }
  ]
}
```
