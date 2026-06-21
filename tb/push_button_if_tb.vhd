library ieee;
use ieee.std_logic_1164.all;
use work.video_pack.all;

entity push_button_if_tb is
end push_button_if_tb;

architecture test of push_button_if_tb is

    component push_button_if
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
    end component;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal sw_in     : std_logic := '1';
    signal press_out : std_logic;
    signal run       : std_logic := '1';

    constant clk_period : time := 40 ns;

begin

    dut : push_button_if
        port map(
            clk       => clk,
            rst       => rst,
            sw_in     => sw_in,
            press_out => press_out
        );

    clk_gen : process
    begin
        while run = '1' loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    rst   <= '1' after 50 ns;
    run   <= '0' after 3.5 sec;
    sw_in <= '0' after 4 sec;

end test;
