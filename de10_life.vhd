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
end entity de10_life;

architecture de10_life_arch of de10_life is
    signal pixel_color : std_logic_vector(11 downto 0);
    signal pixel_row_addr : integer range 0 to 479;
    signal pixel_col_addr : integer range 0 to 639;
begin
    vga_inst : entity work.vga
        generic map (
            SCALE => 1
        )
        port map (
            clk_25MHz => clk_50MHz,  -- Assuming clk_50MHz is divided down to 25MHz externally
            pixel_color => pixel_color,
            pixel_row_addr => pixel_row_addr,
            pixel_col_addr => pixel_col_addr,
            hsync => hsync,
            vsync => vsync,
            r_channel => r_channel,
            g_channel => g_channel,
            b_channel => b_channel
        );

end architecture de10_life_arch;