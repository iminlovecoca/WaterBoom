$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$sampleRoot = Join-Path $projectRoot "assets/water_balloons/v12_staging/samples"
$skinRoot = Join-Path $projectRoot "assets/water_balloons/skins"
$fallbackBurst = Join-Path $skinRoot "skin_001/pop_burst.png"

$samples = @(
    @{ Id = "skin_066"; Source = "aqua_classic_reforge"; Name = "Aqua Classic Reforge"; Theme = "basic_blue"; Rarity = "rare"; Price = 90000; Primary = "#40c8e8"; Secondary = "#8eeeff"; Outline = "#1a6080"; Motif = "bubbles"; Description = "Bóng nước xanh trong được làm lại với highlight mềm và gợn nước mượt"; Vfx = "water_default"; Burst = "blue_splash" },
    @{ Id = "skin_067"; Source = "moonlit_abyss"; Name = "Moonlit Abyss"; Theme = "deep_ocean"; Rarity = "epic"; Price = 160000; Primary = "#3023a6"; Secondary = "#5c8cff"; Outline = "#17145c"; Motif = "moonlit_wave"; Description = "Bóng nước xanh tím sâu với ánh trăng lạnh và gợn sóng đêm"; Vfx = "water_dark"; Burst = "blue_splash" },
    @{ Id = "skin_068"; Source = "starlight_aurora"; Name = "Starlight Aurora"; Theme = "aurora"; Rarity = "legendary"; Price = 220000; Primary = "#22c7d6"; Secondary = "#9df7e9"; Outline = "#1767a4"; Motif = "aurora_ribbon"; Description = "Bóng nước cực quang với dải sáng xanh lục lam chuyển động bên trong"; Vfx = "water_sparkle"; Burst = "blue_splash" },
    @{ Id = "skin_069"; Source = "watermelon_fresh"; Name = "Watermelon Fresh"; Theme = "fruit_water"; Rarity = "rare"; Price = 150000; Primary = "#3a9e3a"; Secondary = "#e84060"; Outline = "#1a5a1a"; Motif = "watermelon_seeds"; Description = "Bóng nước dưa hấu tươi với vỏ xanh, ruột đỏ và hạt đen"; Vfx = "water_default"; Burst = "green_splash" }
)

foreach ($sample in $samples) {
    $sourceDir = Join-Path $sampleRoot $sample.Source
    $targetDir = Join-Path $skinRoot $sample.Id
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    Copy-Item (Join-Path $sourceDir "icon_64.png") (Join-Path $targetDir "icon.png") -Force
    for ($frame = 0; $frame -lt 4; $frame++) {
        Copy-Item (Join-Path $sourceDir ("idle_{0}_128.png" -f $frame)) (Join-Path $targetDir ("idle_{0}.png" -f $frame)) -Force
    }
    # The current water-burst renderer is shared and does not read a per-skin
    # pop sprite yet. Keep the required runtime contract with the canonical
    # burst until bespoke burst art is authored for these four skins.
    Copy-Item $fallbackBurst (Join-Path $targetDir "pop_burst.png") -Force

    $framesText = @"
[gd_resource type="SpriteFrames" load_steps=6 format=3]

[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/$($sample.Id)/idle_0.png" id="1_idle0"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/$($sample.Id)/idle_1.png" id="2_idle1"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/$($sample.Id)/idle_2.png" id="3_idle2"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/$($sample.Id)/idle_3.png" id="4_idle3"]

[resource]
animations = [{
"frames": [{"duration": 1.0, "texture": ExtResource("1_idle0")}, {"duration": 1.0, "texture": ExtResource("2_idle1")}, {"duration": 1.0, "texture": ExtResource("3_idle2")}, {"duration": 1.0, "texture": ExtResource("4_idle3")}],
"loop": true,
"name": &"idle",
"speed": 5.0
}]
"@
    Set-Content -LiteralPath (Join-Path $targetDir "$($sample.Id)_frames.tres") -Value $framesText -Encoding utf8

    $definitionText = @"
[gd_resource type="Resource" script_class="WaterBalloonSkinDefinition" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/water_balloon/WaterBalloonSkinDefinition.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/$($sample.Id)/icon.png" id="2_icon"]
[ext_resource type="SpriteFrames" path="res://assets/water_balloons/skins/$($sample.Id)/$($sample.Id)_frames.tres" id="3_frames"]

[resource]
script = ExtResource("1_script")
id = &"$($sample.Id)"
display_name = "$($sample.Name)"
theme = "$($sample.Theme)"
motif = "$($sample.Motif)"
description = "$($sample.Description)"
rarity = "$($sample.Rarity)"
price = $($sample.Price)
vfx_profile = "$($sample.Vfx)"
burst_accent = "$($sample.Burst)"
icon = ExtResource("2_icon")
sprite_frames = ExtResource("3_frames")
"@
    Set-Content -LiteralPath (Join-Path $targetDir "$($sample.Id)_definition.tres") -Value $definitionText -Encoding utf8
}

Write-Output "Integrated $($samples.Count) v12 balloon samples into assets/water_balloons/skins."
