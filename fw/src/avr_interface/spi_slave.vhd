--! @file spi_slave.vhd
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

entity spi_slave is
  generic(
    G_CLK_FREQ_HZ : natural --! The system clock frequency in Hertz
  );
  port(
    CLK           : in  std_logic; --! The system clock input signal
    RST           : in  std_logic; --! The system reset input (active high)
    --
    MOSI          : in  std_logic; --! Master Out Slave In data signal
    MISO          : out std_logic; --! Master In Slave Out data signal
    SCLK          : in  std_logic; --! SPI clock signal
    SS            : in  std_logic; --! Slave select signal
    DONE          : out std_logic; --! Goes high for one clock cycle when a transaction has completed
    BYTE_TO_SEND  : in  std_logic_vector(7 downto 0); --! The byte to send in the next transaction
    RECEIVED_BYTE : out std_logic_vector(7 downto 0) --! The byte received in the latest transaction
  );
end spi_slave;

architecture behavioral of spi_slave is

  -----------
  -- Types --
  -----------

  type state_t is (
    st_idle,
    st_active
  );


  ---------------
  -- Constants --
  ---------------

  -------------
  -- Signals --
  -------------

  -- The initial states here is to prevent accidentally detecting a non-existent edge on the registered signal
  signal ss_d         : std_logic := '0';

  signal sclk_d       : std_logic;
  signal bit_counter  : natural range 0 to 7;
  signal data_in      : std_logic_vector(7 downto 0);
  signal data_out     : std_logic_vector(7 downto 0);

  signal state        : state_t := st_idle;
  signal byte_done    : std_logic := '0';

  -------------
  -- Aliases --
  -------------

begin

  -- This process implements a SPI slave device.  It first watches for a falling edge of the SS signal, indicating the
  -- start of transactions.  As long as SS is low, data will continue to be shifted out of the byte that has been placed
  -- on BYTE_TO_SEND.  After 8 bits have been sent, new data will be latched in from BYTE_TO_SEND and DONE will be
  -- asserted high for one clock cycle.  This repeats until SS goes high.  MOSI is sampled on the rising edge of SCLK,
  -- and MISO is updated on the falling edge of SCLK (SPI Mode 3).
  process(CLK)
  begin
    if(rising_edge(CLK)) then
      if(RST = '1') then

      else
        -- Register SCLK and SS for edge detection
        sclk_d  <= SCLK;
        ss_d    <= SS;

        -- Default state so it's only pulsed high for one clock cycle
        byte_done <= '0';
        DONE      <= '0';
        if(byte_done = '1') then
          DONE          <= '1';
          RECEIVED_BYTE <= data_in;
        end if;

        case(state) is
          when st_idle =>
            -- TODO: Hold MISO in high impedance while idle

            -- Watch for falling edge of SS while idle
            if(SS = '0' and ss_d = '1') then
              -- On falling edge of SS, move to the active state, setup byte to send and first bit of MISO
              state       <= st_active;
              bit_counter <= 7;
              MISO        <= BYTE_TO_SEND(7);
              data_out    <= BYTE_TO_SEND;
            end if;

          when st_active =>
            -- Continue in the active state as long as SS is held low
            if(SS = '0') then

              if(SCLK = '1' and sclk_d = '0') then
                -- Sample MOSI on rising edge of SCLK
                data_in(bit_counter) <= MOSI;

                -- Move to the next bit after each rising edge
                if(bit_counter = 0) then
                  -- If we just sent/received the last bit, move to the next byte
                  bit_counter <= 7;
                  byte_done <= '1';
                else
                  bit_counter <= bit_counter - 1;
                end if;
              elsif(SCLK = '0' and sclk_d = '1') then
                -- Setup MISO on falling edge of SCLK

                if(bit_counter = 7) then
                  data_out  <= BYTE_TO_SEND;
                  MISO      <= BYTE_TO_SEND(7);
                else
                  MISO <= data_out(bit_counter);
                end if;
              end if;
            else
              -- If SS went high, go back to the idle state
              state <= st_idle;

              -- TODO: assert error if transaction was aborted mid-byte
            end if;

          when others =>
            -- If we somehow get in a bad state, always go back to idle
            state <= st_idle;
        end case;


      end if;
    else
    end if;
  end process;

end behavioral;
