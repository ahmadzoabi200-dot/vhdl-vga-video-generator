library ieee;
use ieee.std_logic_1164.all;
use work.video_pack.all;

entity timing_generator is
    generic(
        G_RESET_ACTIVE_VALUE : std_logic := '0'
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        inc_speed  : in  std_logic;
        dec_speed  : in  std_logic;
        h_sync     : out std_logic;
        v_sync     : out std_logic;
        h_cnt      : out integer range 0 to h_total-1;
        v_cnt      : out integer range 0 to v_total-1;
        next_image : out std_logic
    );
end timing_generator;

architecture behave of timing_generator is

    signal h_counter      : integer range 0 to h_total-1;
    signal v_counter      : integer range 0 to v_total-1;
    signal speed_cnt      : integer range 0 to max_speed_val-1 := 0;
    signal speed_val      : integer range min_speed_val to max_speed_val := initial_speed_val;
    signal v_sync_signal  : std_logic;
    signal v_sync_ff      : std_logic;

begin

    h_cnt  <= h_counter;
    v_cnt  <= v_counter;
    v_sync <= v_sync_signal;

    sync_gen : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            h_counter     <= 0;
            v_counter     <= 0;
            v_sync_signal <= c_sync_pol;
            h_sync        <= not c_sync_pol;
        elsif rising_edge(clk) then
            if h_counter = H_TOTAL - 1 then
                h_counter <= 0;
                if v_counter = V_TOTAL - 1 then
                    v_counter <= 0;
                else
                    v_counter <= v_counter + 1;
                end if;
                if (v_counter > v_start - 1) and (v_end > v_counter) then
                    v_sync_signal <= not c_sync_pol;
                else
                    v_sync_signal <= c_sync_pol;
                end if;
            else
                h_counter <= h_counter + 1;
            end if;

            if (h_counter > h_start - 1) and (h_end > h_counter) then
                h_sync <= c_sync_pol;
            else
                h_sync <= not c_sync_pol;
            end if;
        end if;
    end process;

    next_frame : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            next_image <= '0';
            speed_cnt  <= 0;
            speed_val  <= initial_speed_val;
            v_sync_ff  <= '0';
        elsif rising_edge(clk) then
            v_sync_ff <= v_sync_signal;

            if inc_speed = '1' then
                if speed_val = min_speed_val then
                    speed_val <= min_speed_val;
                else
                    speed_val <= speed_val - 1;
                end if;
            elsif dec_speed = '1' then
                if speed_val = max_speed_val then
                    speed_val <= max_speed_val;
                else
                    speed_val <= speed_val + 1;
                end if;
            end if;

            -- detect falling edge of v_sync (end of frame)
            if v_sync_signal = '0' and v_sync_ff = '1' then
                if speed_cnt >= speed_val - 1 then
                    next_image <= '1';
                    speed_cnt  <= 0;
                else
                    speed_cnt <= speed_cnt + 1;
                end if;
            else
                next_image <= '0';
            end if;
        end if;
    end process;

end behave;
