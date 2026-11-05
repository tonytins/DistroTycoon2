# Review Guide

Use this checklist when reviewing a change to Distro Tycoon 2. It is adapted from
[Hudini's review guide](https://github.com/tonytins/Hudini/blob/main/REVIEW.md), with checks
tailored to this game.

## Before reviewing

- Read the change description and the relevant code and tests.
- Identify the behavior the player should see or the problem the change addresses.
- Check available build, test, and CI results. Run `swift build` or `swift test` when the change or
  its verification warrants it, and report checks that could not be run.

## Review checklist

- Does the behavior match the stated intent, including empty, blank, and over-long input?
- Do the game's rules stay free of raylib and drawing, and can tests repeat anything random?
- Does a rule change keep the game playable? Look for choices that have become free or pointless,
  numbers that can run away, and values that can go below zero or overflow.
- Does input stop at the top layer? A click or key used by the menu bar or an open notice must not
  also reach the window under it.
- Does the screen work at the smallest window size, and after a resize?
- Is the layout in UIScript where the format allows it, and does the document load without ignored
  attributes?
- Are GPU resources loaded after `InitWindow` and released before `CloseWindow`? Does a failure to
  load report a clear error rather than crash?
- Does a change to saved or bundled data keep working with what already exists?
- Is game content fictional, with no real product names?
- Do focused tests cover the changed rules? Has the game been run when a screen changed?
- Are the README, `AGENTS.md`, and roadmap accurate after the change?

## Writing review comments

- Report concrete correctness, compatibility, reliability, game balance, or missing-test concerns.
  Don't block changes on personal style preferences.
- Make each comment specific, constructive, and actionable. Point to the smallest relevant location
  and explain the impact and a useful next step.
- Prioritize findings by impact:
  - **Blocking**: prevents the game from building or starting, or causes severe, unavoidable failure
    in normal play.
  - **High**: breaks a common interaction or makes the game unwinnable or trivially exploitable.
  - **Medium**: causes a limited but meaningful behavior, balance, or reliability issue.
  - **Low**: a small edge case or non-blocking improvement.
- If no actionable issues remain, say so and note any important checks that were not run.
