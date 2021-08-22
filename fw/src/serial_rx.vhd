--! @file serial_rx.vhd
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

entity serial_rx is
  generic(
    G_CLK_FREQ_HZ : natural
  );
  port(
    CLK       : in  std_logic;
    RST       : in  std_logic;
    --
    RX        : in  std_logic;
    DATA      : out std_logic_vector(7 downto 0);
    NEW_DATA  : out std_logic
  );
end serial_rx;

architecture behavioral of serial_rx is

  -----------
  -- Types --
  -----------
  type state_t is (
    idle,
    wait_half,
    wait_full,
    wait_high
  );

  ---------------
  -- Constants --
  ---------------

  constant c_state_size : natural := 2;

  -------------
  -- Signals --
  -------------

  signal

  -------------
  -- Aliases --
  -------------

begin

  process()
  begin
  end process;

end behavioral;
