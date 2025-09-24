library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Entity to drive a 640x480 VGA display with a given pixel scale factor
entity vga is
    generic (
        SCALE : integer := 1  -- Pixel scale factor
    );

    port (
        clk_25MHz : in std_logic; -- 25 MHz clock input
        rst_n : in std_logic; -- Active low reset
        pixel_color : in std_logic_vector(11 downto 0); -- 12-bit pixel color input (4 bits each for R, G, B)
        pixel_row_addr : out integer range 0 to (480 / SCALE) - 1; -- Pixel row address output
        pixel_col_addr : out integer range 0 to (640 / SCALE) - 1; -- Pixel column address output
        hsync : out std_logic; -- Horizontal sync output
        vsync : out std_logic; -- Vertical sync output
        r_channel : out std_logic_vector(3 downto 0); -- 4-bit red channel output
        g_channel : out std_logic_vector(3 downto 0); -- 4-bit green channel output
        b_channel : out std_logic_vector(3 downto 0)  -- 4-bit blue channel output
    );
end entity;

architecture vga_arch of vga is
    type state_t is (
        ACTIVE, FRONT_PORCH, SYNC_PULSE, BACK_PORCH
    );

    -- Constants for VGA timing
    constant H_ACTIVE : integer := 640;
    constant H_FRONT_PORCH : integer := 16;
    constant H_SYNC_PULSE : integer := 96;
    constant H_BACK_PORCH : integer := 48;
    constant H_TOTAL : integer := H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

    constant V_ACTIVE : integer := 480;
    constant V_FRONT_PORCH : integer := 11;
    constant V_SYNC_PULSE : integer := 2;
    constant V_BACK_PORCH : integer := 31;
    constant V_TOTAL : integer := V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    -- Internal registers and signals
    signal h_state : state_t := ACTIVE;
    signal v_state : state_t := ACTIVE;
    
    -- 
    signal h_pixel_counter : integer range 0 to (640 / SCALE) - 1 := 0;
    signal v_pixel_counter : integer range 0 to (480 / SCALE) - 1 := 0;

    -- -- Keeps track of how long we've been in the current state
    -- signal h_state_counter : integer range 0 to H_TOTAL - 1 := 0;
    -- signal v_state_counter : integer range 0 to V_TOTAL - 1 := 0;
begin

    -- Process to handle the state information for horizontal and vertical timing
    process(clk_25MHz, rst_n)
        variable h_state_counter : integer range 0 to H_TOTAL - 1 := 0;
        variable v_state_counter : integer range 0 to V_TOTAL - 1 := 0;
    begin
        if rst_n = '0' then
            h_state_counter := 0;
            v_state_counter := 0;
        elsif rising_edge(clk_25MHz) then
            h_state_counter := h_state_counter + 1;

            -- Handle overflow of horizontal counter
            if h_state_counter = H_TOTAL then
                h_state_counter := 0;
                v_state_counter := v_state_counter + 1;
            end if;

            -- Handle overflow of vertical counter
            if v_state_counter = V_TOTAL then
                v_state_counter := 0;
            end if;
        end if;

        -- Update horizontal state
        if h_state_counter < H_ACTIVE then
            h_state <= ACTIVE;
        elsif h_state_counter < H_ACTIVE + H_FRONT_PORCH then
            h_state <= FRONT_PORCH;
        elsif h_state_counter < H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE then
            h_state <= SYNC_PULSE;
        else
            h_state <= BACK_PORCH;
        end if;

        -- Update vertical state
        if v_state_counter < V_ACTIVE then
            v_state <= ACTIVE;
        elsif v_state_counter < V_ACTIVE + V_FRONT_PORCH then
            v_state <= FRONT_PORCH;
        elsif v_state_counter < V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE then
            v_state <= SYNC_PULSE;
        else
            v_state <= BACK_PORCH;
        end if;

        -- Update pixel counters during active display period
        if h_state_counter < H_ACTIVE then
            h_pixel_counter <= h_state_counter / SCALE;
        else
            h_pixel_counter <= 0;
        end if;

        if v_state_counter < V_ACTIVE then
            v_pixel_counter <= v_state_counter / SCALE;
        else
            v_pixel_counter <= 0;
        end if;
    end process;


    process(all)
    begin
        -- Output logic for row/column addresses and color channels
        if h_state = ACTIVE and v_state = ACTIVE then
            pixel_row_addr <= v_pixel_counter;
            pixel_col_addr <= h_pixel_counter;
            r_channel <= pixel_color(11 downto 8);
            g_channel <= pixel_color(7 downto 4);
            b_channel <= pixel_color(3 downto 0);
        else 
            pixel_row_addr <= 0;
            pixel_col_addr <= 0;
            r_channel <= (others => '0');
            g_channel <= (others => '0');
            b_channel <= (others => '0');
        end if;

        if h_state = SYNC_PULSE then
            hsync <= '0';
        else
            hsync <= '1';
        end if;

        if v_state = SYNC_PULSE then
            vsync <= '0';
        else
            vsync <= '1';
        end if;
    end process;

end architecture;