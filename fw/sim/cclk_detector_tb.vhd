--! @file cclk_detector_tb.vhd
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
use ieee.math_real.all;

entity cclk_detector_tb is
end cclk_detector_tb;

architecture behavioral of cclk_detector_tb is

  -----------
  -- Types --
  -----------

  ---------------
  -- Constants --
  ---------------
  constant c_clk_freq_hz        : natural := 50_000_000;
  constant c_clk_half_period_ns : time := 10 ns;
  constant c_rst_release_delay  : time := 1 us;
  constant c_cclk_release_delay : time := 1 us;

  -------------
  -- Signals --
  -------------
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '0';
  signal cclk   : std_logic := '0';
  signal ready  : std_logic;

  -------------
  -- Aliases --
  -------------

begin

  -- Unit under test
  uut : entity work.cclk_detector
  generic map(
    G_CLK_FREQ_HZ => c_clk_freq_hz
  )
  port map(
    CLK   => clk,
    RST   => rst,
    CCLK  => cclk,
    READY => ready
  );

  -- Creates the system clock
  clk_proc : process
  begin
    wait for c_clk_half_period_ns;
    clk <= not clk;
  end process clk_proc;

  -- Releases cclk to simulate the AVR's behavior
  test_proc : process
  begin
    wait for c_cclk_release_delay;
    cclk <= '1';
    wait until ready = '1';
    wait;
  end process test_proc;

end behavioral;
