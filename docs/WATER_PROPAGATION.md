# Water Propagation

`WaterGridPropagation.calculate_water_burst(origin_cell, water_power, grid)` is deterministic and pixel-independent. It returns center, cardinal ray entries, affected cells, and destroyed soft blocks.

- Invalid/hard cell: stop before entry and mark the previous segment as an end.
- Soft block: include/destroy that cell, render an end, then stop.
- Open/Water Balloon cell: include and continue until power is exhausted.

`WaterStreamRenderer` creates one independent 40×40 segment per cell: center, horizontal, vertical, four ends, or cross at overlapping streams. `WaterBalloonManager.active_water_cells` keeps gameplay hazard duration synchronized with the renderer fade.
