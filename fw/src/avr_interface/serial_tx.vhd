--! @file serial_tx.vhd
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

entity serial_tx is
  generic(
    G_CLK_FREQ_HZ   : natural; --! The system clock frequency in Hertz
    G_BAUD_RATE_BPS : natural --! The serial baud rate in bits per second
  );
  port(
    CLK       : in  std_logic; --! The system clock input signal
    RST       : in  std_logic; --! The system reset input (active high)
    --
    TX        : out std_logic; --! The transmitted serial UART data
    TX_BLOCK  : in  std_logic; --! Flag indicating to ignore any new data.  Does not halt in-progress transmissions.
    BUSY      : out std_logic; --! Flag indicating when a transmission is in progress. Active high.
    DATA      : in  std_logic_vector(7 downto 0); --! The input data to serialize
    NEW_DATA  : in  std_logic --! Flag indicating that new data has been placed on @p DATA
  );
end serial_tx;

architecture behavioral of serial_tx is

  -----------
  -- Types --
  -----------

  type state_t is (
    st_idle,
    st_start_bit,
    st_data_bit,
    st_stop_bit
  );

  ---------------
  -- Constants --
  ---------------

    -- Period and half-period of a serial bit in terms of system clock periods (number of clks per bit)
    constant c_bit_period_clks : natural := natural(ceil(real(G_CLK_FREQ_HZ)/real(G_BAUD_RATE_BPS))) - 1;

  -------------
  -- Signals --
  -------------

  signal bit_counter  : natural range 0 to c_bit_period_clks;
  signal bit_index    : natural range 0 to DATA'length-1;
  signal state        : state_t := st_idle;
  signal data_d       : std_logic_vector(DATA'length-1 downto 0);

  -------------
  -- Aliases --
  -------------

begin

  transmit_proc : process(CLK)
  begin
    if(rising_edge(CLK)) then
      if(RST = '1') then
        BUSY        <= '1';
        TX          <= '1';
        state       <= st_idle;
      else
        case(state) is
          when st_idle =>
            -- Default to not busy in the idle state
            BUSY  <= '0';
            TX    <= '1';

            if(TX_BLOCK = '1') then
              -- Block new transmissions if TX_BLOCK is high
              BUSY <= '1';
            elsif(NEW_DATA = '1') then
              -- If new data is available, latch in the data, indicate busy, and go to the start bit state.  Load the
              -- counter for one bit period.
              state       <= st_start_bit;
              data_d      <= DATA;
              BUSY        <= '1';
              bit_counter <= c_bit_period_clks;
            end if;

          when st_start_bit =>
            if(bit_counter = 0) then
              -- If the bit period has finished, reload the counter and move to the data bit state (start at bit 0)
              bit_counter <= c_bit_period_clks;
              bit_index   <= 0;
              state       <= st_data_bit;
            else
              -- Otherwise, keep decrementing the counter
              bit_counter <= bit_counter - 1;
            end if;

          when st_data_bit =>
            -- Always place the next bit on the line
            TX <= data_d(bit_index);

            if(bit_counter = 0) then
              -- Always reload the counter when it expires
              bit_counter <= c_bit_period_clks;

              -- Check to see what we need to do based on which bit was just sent
              if(bit_index = (DATA'length-1)) then
                -- If the last bit was just sent, move to the stop bit state
                state <= st_stop_bit;
              else
                -- Otherwise, move to the next bit
                bit_index <= bit_index + 1;
              end if;
            else
              -- Otherwise, keep decrementing
              bit_counter <= bit_counter - 1;
            end if;

          when st_stop_bit =>
            -- STOP bit is high
            TX <= '1';

            if(bit_counter = 0) then
              -- If the counter is done, move back to the idle state
              state <= st_idle;
            else
              -- Otherwise, keep decrementing
              bit_counter <= bit_counter - 1;
            end if;

          when others =>
            -- If we somehow get in a bad state, always go back to idle
            state <= st_idle;
        end case;
      end if;
    end if;
  end process transmit_proc;

end behavioral;
