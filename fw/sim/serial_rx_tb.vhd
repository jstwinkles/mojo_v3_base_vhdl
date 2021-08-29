--! @file serial_rx_tb.vhd
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

entity serial_rx_tb is
end serial_rx_tb;

architecture behavioral of serial_rx_tb is

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
  signal rx       : std_logic := '1';
  signal data     : std_logic_vector(7 downto 0);
  signal new_data : std_logic;
  signal error    : std_logic;

  -------------
  -- Aliases --
  -------------

begin

  -- Unit under test
  uut : entity work.serial_rx
  generic map(
    G_CLK_FREQ_HZ   => c_clk_freq_hz,
    G_BAUD_RATE_BPS => c_baud_rate_bps
  )
  port map(
    CLK       => clk,
    RST       => rst,
    RX        => rx,
    DATA      => data,
    NEW_DATA  => new_data,
    ERROR     => error
  );

  -- Creates the system clock
  clk_proc : process
  begin
    clk <= '0';
    wait for c_clk_half_period_ns;
    clk <= '1';
    wait for c_clk_half_period_ns;
  end process clk_proc;

  -- Places data on the receive serial line
  test_proc : process
  begin

    -- Hold reset
    rst <= '1';
    wait for c_baud_period;
    rst <= '0';

    -- idle period followed by start bit
    rx <= '1';
    wait for c_baud_period;
    rx <= '0';
    wait for c_baud_period;

    -- 8 data bits 0xA5
    rx <= '1';
    wait for c_baud_period;
    rx <= '0';
    wait for c_baud_period;
    rx <= '1';
    wait for c_baud_period;
    rx <= '0';
    wait for c_baud_period;
    rx <= '0';
    wait for c_baud_period;
    rx <= '1';
    wait for c_baud_period;
    rx <= '0';
    wait for c_baud_period;
    rx <= '1';
    wait for c_baud_period;

    -- No parity

    -- 1 Stop bit
    rx <= '1';
    wait for c_baud_period;

    wait;
  end process test_proc;

end behavioral;
