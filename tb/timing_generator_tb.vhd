library ieee;
use ieee.std_logic_1164.all;
use work.video_pack.all;

entity timing_generator_tb is
end timing_generator_tb;

architecture test of timing_generator_tb is

    component timing_generator
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
    end component;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal inc_speed  : std_logic := '0';
    signal dec_speed  : std_logic := '0';
    signal h_sync     : std_logic;
    signal v_sync     : std_logic;
    signal h_cnt      : integer range 0 to h_total-1;
    signal v_cnt      : integer range 0 to v_total-1;
    signal next_image : std_logic;
    signal run        : std_logic := '1';

    constant clk_period : time := 40 ns;

begin

    dut : timing_generator
        port map(
            clk        => clk,
            rst        => rst,
            inc_speed  => inc_speed,
            dec_speed  => dec_speed,
            h_sync     => h_sync,
            v_sync     => v_sync,
            h_cnt      => h_cnt,
            v_cnt      => v_cnt,
            next_image => next_image
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

    rst       <= '1' after 50 ns;
    run       <= '0' after 3.5 sec;
    inc_speed <= '0' after 4 sec;

end test;
