--! @file avr_interface.vhd
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

entity avr_interface is
  generic(
    G_CLK_FREQ_HZ : natural
    G_BAUD_RATE   : natural
  );
  port(
    CLK             : in  std_logic;
    RST             : in  std_logic;
    --
    CCLK            : in  std_logic;  --! cclk, or configuration clock is used when the FPGA is begin configured.
                                      --! The AVR will hold cclk high when it has finished initializing.
                                      --! It is important not to drive the lines connecting to the AVR
                                      --! until cclk is high for a short period of time to avoid contention.
    -- AVR SPI Signals
    SPI_MISO        : out std_logic;
    SPI_MOSI        : in  std_logic;
    SPI_SCK         : in  std_logic;
    SPI_SS          : in  std_logic;
    SPI_CHANNEL     : out std_logic_vector(3 downto 0);
    -- AVR Serial Signals
    TX              : out std_logic;
    RX              : in  std_logic;
    -- ADC Interface Signals
    CHANNEL         : in  std_logic;
    NEW_SAMPLE      : out std_logic;
    SAMPLE          : out std_logic_vector(3 downto 0);
    SAMPLE_CHANNEL  : out std_logic_vector(3 downto 0);
    -- Serial TX User Interface
    TX_DATA         : in  std_logic_vector(7 downto 0);
    NEW_TX_DATA     : in  std_logic;
    TX_BUSY         : out std_logic;
    TX_BLOCK        : in  std_logic;
    -- Serial Rx User Interface
    RX_DATA         : out std_logic_vector(7 downto 0);
    NEW_RX_DATA     : out std_logic
  );
end avr_interface;

architecture behavioral of avr_interface is

  -----------
  -- Types --
  -----------

  ---------------
  -- Constants --
  ---------------

  constant c_clks_per_bit : natural := natural(ceil(real(G_CLK_FREQ_HZ)/real(G_BAUD_RATE)));

  -------------
  -- Signals --
  -------------

  signal ready            : std_logic;
  signal n_rdy            : std_logic;
  signal spi_done         : std_logic;
  signal spi_dout         : std_logic_vector(7 downto 0);
  --
  signal tx_m             : std_logic;
  signal spi_miso_m       : std_logic;
  --
  signal byte_ct_d        : std_logic;
  signal byte_ct_q        : std_logic;
  signal sample_d         : std_logic_vector(9 downto 0);
  signal sample_q         : std_logic_vector(9 downto 0);
  signal new_sample_d     : std_logic;
  signal new_sample_q     : std_logic;
  signal sample_channel_d : std_logic_vector(3 downto 0);
  signal sample_channel_q : std_logic_vector(3 downto 0);
  signal block_d          : std_logic_vector(3 downto 0);
  signal block_q          : std_logic_vector(3 downto 0);
  signal busy_d           : std_logic;
  signal busy_q           : std_logic;

  -------------
  -- Aliases --
  -------------

begin

  -- cclk_detector is used to detect when cclk is high signaling when the AVR is ready
  cclk_detect_inst : entity work.cclk_detector
  generic map(
    G_CLK_FREQ_HZ => G_CLK_FREQ_HZ
  )
  port map(
    CLK   => CLK,
    RST   => RST,
    CCLK  => CCLK,
    READY => ready
  );

  spi_slave_inst : entity work.spi_slave
  port map(
    CLK   => CLK,
    RST   => n_rdy,
    SS    => SPI_SS,
    MOSI  => SPI_MOSI,
    MISO  => spi_miso_m,
    SCK   => SPI_SCK,
    DONE  => spi_done,
    DIN   => 16#FF#,
    DOUT  => spi_dout
  );

  serial_rx_inst : entity work.serial_rx
  generic map(
    G_CLKS_PER_BIT => c_clks_per_bit
  )
  port map(
    CLK       => CLK,
    RST       => n_rdy,
    RX        => RX,
    DATA      => RX_DATA,
    NEW_DATA  => NEW_RX_DATA
  );

  serial_tx_inst : entity work.serial_tx
  generic map(
    G_CLKS_PER_BIT => c_clks_per_bit
  )
  port map(
    CLK       => CLK,
    RST       => n_rdy,
    TX        => tx_m,
    BLOCK     => busy_q,
    BUSY      => TX_BUSY,
    DATA      => TX_DATA,
    NEW_DATA  => NEW_TX_DATA
  );

  -- Output declarations
  NEW_SAMPLE      <= new_sample_q;
  SAMPLE          <= sample_q;
  SAMPLE_CHANNEL  <= sample_channel_q;

  -- These signals connect to the AVR and should be Z when the AVR isn't ready
  SPI_CHANNEL     <= channel when ready = '1' else (others => 'Z');
  SPI_MISO        <= spi_miso_m when ((ready = '1') and (spi_ss = '0')) else 'Z';
  TX              <= tx_m when (ready = '1') else 'Z';

  -- TODO: Look for a better way to write this.  This non-clocked process comes straight from the original Verilog.
  process(byte_ct_q, sample_q, sample_channel_q, busy_q, block_q, TX_BUSY, NEW_TX_DATA, SPI_SS, spi_done)
  begin
    byte_ct_d         <= byte_ct_q;
    sample_d          <= sample_q;
    new_sample_d      <= '0';
    sample_channel_d  <= sample_channel_q;
    busy_d            <= busy_q;
    block_d           <= block_q(2 downto 0) & TX_BLOCK;

    if(block_q(3) xor block_q(2)) then
      busy_d <= '0';
    end if;

    if((TX_BUSY = '0') and (NEW_TX_DATA = '1')) then
      busy_d <= '1';
    end if;

    -- Device is not selected
    if(SPI_SS = '1') then
      byte_ct_d <= '0';
    end if;

    if(spi_done = '1') then -- sent/received data from SPI
      if(byte_ct_q = '0') then
        sample_d(7 downto 0)  <= spi_dout;  -- First byte is the 8 LSB of the sample
        byte_ct_d <= '1';
      else
        sample_d(9 downto 8)  <= spi_dout(1 downto 0);  -- second byte is the channel 2 MSB of the sample
        sample_channel_d  <= spi_dout(7 downto 4);  -- and the channel that was sampled
        byte_ct_d <= '1'; -- slave-select must be brought high before the next transfer
        new_sample_d  <= '1';
      end if;
    end if;
  end process;

  process(CLK)
  begin
    if(rising_edge(CLK)) then
      if(n_rdy = '1') then
        byte_ct_q     <= '0';
        sample_q      <= (others => '0');
        new_sample_q  <= '0';
      else
        byte_ct_q     <= byte_ct_d;
        sample_q      <= sample_d;
        new_sample_q  <= new_sample_d;
      end if;

      block_q           <= block_d;
      busy_q            <= busy_d;
      sample_channel_q  <= sample_channel_d;
    end if;
  end process;

end behavioral;