--! @file serial_rx.vhd
--!
--! @brief UART serial data receiver for the Mojo V3.  Captures data from the AVR serial interface.  Assumes 1 START
--! bit, 8 data bits, no parity, and 1 STOP bit.
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

entity serial_rx is
  generic(
    G_CLK_FREQ_HZ   : natural;  --! The system clock frequency in Hertz
    G_BAUD_RATE_BPS : natural   --! The serial baud rate in bits per second
  );
  port(
    CLK       : in  std_logic;  --! The system clock input signal
    RST       : in  std_logic;  --! The system reset input (active high)
    --
    RX        : in  std_logic;  --! The received serial UART data (idles high)
    DATA      : out std_logic_vector(7 downto 0); --! The latest UART data frame that has been sampled
    NEW_DATA  : out std_logic;  --! Indicates when new serial data is available. Pulsed high for one clock cycle.
    ERROR     : out std_logic   --! Indicates a framing error.  Stays high until a new frame is started.
  );
end serial_rx;

architecture behavioral of serial_rx is

  -----------
  -- Types --
  -----------
  type state_t is (
    st_idle,
    st_wait_bit,
    st_wait_stop
  );

  ---------------
  -- Constants --
  ---------------

  -- Period and half-period of a serial bit in terms of system clock periods (number of clks per bit)
  constant c_bit_period_clks        : natural := natural(ceil(real(G_CLK_FREQ_HZ)/real(G_BAUD_RATE_BPS))) - 1;
  constant c_bit_half_period_clks   : natural := c_bit_period_clks/2;
  constant c_bit_extra_period_clks  : natural := c_bit_period_clks + c_bit_half_period_clks;

  -------------
  -- Signals --
  -------------

  -- bit_counter goes up to 1.5 bit periods for sampling in the middle of a bit
  signal bit_counter  : natural range 0 to c_bit_extra_period_clks;
  signal state        : state_t := st_idle;
  signal rx_d         : std_logic := '0';
  signal data_l       : std_logic_vector(DATA'length-1 downto 0);
  signal bit_index    : natural range 0 to DATA'length-1;
  signal stop_err     : std_logic;

begin

  -- Process for detecting bits on the serial data line.  Waits in an idle state until the START bit is detected, then
  -- waits half of a bit period followed by a full bit period to sample the rx line in the middle of the bit.  It then
  -- waits an additional seven bit periods to collect a total of 8 data bits.  It then waits for the STOP bit and
  -- returns to the idle state.  At the end of each frame, the data is latched on the output and the new_data signal is
  -- asserted for one clock cycle.
  receive_proc : process(CLK)
  begin
    if(rising_edge(CLK)) then
      if(RST = '1') then
        NEW_DATA    <= '0';
        rx_d        <= '0';
        state       <= st_idle;
        ERROR       <= '0';
        DATA        <= (others => '0');
      else
        -- Always clear to 0 to make sure any assertion is only 1 clock period wide
        NEW_DATA <= '0';

        -- Register the serial bit input for edge detection
        rx_d <= RX;

        -- Case statement handling the sampling of the serial bits
        case(state) is
          when st_idle =>
            -- If a falling edge on the serial line is detected, start the sequence (START bit of UART 8n1)
            if(RX = '0' and rx_d = '1') then
              state       <= st_wait_bit;
              bit_counter <= c_bit_extra_period_clks;
              bit_index   <= 0;
              ERROR       <= '0';
              stop_err    <= '0';
            end if;

          when st_wait_bit =>
            if(bit_counter = 0) then
              -- If we've counted a full bit, sample it
              data_l(bit_index) <= RX;

              if(bit_index = DATA'length-1) then
                -- If this is the last bit, reload the counter and move to the next state
                bit_counter <= c_bit_period_clks;
                state       <= st_wait_stop;
              else
                -- Otherwise, reload the counter and move to the next bit
                bit_counter <= c_bit_period_clks;
                bit_index   <= bit_index + 1;
              end if;
            else
              -- Otherwise, decrement the counter
              bit_counter <= bit_counter - 1;
            end if;

          when st_wait_stop =>
            if((bit_counter = 0) and (stop_err = '1')) then
              -- If 1.5 periods have expired without seeing a STOP bit, assert an error and move to the idle state
              ERROR <= '1';
              state <= st_idle;
            elsif(bit_counter = 0 and (RX = '0')) then
              -- If the counter expired without seeing the STOP, go again for another 0.5 period just to make sure
              bit_counter <= c_bit_half_period_clks;
              stop_err    <= '1';
            elsif((bit_counter) = 0 and (RX = '1')) then
              -- Else if the STOP bit is seen, latch out the data and move to the idle state
              DATA      <= data_l;
              NEW_DATA  <= '1';
              state     <= st_idle;
            else
              -- Otherwise, decrement the counter
              bit_counter <= bit_counter - 1;
            end if;

          when others =>
            -- If we somehow get in a bad state, return to idle
            state <= st_idle;
        end case;
      end if;
    end if;
  end process receive_proc;

end behavioral;
