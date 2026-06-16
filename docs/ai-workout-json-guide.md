# AI Workout JSON Guide

Use this guide when asking another AI assistant to turn an existing workout into
a `.json` file that can be imported into this app from the Library screen with
`Import Workout JSON`.

The app imports one workout plan per JSON file. A plan contains reusable
moves plus one or more workouts. Workouts contain sets. Sets contain workout
moves. Each workout move points back to one reusable move by `moveId`.

## Copy-paste prompt

Paste this prompt into the other AI assistant, then replace the bracketed
sections with the workout you want converted.

```text
Convert the workout below into an importable Workout App JSON file.

Output rules:
- Return only valid JSON. Do not wrap it in Markdown.
- Use schemaVersion 4.
- Create one root object with planId, name, description, author, tags,
  moves, and workouts.
- Use stable lowercase kebab-case IDs for planId, workoutId, setId,
  workoutMoveId, and moveId.
- Define every distinct move exactly once in moves.
- Every workout move `moveId` must match a `moveId` from `moves`.
- Omit optional fields when unknown. Do not use null.
- Use integer seconds for all time values.
- Use type "reps" for counted movements and include repCount.
- Use type "duration" for timed countdown movements and include
  durationSeconds.
- Use type "stopwatch" only when the athlete should count up manually; do not
  include durationSeconds for stopwatch moves.
- For each set, include lapCount only when it is more than 1 and
  restBetweenLapsSeconds only when there is rest between repeated rounds.
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
  "schemaVersion": 4,
  "planId": "plan-id",
  "name": "Plan name",
  "description": "Short description",
  "author": "Author name",
  "imageUrl": "https://example.com/plan-image.jpg",
  "tags": ["strength", "beginner"],
  "moves": [
    {
      "moveId": "move-id",
      "name": "Move name",
      "imageUrl": "https://example.com/move-image.jpg",
      "description": "How to perform the move"
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
              "workoutMoveId": "workout-move-id",
              "moveId": "move-id",
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
`imageUrl`, `tags`, set `name`, `lapCount`, `restBetweenLapsSeconds`,
`prepTimeSeconds`, `finishTimeSeconds`, `setCount`, `repeatEachSide`,
`targetWeight`, `targetWeightUnit`, and `metronomeSpeed`.

## Move types

Use exactly one of these `type` values for every move:

- `reps`: A counted movement. Must include `repCount`.
- `duration`: A countdown movement. Must include `durationSeconds`.
- `stopwatch`: A count-up movement. Do not include `durationSeconds`.

`prepTimeSeconds` and `finishTimeSeconds` default to `0` when omitted.
`lapCount` defaults to `1`, and `restBetweenLapsSeconds` defaults to `0`.
`setCount` defaults to `1`; use a larger value when one move should be
completed for multiple sets before moving to the next move.

Use `repeatEachSide: true` on any move where the listed target should run once
for the left side and once for the right side. For example, a 30-second lunge
with `repeatEachSide: true` counts as 60 active seconds, and a 10-rep split
squat displays as 10 reps per side. Do not create separate left and right
move entries for the same sided movement unless they need different names
or settings; the workout player expands the move into separate left and right
executions.

`metronomeSpeed` is only for `duration` moves and must be between `20` and
`300`.

## Import checks

Before importing, check that:

- The file is valid JSON with one root object.
- `schemaVersion` is `4`.
- `planId`, `name`, `workouts`, and `moves` are present.
- `workouts` has at least one workout.
- `moves` has at least one move.
- Every workout has at least one set.
- If present, every set `lapCount` is at least `1`.
- Every set has at least one move.
- Every `move.moveId` exists in the top-level `moves` list.
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
  "schemaVersion": 4,
  "planId": "beginner-full-body",
  "name": "Beginner Full Body",
  "description": "Three-round beginner full body workout.",
  "author": "AI generated",
  "tags": ["beginner", "full-body"],
  "moves": [
    {
      "moveId": "bodyweight-squat",
      "name": "Bodyweight Squat",
      "description": "Squat using bodyweight only."
    },
    {
      "moveId": "plank",
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
              "workoutMoveId": "squat-12",
              "moveId": "bodyweight-squat",
              "type": "reps",
              "repCount": 12
            },
            {
              "workoutMoveId": "plank-30",
              "moveId": "plank",
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
