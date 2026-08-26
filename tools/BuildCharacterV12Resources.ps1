$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$root = Join-Path $projectRoot "assets\characters"
$resourceRoot = Join-Path $projectRoot "resources\characters"
$ids = @("boom_mascot","cloud_bunny","cocoa_otter","coral_diver","lime_dino","mint_sprout","red_rider","star_skater","sunny_mechanic")
$actions = [ordered]@{
    idle_down = 4; idle_left = 4; idle_right = 4; idle_up = 4
    walk_down = 8; walk_left = 8; walk_right = 8; walk_up = 8
    bubble = 6; rescued = 4; lose = 6; win = 6; die = 6; water_hit = 4
}

foreach ($id in $ids) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $textureIds = [ordered]@{}
    $nextId = 1
    foreach ($action in $actions.Keys) {
        for ($i = 0; $i -lt [int]$actions[$action]; $i++) {
            $key = "$action/$i"
            $textureIds[$key] = "${nextId}_tex"
            $nextId++
        }
    }
    $lines.Add(('[gd_resource type="SpriteFrames" load_steps={0} format=3]' -f $nextId))
    $lines.Add("")
    foreach ($action in $actions.Keys) {
        for ($i = 0; $i -lt [int]$actions[$action]; $i++) {
            $rid = $textureIds["$action/$i"]
            $path = "res://assets/characters/$id/v12_staging/runtime_frames/$action/$('{0:D3}' -f $i).png"
            $lines.Add(('[ext_resource type="Texture2D" path="{0}" id="{1}"]' -f $path, $rid))
        }
    }
    $lines.Add("")
    $lines.Add("[resource]")
    $lines.Add("animations = [")
    $actionIndex = 0
    foreach ($action in $actions.Keys) {
        $frameParts = [System.Collections.Generic.List[string]]::new()
        for ($i = 0; $i -lt [int]$actions[$action]; $i++) {
            $rid = $textureIds["$action/$i"]
            $frameParts.Add('{"duration": 1.0, "texture": ExtResource("' + $rid + '")}')
        }
        $loop = if ($action -in @("bubble")) { "true" } else { "false" }
        $speed = if ($action -like "idle_*") { "4.0" } elseif ($action -like "walk_*") { "10.0" } elseif ($action -eq "bubble") { "8.0" } else { "8.0" }
        $comma = if ($actionIndex -lt $actions.Count - 1) { "," } else { "" }
        $lines.Add("{")
        $lines.Add('"frames": [' + ($frameParts -join ",") + '],')
        $lines.Add('"loop": ' + $loop + ',')
        $lines.Add('"name": &"' + $action + '",')
        $lines.Add('"speed": ' + $speed)
        $lines.Add("}$comma")
        $actionIndex++
    }
    $lines.Add("]")
    $out = Join-Path $resourceRoot "${id}_frames_v12.tres"
    $lines -join "`n" | Set-Content -LiteralPath $out -Encoding UTF8
}
Write-Output "CHARACTER_V12_RESOURCES BUILT resources=$($ids.Count)"
