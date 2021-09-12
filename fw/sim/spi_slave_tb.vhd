--! @file spi_slave_tb.vhd
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

entity spi_slave_tb is
end spi_slave_tb;

architecture behavioral of spi_slave_tb is

  -----------
  -- Types --
  -----------

  ---------------
  -- Constants --
  ---------------

  constant c_clk_freq_hz        : natural := 50_000_000;
  constant c_clk_half_period_ns : time := 10 ns;
  constant c_sclk_period        : time := 1 us;
  constant c_sclk_half_period   : time := 500 ns;

  -------------
  -- Signals --
  -------------

  signal clk            : std_logic := '0';
  signal rst            : std_logic := '0';
  signal mosi           : std_logic := '0';
  signal miso           : std_logic;
  signal sclk           : std_logic := '1';
  signal ss             : std_logic := '1';
  signal done           : std_logic;
  signal byte_to_send   : std_logic_vector(7 downto 0) := (others => '0');
  signal received_byte  : std_logic_vector(7 downto 0);

  -------------
  -- Aliases --
  -------------

  -- component spi_slave
  -- port(
  --   CLK   : in  std_logic;
  --   RST   : in  std_logic;
  --   SS    : in  std_logic;
  --   MOSI  : in  std_logic;
  --   MISO  : out std_logic;
  --   SCK   : in  std_logic;
  --   DONE  : out std_logic;
  --   DIN   : in  std_logic_vector(7 downto 0);
  --   DOUT  : out std_logic_vector(7 downto 0)
  -- );
  -- end component spi_slave;

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
  uut_new : entity work.spi_slave
  generic map(
    G_CLK_FREQ_HZ => c_clk_freq_hz
  )
  port map(
    CLK           => clk,
    RST           => rst,
    MOSI          => mosi,
    MISO          => miso,
    SCLK          => sclk,
    SS            => ss,
    DONE          => done,
    BYTE_TO_SEND  => byte_to_send,
    RECEIVED_BYTE => received_byte
  );
  -- uut_orig : spi_slave
  -- port map(
  --   CLK   => clk,
  --   RST   => rst,
  --   SS    => ss,
  --   MOSI  => mosi,
  --   MISO  => miso,
  --   SCK   => sclk,
  --   DONE  => done,
  --   DIN   => byte_to_send,
  --   DOUT  => received_byte
  -- );

  -- Acts as the SPI master
  test_proc : process
  begin
    -- Wait an arbitrary delay
    wait for c_sclk_period;

    -- Slave should send 0xAA in the next transaction


    -- Set SS low
    byte_to_send <= x"AA";
    ss <= '0';

    -- Typical CS setup time
    wait for 5 ns;

    -- Send 8 bits to the slave (0xBB)
    -- 7
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 6
    mosi <= '0';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 5
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 4
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 3
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 2
    mosi <= '0';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 1
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 0
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;

    byte_to_send <= x"77";
    -- Send 8 bits to the slave (0x47)
    -- 7
    mosi <= '0';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 6
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 5
    mosi <= '0';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 4
    mosi <= '0';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 3
    mosi <= '0';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 2
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 1
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';
    wait for c_sclk_half_period;
    -- 0
    mosi <= '1';
    sclk <= '0';
    wait for c_sclk_half_period;
    sclk <= '1';

    -- Typical CS hold time
    wait for 8 ns;

    -- Set SS high
    ss <= '1';

    wait;
  end process test_proc;

end behavioral;
