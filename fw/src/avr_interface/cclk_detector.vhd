--! @file cclk_detector.vhd
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

entity cclk_detector is
  generic(
    G_CLK_FREQ_HZ : natural --!
  );
  port(
    CLK   : in  std_logic; --!
    RST   : in  std_logic; --!
    --
    CCLK  : in  std_logic; --!
    READY : out std_logic --!
  );
end cclk_detector;

architecture behavioral of cclk_detector is

  ---------------
  -- Constants --
  ---------------

  -- FPGA needs to wait until the CCLK signal is high for at least 512 cycles before taking control of its outputs
  constant c_count_max : natural := 3;

  -------------
  -- Signals --
  -------------

  signal count : natural range 0 to c_count_max := 0;

begin

  -- Process for asserting the READY signal.  When CCLK goes high, a counter is started.  When that counter reaches 512,
  -- READY will be asserted.  If CCLK goes low at any point, READY is deasserted and the counter is restarted.
  -- Asserting RST will have the same effect.
  process(CLK)
  begin
    if rising_edge(CLK) then
      if(RST = '1') then
        count <= c_count_max;
        READY <= '0';
      else
        if(CCLK = '0') then
          -- CCLK went low, so reset the counter and ready
          count <= c_count_max;
          READY <= '0';
        elsif(count = 0) then
          -- Counter done, so assert ready
          READY <= '1';
        else
          -- Still counting
          count <= count - 1;
        end if;
      end if;
    end if;
  end process;

end behavioral;
