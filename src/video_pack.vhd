library ieee;
use ieee.std_logic_1164.all;

package video_pack is

    -- VGA 640x480 @ 60 Hz timing (25.175 MHz pixel clock)
    constant H_VA    : integer := 640;   -- horizontal visible area
    constant H_FP    : integer := 16;    -- horizontal front porch
    constant H_SYNC  : integer := 96;    -- horizontal sync pulse width
    constant H_BP    : integer := 48;    -- horizontal back porch
    constant H_TOTAL : integer := H_VA + H_FP + H_SYNC + H_BP;  -- 800

    constant V_VA    : integer := 480;   -- vertical visible area
    constant V_FP    : integer := 10;    -- vertical front porch
    constant V_SYNC  : integer := 2;     -- vertical sync pulse width
    constant V_BP    : integer := 33;    -- vertical back porch
    constant V_TOTAL : integer := V_VA + V_FP + V_SYNC + V_BP;  -- 525

    -- Aliases used in timing generator
    constant h_total : integer := H_TOTAL;
    constant v_total : integer := V_TOTAL;

    -- Sync pulse active region (within h/v counter)
    constant h_start : integer := H_VA + H_FP;             -- 656
    constant h_end   : integer := H_VA + H_FP + H_SYNC;    -- 752
    constant v_start : integer := V_VA + V_FP;             -- 490
    constant v_end   : integer := V_VA + V_FP + V_SYNC;    -- 492

    -- Sync polarity (active low for standard VGA)
    constant c_sync_pol : std_logic := '0';

    -- Animation speed (units: display frames between image updates)
    constant min_speed_val     : integer := 1;
    constant max_speed_val     : integer := 30;
    constant initial_speed_val : integer := 10;

    -- Push-button interface timing (at 25 MHz clock)
    -- count_1m      : hold-before-repeat threshold (~50 ms)
    -- count_1m_after: repeat rate after threshold (~5 ms)
    -- pulse_count_1m: output pulse width (1 clock cycle)
    constant count_1m       : integer := 1_250_000;
    constant count_1m_after : integer := 125_000;
    constant pulse_count_1m : integer := 1;

    -- On-screen image dimensions (pixels)
    constant c_image_size_h : integer := 76;
    constant c_image_size_v : integer := 76;

end package video_pack;
