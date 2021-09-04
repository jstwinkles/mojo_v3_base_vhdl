--! @file serial_tx_tb.vhd
--!
--! @brief
--!
--! @copyright 2021 jstwinkles
--!
--! This program is free software: you can redistribute it and/or modify
--! it under the terms of the GNU General Public License as published by
--! the Free Software Foundation, either version 3 of the License, or
--! (at your option) any later version.
--!
--! This program is distributed in the hope that it will be useful,
--! but WITHOUT ANY WARRANTY; without even the implied warranty of
--! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--! GNU General Public License for more details.
--!
--! You should have received a copy of the GNU General Public License
--! along with this program.  If not, see <https://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;

entity serial_tx_tb is
end serial_tx_tb;

architecture behavioral of serial_tx_tb is

  -----------
  -- Types --
  -----------

  ---------------
  -- Constants --
  ---------------
  constant c_clk_freq_hz        : natural := 50_000_000;
  constant c_clk_half_period_ns : time := 10 ns;
  constant c_baud_rate_bps      : natural := 500_000;
  constant c_baud_period        : time := 2 us;

  -------------
  -- Signals --
  -------------
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '0';
  signal tx       : std_logic;
  signal tx_block : std_logic := '0';
  signal busy     : std_logic;
  signal data     : std_logic_vector(7 downto 0) := (others => '0');
  signal new_data : std_logic := '0';

  -------------
  -- Aliases --
  -------------

begin

  -- Creates the system clock
  clk_proc : process
  begin
    clk <= '0';
    wait for c_clk_half_period_ns;
    clk <= '1';
    wait for c_clk_half_period_ns;
  end process clk_proc;

  -- Unit under test
  uut : entity work.serial_tx
  generic map(
    G_CLK_FREQ_HZ => c_clk_freq_hz,
    G_BAUD_RATE_BPS => c_baud_rate_bps
  )
  port map(
    CLK       => clk,
    RST       => rst,
    TX        => tx,
    TX_BLOCK  => tx_block,
    BUSY      => busy,
    DATA      => data,
    NEW_DATA  => new_data
  );

  -- Places data on the transmit serial line
  test_proc : process
  begin
    -- Hold reset
    rst <= '1';
    wait for c_baud_period;
    rst <= '0';
    wait for c_baud_period;

    -- Provide new data to the UUT
    data      <= x"A5";
    new_data  <= '1';
    wait until busy = '1';
    new_data  <= '0';

    wait;
  end process test_proc;

end behavioral;
