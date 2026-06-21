library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.video_pack.all;

entity data_generator is
    generic(
        G_RESET_ACTIVE_VALUE : std_logic := '0'
    );
    port(
        clk           : in    std_logic;
        rst           : in    std_logic;
        NEXT_IMAGE    : in    std_logic;
        IMAGE_ENA     : in    std_logic;
        ANIMATION_DIR : in    std_logic;
        H_CNT         : in    integer range 0 to H_TOTAL-1;
        V_CNT         : in    integer range 0 to V_TOTAL-1;
        SRAM_D        : inout std_logic_vector(15 downto 0);
        SRAM_A        : out   std_logic_vector(17 downto 0);
        DATA_DE       : out   std_logic;
        HDMI_TX       : out   std_logic_vector(23 downto 0)
    );
end data_generator;

architecture behave of data_generator is

    type color_lut_type is array (0 to 3) of std_logic_vector(7 downto 0);
    constant color_lut : color_lut_type :=
        ("00000000", "00111111", "01111111", "11111111");

    -- Image window within the visible area (centred)
    constant c_image_start_h : integer := H_VA/2 - c_image_size_h/2;
    constant c_image_start_v : integer := V_VA/2 - c_image_size_v/2;
    constant c_image_end_h   : integer := c_image_start_h + c_image_size_h;
    constant c_image_end_v   : integer := c_image_start_v + c_image_size_v;

    signal image_pixel_num  : std_logic_vector(7 downto 0) := (others => '0');
    signal image_line_num   : std_logic_vector(7 downto 0) := (others => '0');
    signal image_num        : integer range 0 to 23 := 0;
    signal image_h_active   : std_logic;
    signal image_v_active   : std_logic;
    signal image_active     : std_logic;
    signal byte_select      : std_logic;
    signal r_data           : std_logic_vector(7 downto 0);
    signal g_data           : std_logic_vector(7 downto 0);
    signal b_data           : std_logic_vector(7 downto 0);
    signal SRAM_AS          : std_logic_vector(17 downto 0) := (others => '0');
    signal next_image_flag  : std_logic;

