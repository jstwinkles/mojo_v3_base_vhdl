--! @file mojo_v3.vhd
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
library work;

entity mojo_v3 is
  port(
    CLK         : in    std_logic;  --! Clock input (50 MHz)
    RST_N       : in    std_logic;  --! Reset input, active low
    --
    CCLK        : inout std_logic;  --! CCLK input from AVR.  High when AVR is ready.
    --
    SPI_MISO    : inout std_logic;  --! SPI Master In Slave Out
    SPI_SS      : inout std_logic;  --! SPI Slave Select
    SPI_MOSI    : inout std_logic;  --! SPI Master Out Slave In
    SPI_SCK     : inout std_logic;  --! SPI Clock
    --
    SPI_CHANNEL : inout std_logic_vector(3 downto 0); --! AVR ADC channel select
    --
    AVR_TX      : inout std_logic;  --! AVR Tx to FPGA Rx
    AVR_RX      : inout std_logic;  --! AVR Rx to FPGA Tx
    AVR_RX_BUSY : inout std_logic;  --! AVR Rx buffer full
    --
    SV1         : inout std_logic_vector(38 downto 0);  --! Connector SV1
    SV2         : inout std_logic_vector(45 downto 0)   --! Connector SV2
  );
end mojo_v3;

architecture behavioral of mojo_v3 is

  -----------
  -- Types --
  -----------

  ---------------
  -- Constants --
  ---------------

  constant c_clk_freq_hz : natural := 50_000_000;

  -------------
  -- Signals --
  -------------

  signal rst : std_logic;

  -------------
  -- Aliases --
  -------------

  alias led : std_logic_vector(7 downto 0) is SV2(45 downto 38);

begin

  -- Invert for active-high reset
  rst <= not RST_N;

end behavioral;
