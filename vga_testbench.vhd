library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

-- Testbench for the VGA module
entity vga_testbench is
end entity vga_testbench;

architecture tb_arch of vga_testbench is

    -- Constants
    constant CLK_25MHz_PERIOD : time := 40 ns;  -- 25 MHz clock period
    constant PIXEL_SCALE : integer := 1;  -- Pixel scale factor for the VGA module

    -- Signals to connect to the VGA module
    signal clk_25MHz : std_logic := '0';
    signal pixel_color : std_logic_vector(11 downto 0) := (others => '0');
    signal pixel_row_addr : integer range 0 to (480 / PIXEL_SCALE) - 1;
    signal pixel_col_addr : integer range 0 to (640 / PIXEL_SCALE) - 1;
    signal hsync : std_logic;
    signal vsync : std_logic;
    signal r_channel : std_logic_vector(3 downto 0);
    signal g_channel : std_logic_vector(3 downto 0);
    signal b_channel : std_logic_vector(3 downto 0);
begin
    -- Instantiate the VGA module
    vga_inst : entity work.vga
        generic map (
            SCALE => PIXEL_SCALE
        )
        port map (
            clk_25MHz => clk_25MHz,
            pixel_color => pixel_color,
            pixel_row_addr => pixel_row_addr,
            pixel_col_addr => pixel_col_addr,
            hsync => hsync,
            vsync => vsync,
            r_channel => r_channel,
            g_channel => g_channel,
            b_channel => b_channel,
				rst_n => '1'
        );

    -- Clock generation process
    clk_process : process
    begin
        while true loop
            clk_25MHz <= '0';
            wait for CLK_25MHz_PERIOD / 2;
            clk_25MHz <= '1';
            wait for CLK_25MHz_PERIOD / 2;
        end loop;
    end process;

    -- Stimulus process to provide test inputs
    stimulus_process : process
    begin
        -- Wait for global reset to finish
        wait for 100 ns;

        -- Test pattern: Fill the screen with a color gradient
        for row in 0 to (480 / PIXEL_SCALE) - 1 loop
            for col in 0 to (640 / PIXEL_SCALE) - 1 loop
                pixel_color <= std_logic_vector(to_unsigned((row mod 16) * 256 + (col mod 16) * 16, 12));
                wait for CLK_25MHz_PERIOD;  -- Wait for one clock cycle
            end loop;
        end loop;

        -- End simulation after some time
        wait for 10 ms;
        assert false report "End of simulation" severity note;
        wait;
    end process;

end architecture tb_arch;