begin

    HDMI_TX(23 downto 16) <= r_data;
    HDMI_TX(15 downto  8) <= g_data;
    HDMI_TX( 7 downto  0) <= b_data;

    image_active <= image_h_active and image_v_active;

    SRAM_A <= SRAM_AS;
    SRAM_D <= (others => 'Z');  -- tri-state: SRAM drives the bus (read-only)

    -- DATA_DE: high during visible area
    data_enable : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            DATA_DE <= '1';
        elsif rising_edge(clk) then
            if H_VA - 1 >= H_CNT and V_VA - 1 >= V_CNT then
                DATA_DE <= '1';
            else
                DATA_DE <= '0';
            end if;
        end if;
    end process;

    -- Horizontal active window for image
    image_h_active_proc : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            image_h_active <= '0';
        elsif rising_edge(clk) then
            if H_CNT >= c_image_start_h - 1 and c_image_end_h - 1 >= H_CNT then
                image_h_active <= '1';
            else
                image_h_active <= '0';
            end if;
        end if;
    end process;

    -- Vertical active window for image
    image_v_active_proc : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            image_v_active <= '0';
        elsif rising_edge(clk) then
            if V_CNT >= c_image_start_v - 1 and c_image_end_v - 1 >= V_CNT then
                image_v_active <= '1';
            else
                image_v_active <= '0';
            end if;
        end if;
    end process;

    -- Background and SRAM pixel output
    background : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            r_data <= (others => '0');
            g_data <= (others => '0');
            b_data <= (others => '0');
        elsif rising_edge(clk) then
            if 79 >= H_CNT then                          -- red bar
                r_data <= color_lut(3);
                g_data <= color_lut(0);
                b_data <= color_lut(0);
            elsif 159 >= H_CNT and H_CNT >= 80 then     -- green bar
                r_data <= color_lut(0);
                g_data <= color_lut(3);
                b_data <= color_lut(0);
            elsif 239 >= H_CNT and H_CNT >= 160 then    -- black bar
                r_data <= color_lut(0);
                g_data <= color_lut(0);
                b_data <= color_lut(0);
            elsif 399 >= H_CNT and H_CNT >= 240 then    -- image zone
                if IMAGE_ENA = '0' then
                    if 319 >= H_CNT then
                        r_data <= color_lut(3);
                        g_data <= color_lut(3);
                        b_data <= color_lut(3);
                    else
                        r_data <= color_lut(0);
                        g_data <= color_lut(0);
                        b_data <= color_lut(0);
                    end if;
                else
                    if image_active = '1' then
                        if byte_select = '0' then
                            r_data <= color_lut(conv_integer(SRAM_D(1 downto 0)));
                            g_data <= color_lut(conv_integer(SRAM_D(3 downto 2)));
                            b_data <= color_lut(conv_integer(SRAM_D(5 downto 4)));
                        else
                            r_data <= color_lut(conv_integer(SRAM_D(7 downto 6)));
                            g_data <= color_lut(conv_integer(SRAM_D(9 downto 8)));
                            b_data <= color_lut(conv_integer(SRAM_D(11 downto 10)));
                        end if;
                    else
                        if 319 >= H_CNT then
                            r_data <= color_lut(3);
                            g_data <= color_lut(3);
                            b_data <= color_lut(3);
                        else
                            r_data <= color_lut(0);
                            g_data <= color_lut(0);
                            b_data <= color_lut(0);
                        end if;
                    end if;
                end if;
            elsif 479 >= H_CNT and H_CNT >= 400 then    -- purple bar
                r_data <= color_lut(3);
                g_data <= color_lut(0);
                b_data <= color_lut(3);
            elsif 559 >= H_CNT and H_CNT >= 480 then    -- cyan bar
                r_data <= color_lut(0);
                g_data <= color_lut(3);
                b_data <= color_lut(3);
            elsif 639 >= H_CNT and H_CNT >= 560 then    -- white bar
                r_data <= color_lut(3);
                g_data <= color_lut(3);
                b_data <= color_lut(3);
            end if;
        end if;
    end process;

    -- SRAM address tracking: walk through image pixels while image_active
    SRAM_proc : process(clk, rst)
    begin
        if rst = G_RESET_ACTIVE_VALUE then
            image_pixel_num <= (others => '0');
            image_line_num  <= (others => '0');
            next_image_flag <= '0';
            if ANIMATION_DIR = '0' then
                image_num <= 0;
            else
                image_num <= 23;
            end if;
        elsif rising_edge(clk) then
            if NEXT_IMAGE = '1' then
                next_image_flag <= '1';
            end if;

            if next_image_flag = '1' then
                if ANIMATION_DIR = '0' then
                    if image_num < 23 then
                        image_num <= image_num + 1;
                    else
                        image_num <= 0;
                    end if;
                else
                    if image_num > 0 then
                        image_num <= image_num - 1;
                    else
                        image_num <= 23;
                    end if;
                end if;
                next_image_flag  <= '0';
                image_pixel_num  <= (others => '0');
                image_line_num   <= (others => '0');
            end if;

            if image_active = '1' then
                if conv_integer(image_pixel_num) < c_image_size_h - 1 then
                    image_pixel_num <= image_pixel_num + 1;
                else
                    image_pixel_num <= (others => '0');
                    if conv_integer(image_line_num) < c_image_size_v - 1 then
                        image_line_num <= image_line_num + 1;
                    else
                        image_line_num <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Compute SRAM word address from current pixel/line/frame position
    SRAM_AS <= conv_std_logic_vector(
        conv_integer(image_pixel_num(7 downto 1)) +
        conv_integer(image_line_num) * (c_image_size_h / 2) +
        image_num * (c_image_size_v * c_image_size_h / 2),
        18);

    byte_select <= image_pixel_num(0);

end behave;
