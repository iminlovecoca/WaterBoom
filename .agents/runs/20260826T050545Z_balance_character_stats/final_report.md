# Agent automation report: balance_character_stats

- Status: **FAIL**
- Stop reason: fatal validator or safety error
- Iterations: 1
- Run ID: `20260826T050545Z_balance_character_stats`
- Git checkpoint: Git metadata captured

## Files changed

- `assets/water_balloons/v14_rebuild_new10_raw.png.import`
- `assets/water_balloons/v14_rebuild_new16_raw.png.import`
- `assets/water_balloons/v14_rebuild_new16_raw_magenta.png.import`
- `assets/water_balloons/v14_rebuild_new16_raw_transparent.png.import`
- `test_match_res.gd.uid`
- `test_match_res_direct.gd.uid`
- `test_match_res_mock.gd.uid`
- `test_match_unified.gd.uid`
- `tests/CharacterStatsBalanceSmoke.gd.uid`
- `tmp2_cloud_bunny_walk.png.import`
- `tmp2_cocoa_otter_walk.png.import`
- `tmp2_coral_diver_walk.png.import`
- `tmp2_lime_dino_walk.png.import`
- `tmp2_mint_sprout_walk.png.import`
- `tmp2_red_rider_walk.png.import`
- `tmp2_star_skater_walk.png.import`
- `tmp2_sunny_mechanic_walk.png.import`
- `tmp3_cloud_bunny_walk.png.import`
- `tmp3_cloud_walk_left.png.import`
- `tmp3_cloud_walk_right.png.import`
- `tmp3_cloud_walk_up.png.import`
- `tmp3_cocoa_otter_walk.png.import`
- `tmp3_coral_diver_walk.png.import`
- `tmp3_lime_dino_walk.png.import`
- `tmp3_mint_sprout_walk.png.import`
- `tmp3_red_rider_walk.png.import`
- `tmp3_star_skater_walk.png.import`
- `tmp3_sunny_mechanic_walk.png.import`
- `tmp4_cloud_bunny.png.import`
- `tmp4_coral_diver.png.import`
- `tmp5_cloud_bunny.png.import`
- `tmp5_coral_diver.png.import`
- `tmp5_mint_sprout.png.import`
- `tmp_bunny_big.png.import`
- `tmp_bunny_big2.png.import`
- `tmp_bunny_big3.png.import`
- `tmp_cloud_bunny_walk.png.import`
- `tmp_cocoa_otter_walk.png.import`
- `tmp_coral_diver_walk.png.import`
- `tmp_frame_10.png.import`
- `tmp_frame_7.png.import`
- `tmp_frame_8.png.import`
- `tmp_frame_9.png.import`
- `tmp_lime_dino_walk.png.import`
- `tmp_mint_sprout_walk.png.import`
- `tmp_red_rider_walk.png.import`
- `tmp_source_row0.png.import`
- `tmp_source_row1.png.import`
- `tmp_source_row2.png.import`
- `tmp_source_row3.png.import`
- `tmp_source_row4.png.import`
- `tmp_source_row5.png.import`
- `tmp_source_row6.png.import`
- `tmp_source_row7.png.import`
- `tmp_star_skater_walk.png.import`
- `tmp_sunny_mechanic_walk.png.import`

## Unresolved issues / root cause

