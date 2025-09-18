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
        pixel_color : in std_logic_vector(11 downto 0); -- 12-bit pixel color input (4 bits each for R, G, B)
        pixel_row_addr : out integer range 0 to (480 / SCALE) - 1; -- Pixel row address output
        pixel_col_addr : out integer range 0 to (640 / SCALE) - 1; -- Pixel column address output
        hsync : out std_logic; -- Horizontal sync output
        vsync : out std_logic; -- Vertical sync output
        r_channel : out std_logic_vector(3 downto 0); -- 4-bit red channel output
        g_channel : out std_logic_vector(3 downto 0); -- 4-bit green channel output
        b_channel : out std_logic_vector(3 downto 0)  -- 4-bit blue channel output
    );
end entity vga;

architecture vga_arch of vga is
    type state_t is (
        ACTIVE, FRONT_PORCH, SYNC_PULSE, BACK_PORCH
    );

    -- Constants for VGA timing

    -- Internal registers and signals
    signal h_state : state_t := ACTIVE;
    signal v_state : state_t := ACTIVE;

    -- Keeps track of how long we've been in the current state
    signal h_state_counter : integer := 0;
    signal v_state_counter : integer := 0;

    -- Used to handle the pixel scaling
    signal h_subpixel_count : integer range 0 to SCALE - 1 := 0;
    signal v_subpixel_count : integer range 0 to SCALE - 1 := 0;

    signal h_pixel_addr : integer range 0 to (640 / SCALE) - 1 := 0;
    signal v_pixel_addr : integer range 0 to (480 / SCALE) - 1 := 0;
begin

    process(clk_25MHz) is 
        variable vertical_tick : boolean := false;
    begin

        if rising_edge(clk_25MHz) then
            -- Horizontal state machine
            
            case h_state is
                when ACTIVE =>
                    -- Active time is 640 ticks
                    if h_state_counter = 640 - 1 then
                        h_state <= FRONT_PORCH;
                        h_state_counter <= 0;
                        h_pixel_addr <= 0;
                        h_subpixel_count <= 0;
                    else
                        -- Update the pixel index
                        h_state_counter <= h_state_counter + 1;
                        if h_subpixel_count = SCALE - 1 then
                            h_pixel_addr <= h_pixel_addr + 1;
                            h_subpixel_count <= 0;
                        else
                            h_subpixel_count <= h_subpixel_count + 1;
                        end if;
                    end if;
                when FRONT_PORCH =>
                    -- Front porch is 16 ticks
                    if h_state_counter = 16 - 1 then
                        h_state <= SYNC_PULSE;
                        h_state_counter <= 0;
                    else
                        h_state_counter <= h_state_counter + 1;
                    end if;
                when SYNC_PULSE =>
                    -- Sync pulse is 96 ticks
                    if h_state_counter = 96 - 1 then
                        h_state <= BACK_PORCH;
                        h_state_counter <= 0;
                    else
                        h_state_counter <= h_state_counter + 1;
                    end if;
                when BACK_PORCH =>
                    -- Back porch is 48 ticks
                    if h_state_counter = 48 - 1 then
                        h_state <= ACTIVE;
                        h_state_counter <= 0;

                        -- We've completed a full horizontal scanline, so update vertical state machine
                        vertical_tick := true;
                    else
                        h_state_counter <= h_state_counter + 1;
                    end if;
            end case;

            -- Vertical state machine
            if vertical_tick then
                vertical_tick := false;
                case v_state is
                    when ACTIVE =>
                        -- Active time is 480 lines
                        if v_state_counter = 480 - 1 then
                            v_state <= FRONT_PORCH;
                            v_state_counter <= 0;
                            v_pixel_addr <= 0;
                            v_subpixel_count <= 0;
                        else
                            -- Update the pixel index
                            v_state_counter <= v_state_counter + 1;
                            if v_subpixel_count = SCALE - 1 then
                                v_pixel_addr <= v_pixel_addr + 1;
                                v_subpixel_count <= 0;
                            else
                                v_subpixel_count <= v_subpixel_count + 1;
                            end if;
                        end if;
                    when FRONT_PORCH =>
                        -- Front porch is 10 lines
                        if v_state_counter = 10 - 1 then
                            v_state <= SYNC_PULSE;
                            v_state_counter <= 0;
                        else
                            v_state_counter <= v_state_counter + 1;
                        end if;
                    when SYNC_PULSE =>
                        -- Sync pulse is 2 lines
                        if v_state_counter = 2 - 1 then
                            v_state <= BACK_PORCH;
                            v_state_counter <= 0;
                        else
                            v_state_counter <= v_state_counter + 1;
                        end if;
                    when BACK_PORCH =>
                        -- Back porch is 33 lines
                        if v_state_counter = 33 - 1 then
                            v_state <= ACTIVE;
                            v_state_counter <= 0;
                        else
                            v_state_counter <= v_state_counter + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    output_process : process(all) is
        variable r : std_logic_vector(3 downto 0) := (others => '0');
        variable g : std_logic_vector(3 downto 0) := (others => '0');
        variable b : std_logic_vector(3 downto 0) := (others => '0');

        variable h_r_temp : std_logic_vector(3 downto 0) := (others => '0');
        variable h_g_temp : std_logic_vector(3 downto 0) := (others => '0');
        variable h_b_temp : std_logic_vector(3 downto 0) := (others => '0');
        variable h_hsync_temp : std_logic := '1';
    begin
        -- Get the channel data from the pixel color input
        r := pixel_color(11 downto 8);
        g := pixel_color(7 downto 4);
        b := pixel_color(3 downto 0);

        -- Calculate what the outputs would be if this were an active horizontal scanline
        case h_state is
            when ACTIVE =>
                h_hsync_temp := '1';
                h_r_temp := r;
                h_g_temp := g;
                h_b_temp := b;
            when FRONT_PORCH =>
                h_hsync_temp := '1';
                h_r_temp := (others => '0');
                h_g_temp := (others => '0');
                h_b_temp := (others => '0');
            when SYNC_PULSE =>
                h_hsync_temp := '0';
                h_r_temp := (others => '0');
                h_g_temp := (others => '0');
                h_b_temp := (others => '0');
            when BACK_PORCH =>
                h_hsync_temp := '1';
                h_r_temp := (others => '0');
                h_g_temp := (others => '0');
                h_b_temp := (others => '0');
        end case;

        -- Now, if we're in an active vertical scanline, use the horizontal outputs to 
        -- drive the actual outputs. Otherwise, force everything to black.
        case v_state is
            when ACTIVE =>
                hsync <= h_hsync_temp;
                r_channel <= h_r_temp;
                g_channel <= h_g_temp;
                b_channel <= h_b_temp;
                vsync <= '1';
            when FRONT_PORCH =>
                hsync <= h_hsync_temp;
                r_channel <= (others => '0');
                g_channel <= (others => '0');
                b_channel <= (others => '0');
                vsync <= '1';
            when SYNC_PULSE =>
                hsync <= h_hsync_temp;
                r_channel <= (others => '0');
                g_channel <= (others => '0');
                b_channel <= (others => '0');
                vsync <= '0';
            when BACK_PORCH =>
                hsync <= h_hsync_temp;
                r_channel <= (others => '0');
                g_channel <= (others => '0');
                b_channel <= (others => '0');
                vsync <= '1';
        end case;
    end process;

    pixel_row_addr <= v_pixel_addr;
    pixel_col_addr <= h_pixel_addr;

end architecture;