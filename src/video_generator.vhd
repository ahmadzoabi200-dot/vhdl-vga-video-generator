library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.video_pack.all;

entity video_generator is
    port(
        CLK            : in    std_logic;
        RSTn           : in    std_logic;
        SW_ANIMATION_DIR : in  std_logic;
        SW_INC         : in    std_logic;
        SW_DEC         : in    std_logic;
        SW_IMAGE_ENA   : in    std_logic;
        SRAM_D         : inout std_logic_vector(15 downto 0);
        SRAM_A         : out   std_logic_vector(17 downto 0);
        SRAM_CEn       : out   std_logic;
        SRAM_OEn       : out   std_logic;
        SRAM_UBn       : out   std_logic;
        SRAM_WEn       : out   std_logic;
        SRAM_LBn       : out   std_logic;
        HDMI_TX        : out   std_logic_vector(23 downto 0);
        HDMI_TX_DE     : out   std_logic;
        HDMI_TX_HS     : out   std_logic;
        HDMI_TX_VS     : out   std_logic;
        HDMI_TX_CLK    : out   std_logic
    );
end video_generator;

architecture behave of video_generator is

    -- Internal clock and PLL signals
    signal clk_sig      : std_logic;
    signal pll_rst      : std_logic := '0';
    signal locked_sig   : std_logic;

    -- Interconnect signals
    signal horizontal_cnt : integer range 0 to H_TOTAL-1;
    signal vertical_cnt   : integer range 0 to V_TOTAL-1;
    signal ni             : std_logic;   -- next_image pulse
    signal inc_sig        : std_logic;   -- increment speed press
    signal dec_sig        : std_logic;   -- decrement speed press
    signal hdmi_hs_sig    : std_logic;
    signal hdmi_vs_sig    : std_logic;

    -- Component declarations
    component clock_generator
        port(
            refclk  : in  std_logic;
            rst     : in  std_logic;
            outclk_0: out std_logic;
            locked  : out std_logic
        );
    end component;

begin

    -- u1 : data generator
    u1 : entity work.data_generator
        port map(
            clk           => clk_sig,
            rst           => RSTn,
            NEXT_IMAGE    => ni,
            IMAGE_ENA     => SW_IMAGE_ENA,
            ANIMATION_DIR => SW_ANIMATION_DIR,
            H_CNT         => horizontal_cnt,
            V_CNT         => vertical_cnt,
            SRAM_D        => SRAM_D,
            SRAM_A        => SRAM_A,
            DATA_DE       => HDMI_TX_DE,
            HDMI_TX       => HDMI_TX
        );

    -- u2 : timing generator
    u2 : entity work.timing_generator
        port map(
            clk        => clk_sig,
            rst        => RSTn,
            dec_speed  => dec_sig,
            inc_speed  => inc_sig,
            h_sync     => hdmi_hs_sig,
            v_sync     => hdmi_vs_sig,
            h_cnt      => horizontal_cnt,
            v_cnt      => vertical_cnt,
            next_image => ni
        );

    HDMI_TX_HS <= hdmi_hs_sig;
    HDMI_TX_VS <= hdmi_vs_sig;

    -- u3 : push button for increment speed
    u3 : entity work.push_button_if
        port map(
            clk       => clk_sig,
            rst       => RSTn,
            sw_in     => SW_INC,
            press_out => inc_sig
        );

    -- u4 : push button for decrement speed
    u4 : entity work.push_button_if
        port map(
            clk       => clk_sig,
            rst       => RSTn,
            sw_in     => SW_DEC,
            press_out => dec_sig
        );

    -- u5 : PLL / clock generator
    u5 : clock_generator
        port map(
            refclk   => CLK,
            rst      => pll_rst,
            outclk_0 => clk_sig,
            locked   => locked_sig
        );

    HDMI_TX_CLK <= clk_sig;

    -- SRAM always in read mode
    SRAM_CEn <= '0';
    SRAM_OEn <= '0';
    SRAM_WEn <= '1';
    SRAM_UBn <= '0';
    SRAM_LBn <= '0';

end behave;
