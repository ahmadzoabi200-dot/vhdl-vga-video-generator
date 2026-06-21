# VHDL VGA/HDMI Video Generator

A VHDL VGA/HDMI video-signal generator targeting an Altera Cyclone FPGA that outputs a colour-bar test pattern and an animated image streamed from external SRAM.

---

## What it is / what it is NOT

**What it is:** this design *generates* a standard VGA/HDMI video output signal.  It produces sync pulses, pixel counters, background colour bars, and a 76 × 76-pixel animated image fetched from an external 16-bit SRAM.

**What it is NOT:** it does NOT capture, decode, or extract frames from any incoming video stream.  There is no video input, no frame buffer for incoming data, and no capture logic of any kind.

---

## Architecture

The project contains five RTL modules plus a vendor PLL IP:

| Module | Description |
|--------|-------------|
| `video_pack.vhd` | Shared constants package: VGA timing parameters, sync polarity, animation speed limits, push-button debounce thresholds, and image dimensions. |
| `timing_generator.vhd` | Generates H-sync and V-sync pulses together with running horizontal/vertical pixel counters; also issues a `next_image` pulse every N display frames to pace the animation, where N is adjustable via buttons (range 1–30). |
| `data_generator.vhd` | Paints a seven-stripe colour-bar background across the 640-pixel-wide active line; overlays a centred 76 × 76-pixel image read word-by-word from external SRAM, cycling through 24 stored frames; drives a 24-bit RGB output bus plus data-enable. |
| `push_button_if.vhd` | Synchronises a mechanical push-button to the clock domain and produces a single-cycle `press_out` pulse with auto-repeat after a configurable hold threshold. |
| `video_generator.vhd` | Top level: instantiates the four modules above plus the Altera PLL megafunction (`clock_generator`); drives all SRAM control signals in permanent read mode; routes HDMI TX signals. |

---

## VGA Timing — 640 × 480 @ 60 Hz (25.175 MHz pixel clock)

| Parameter | Horizontal (pixels) | Vertical (lines) |
|-----------|--------------------:|----------------:|
| Visible area | 640 | 480 |
| Front porch | 16 | 10 |
| Sync pulse | 96 | 2 |
| Back porch | 48 | 33 |
| **Total** | **800** | **525** |
| Sync active region start | 656 | 490 |
| Sync active region end | 752 | 492 |
| Sync polarity | active-low | active-low |

---

## I/O

### Inputs

| Port | Direction | Description |
|------|-----------|-------------|
| `CLK` | in | Board reference clock (fed to Altera PLL) |
| `RSTn` | in | Active-low asynchronous reset |
| `SW_ANIMATION_DIR` | in | `'0'` = forward through SRAM frames; `'1'` = reverse |
| `SW_IMAGE_ENA` | in | `'1'` = overlay SRAM image on display; `'0'` = colour bars only |
| `SW_INC` | in | Push-button: increase animation speed (fewer frames per update) |
| `SW_DEC` | in | Push-button: decrease animation speed (more frames per update) |

### Outputs — HDMI TX bus

| Port | Width | Description |
|------|-------|-------------|
| `HDMI_TX` | 24 bits | RGB pixel data (bits 23:16 = R, 15:8 = G, 7:0 = B) |
| `HDMI_TX_DE` | 1 bit | Data enable (high during visible area) |
| `HDMI_TX_HS` | 1 bit | Horizontal sync |
| `HDMI_TX_VS` | 1 bit | Vertical sync |
| `HDMI_TX_CLK` | 1 bit | Pixel clock (25.175 MHz, from PLL output) |

### External SRAM interface (read-only)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `SRAM_D` | inout | 16 bits | Data bus (driven by SRAM; tri-stated by FPGA) |
| `SRAM_A` | out | 18 bits | Address bus |
| `SRAM_CEn` | out | 1 bit | Chip enable (tied `'0'`) |
| `SRAM_OEn` | out | 1 bit | Output enable (tied `'0'`) |
| `SRAM_WEn` | out | 1 bit | Write enable (tied `'1'` — read-only) |
| `SRAM_UBn` | out | 1 bit | Upper byte enable (tied `'0'`) |
| `SRAM_LBn` | out | 1 bit | Lower byte enable (tied `'0'`) |

The SRAM holds 24 pre-loaded 76 × 76-pixel images packed at 2 pixels per 16-bit word (6 bits per pixel: 2 bits per channel, expanded through a 4-entry LUT to 8-bit output per channel).

---

## Build and simulation

### Synthesis — Altera Quartus

1. Open Quartus and target an Altera Cyclone device.
2. Add all files under `src/` to the project.
3. **Regenerate the `clock_generator` PLL megafunction** (ALTPLL or PLL Intel FPGA IP) configured for a 25.175 MHz output.  This IP file is intentionally *not* included in the repository; it is vendor-generated and must be created for your specific device and Quartus version.  The top-level component declaration expects ports `refclk`, `rst`, `outclk_0`, `locked`.
4. Set `video_generator` as the top-level entity.
5. Assign pins per your board's schematic and compile.

### Simulation — ModelSim

Two testbenches are provided in `tb/`:

```
tb/timing_generator_tb.vhd   — exercises timing_generator
tb/push_button_if_tb.vhd     — exercises push_button_if
```

Compile order:
```
vcom src/video_pack.vhd
vcom src/timing_generator.vhd
vcom tb/timing_generator_tb.vhd
vsim timing_generator_tb

vcom src/push_button_if.vhd
vcom tb/push_button_if_tb.vhd
vsim push_button_if_tb
```

---

## Limitations and notes

- **No testbench for `data_generator`** — simulation coverage is limited to `timing_generator` and `push_button_if`; `data_generator` has no testbench in this repository.
- The RTL uses the non-standard `ieee.std_logic_arith` and `ieee.std_logic_unsigned` libraries rather than the recommended `ieee.numeric_std`.  This is intentional for compatibility with the original toolflow but may require adjustment for strict IEEE-compliant simulators.
- The `clock_generator` PLL component is an Altera megafunction and is not portable to other vendors without replacement.

---

## Demo

<!-- Add a photo or video of the monitor output here -->

---

## License

MIT — see [LICENSE](LICENSE).