- character_stats_smoke: exit 1
ERROR: res://resources/characters/sunny_mechanic_frames_v13.tres:175 - Parse Error: [ext_resource] referenced non-existent resource at: res://assets/characters/sunny_mechanic/v13_staging/runtime_frames/lose/004.png.
   at: _printerr (scene/resources/resource_format_text.cpp:41)
   GDScript backtrace (most recent call first):
       [0] _ready (res://tests/CharacterStatsBalanceSmoke.gd:15)
ERROR: res://resources/characters/sunny_mechanic_frames_v13.tres:175 - Parse Error: [ext_resource] referenced non-existent resource at: res://assets/characters/sunny_mechanic/v13_staging/runtime_frames/lose/005.png.
   at: _printerr (scene/resources/resource_format_text.cpp:41)
   GDScript backtrace (most recent call first):
       [0] _ready (res://tests/CharacterStatsBalanceSmoke.gd:15)
ERROR: CHARACTER_STATS_BALANCE_RESULT: 62 failed | aqua_pacifier.tres is not CharacterDefinition; aqua_pacifier_frames_v14.tres is not CharacterDefinition; boom_mascot max balloons=8; boom_mascot max power=8; boom_mascot max speed=280.0; boom_mascot_frames_v12.tres is not CharacterDefinition; boom_mascot_frames_v13.tres is not CharacterDefinition; cloud_bunny starts with 1 balloons; cloud_bunny max balloons=8; cloud_bunny max power=8; cloud_bunny max speed=280.0; cloud_bunny_frames_v12.tres is not CharacterDefinition; cloud_bunny_frames_v13.tres is not CharacterDefinition; cocoa_otter max balloons=8; cocoa_otter max power=8; cocoa_otter max speed=280.0; cocoa_otter_frames_v12.tres is not CharacterDefinition; cocoa_otter_frames_v13.tres is not CharacterDefinition; coral_diver max balloons=8; coral_diver max power=8; coral_diver max speed=280.0; coral_diver_frames_v12.tres is not CharacterDefinition; coral_diver_frames_v13.tres is not CharacterDefinition; lime_dino starts with 3 balloons; lime_dino max balloons=8; lime_dino max power=8; lime_dino max speed=280.0; lime_dino_frames_v12.tres is not CharacterDefinition; lime_dino_frames_v13.tres is not CharacterDefinition; mint_sprout starts with 1 balloons; mint_sprout max balloons=8; mint_sprout max power=8; mint_sprout max speed=280.0; mint_sprout_frames_v12.tres is not CharacterDefinition; mint_sprout_frames_v13.tres is not CharacterDefinition; red_rider max balloons=8; red_rider max power=8; red_rider max speed=280.0; red_rider_frames_v12.tres is not CharacterDefinition; red_rider_frames_v13.tres is not CharacterDefinition; shadow_ninja.tres is not CharacterDefinition; shadow_ninja_frames_v14.tres is not CharacterDefinition; star_skater starts with 1 balloons; star_skater max balloons=8; star_skater max power=8; star_skater max speed=280.0; star_skater_frames_v12.tres is not CharacterDefinition; star_skater_frames_v13.tres is not CharacterDefinition; sunny_mechanic max balloons=8; sunny_mechanic max power=8; sunny_mechanic max speed=280.0; sunny_mechanic_frames_v12.tres is not CharacterDefinition; sunny_mechanic_frames_v13.tres is not CharacterDefinition; expected 10 character definitions, got 31; MatchConfig default capacity=1; MatchConfig max capacity=8; MatchConfig max power=8; MatchConfig max speed=280.0; GameConstants default capacity=1; GameConstants max capacity=8; GameConstants max power=8; GameConstants max speed=280.0
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://tests/CharacterStatsBalanceSmoke.gd:57)
- safety: protected paths changed: assets/water_balloons/v14_rebuild_new10_raw.png.import, assets/water_balloons/v14_rebuild_new16_raw.png.import, assets/water_balloons/v14_rebuild_new16_raw_magenta.png.import, assets/water_balloons/v14_rebuild_new16_raw_transparent.png.import
- safety: files outside scope changed: assets/water_balloons/v14_rebuild_new10_raw.png.import, assets/water_balloons/v14_rebuild_new16_raw.png.import, assets/water_balloons/v14_rebuild_new16_raw_magenta.png.import, assets/water_balloons/v14_rebuild_new16_raw_transparent.png.import, test_match_res.gd.uid, test_match_res_direct.gd.uid, test_match_res_mock.gd.uid, test_match_unified.gd.uid, tests/CharacterStatsBalanceSmoke.gd.uid, tmp2_cloud_bunny_walk.png.import, tmp2_cocoa_otter_walk.png.import, tmp2_coral_diver_walk.png.import, tmp2_lime_dino_walk.png.import, tmp2_mint_sprout_walk.png.import, tmp2_red_rider_walk.png.import, tmp2_star_skater_walk.png.import, tmp2_sunny_mechanic_walk.png.import, tmp3_cloud_bunny_walk.png.import, tmp3_cloud_walk_left.png.import, tmp3_cloud_walk_right.png.import, tmp3_cloud_walk_up.png.import, tmp3_cocoa_otter_walk.png.import, tmp3_coral_diver_walk.png.import, tmp3_lime_dino_walk.png.import, tmp3_mint_sprout_walk.png.import, tmp3_red_rider_walk.png.import, tmp3_star_skater_walk.png.import, tmp3_sunny_mechanic_walk.png.import, tmp4_cloud_bunny.png.import, tmp4_coral_diver.png.import, tmp5_cloud_bunny.png.import, tmp5_coral_diver.png.import, tmp5_mint_sprout.png.import, tmp_bunny_big.png.import, tmp_bunny_big2.png.import, tmp_bunny_big3.png.import, tmp_cloud_bunny_walk.png.import, tmp_cocoa_otter_walk.png.import, tmp_coral_diver_walk.png.import, tmp_frame_10.png.import, tmp_frame_7.png.import, tmp_frame_8.png.import, tmp_frame_9.png.import, tmp_lime_dino_walk.png.import, tmp_mint_sprout_walk.png.import, tmp_red_rider_walk.png.import, tmp_source_row0.png.import, tmp_source_row1.png.import, tmp_source_row2.png.import, tmp_source_row3.png.import, tmp_source_row4.png.import, tmp_source_row5.png.import, tmp_source_row6.png.import, tmp_source_row7.png.import, tmp_star_skater_walk.png.import, tmp_sunny_mechanic_walk.png.import

## Screenshot evidence

- None collected

## Iteration evidence

- iteration 1: FAIL — `.agents/runs/20260826T050545Z_balance_character_stats/iteration_01/qa_result.json`
