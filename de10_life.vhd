library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity de10_life is 
    port (
        clk_50MHz : in std_logic;  -- 50 MHz clock input
        reset_n : in std_logic;     -- Active low reset input
        -- VGA output signals
        hsync : out std_logic;
        vsync : out std_logic;
        r_channel : out std_logic_vector(3 downto 0);
        g_channel : out std_logic_vector(3 downto 0);
        b_channel : out std_logic_vector(3 downto 0)
    );
end entity;

architecture de10_life_arch of de10_life is
    constant SCALE : integer := 10;  -- Pixel scale factor
    constant CELLS_X : integer := 64;  -- Number of cells in X direction
    constant CELLS_Y : integer := 48;  -- Number of cells in Y direction

    -- Various signals
    signal pixel_color : std_logic_vector(11 downto 0) := (others => '0');
    signal pixel_row_addr : integer range 0 to (480 / SCALE) - 1 := 0;
    signal pixel_col_addr : integer range 0 to (640 / SCALE) - 1 := 0;
    signal clk_25MHz : std_logic := '0';
begin
    process(clk_50MHz, reset_n)
    begin
        if reset_n = '0' then
            clk_25MHz <= '0';
        elsif rising_edge(clk_50MHz) then
            clk_25MHz <= not clk_25MHz;
        end if;
    end process;

    process(pixel_row_addr, pixel_col_addr)
        variable row : integer;
        variable col : integer;
        constant max_rows : integer := 480 / SCALE;
        constant max_cols : integer := 640 / SCALE;
    begin
        -- Map row from values between 0 to max_rows-1 to 0b0000 to 0b1111
        row := (pixel_row_addr * 16) / max_rows;
        col := (pixel_col_addr * 16) / max_cols;
        
        pixel_color(11 downto 8) <= std_logic_vector(to_unsigned(row mod 16, 4)); -- Red
        pixel_color(7 downto 4) <= std_logic_vector(to_unsigned(col mod 16, 4)); -- Green
        pixel_color(3 downto 0) <= std_logic_vector(to_unsigned((pixel_row_addr + pixel_col_addr) mod 16, 4)); -- Blue
    end process;

    vga_inst : entity work.vga
        generic map (
            SCALE => SCALE
        )
        port map (
            clk_25MHz => clk_25MHz,  -- Assuming clk_50MHz is divided down to 25MHz externally
            pixel_color => pixel_color,
            pixel_row_addr => pixel_row_addr,
            pixel_col_addr => pixel_col_addr,
            hsync => hsync,
            vsync => vsync,
            r_channel => r_channel,
            g_channel => g_channel,
            b_channel => b_channel,
            rst_n => reset_n    
        );

end architecture de10_life_arch;