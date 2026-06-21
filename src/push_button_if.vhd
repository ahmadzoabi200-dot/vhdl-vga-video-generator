library ieee;
use ieee.std_logic_1164.all;
use work.video_pack.all;

entity push_button_if is
    generic(
        G_RESET_ACTIVE_VALUE  : std_logic := '0';
        G_BUTTON_NORMAL_STATE : std_logic := '1'
    );
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        sw_in     : in  std_logic;
        press_out : out std_logic
    );
end push_button_if;

architecture behave of push_button_if is

    -- counters for rising-edge events before and after the 2-second hold threshold
    signal clk_cnt        : integer range 0 to count_1m       := 0;
    signal clk_cnt2       : integer range 0 to count_1m_after := 0;
    signal pulse_cnt      : integer range 0 to pulse_count_1m := 0;
    signal pulse_cnt2     : integer range 0 to pulse_count_1m := 0;
    signal in_sync        : std_logic;

begin

    pulse_gen_process : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            press_out  <= '0';
            clk_cnt    <= 0;
            pulse_cnt  <= 0;
            clk_cnt2   <= 0;
            pulse_cnt2 <= 0;
        elsif rising_edge(clk) then
            in_sync <= sw_in;  -- synchronise input to clock domain

            if in_sync = '1' then
                if count_1m > clk_cnt then
                    clk_cnt <= clk_cnt + 1;
                    if pulse_count_1m > pulse_cnt then
                        pulse_cnt  <= pulse_cnt + 1;
                        press_out  <= '1';
                    else
                        press_out <= '0';
                        pulse_cnt <= pulse_count_1m;
                    end if;
                else
                    press_out <= '0';
                    pulse_cnt <= pulse_count_1m;
                end if;
            else
                clk_cnt <= count_1m;
                if count_1m_after > clk_cnt2 then
                    clk_cnt2 <= clk_cnt2 + 1;
                    if pulse_count_1m > pulse_cnt2 then
                        press_out  <= '1';
                        pulse_cnt2 <= pulse_cnt2 + 1;
                    else
                        press_out  <= '0';
                        pulse_cnt2 <= pulse_count_1m;
                    end if;
                else
                    clk_cnt2   <= 0;
                    pulse_cnt2 <= 0;
                end if;
            end if;
        end if;
    end process;

end behave;
