LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity UART_RX_CTRL is
  port(
    rxD: in std_logic;  -- serial data in
    clk: in std_logic;  -- system clock
    reset: in std_logic;  -- synchronous reset
    rxdone: in std_logic;  -- data received signal
    ovErr: out std_logic;  -- overrun error
    framErr: out std_logic;  -- framing error
    dataReady: buffer std_logic;  -- data valid
    rxdata: out std_logic_vector(7 downto 0)  -- received data
    );
end entity;

architecture behavioral of UART_RX_CTRL is
  -- internal signal for state machine
  type state_type is (IDLE, START, DATA, STOP);
  signal state : state_type;
  -- internal counters
  signal bit_cnt : integer range 0 to 7 := 0;
  signal byte_cnt : integer range 0 to 255 := 0;
  
  -- internal data register
  signal rx_data : std_logic_vector(7 downto 0);
  
begin
  -- process for state machines
  process (clk, reset)
  begin
    if reset = '1' then  -- reset state machine and counters
      state <= IDLE;
      bit_cnt <= 0;
      byte_cnt <= 0;
    elsif rising_edge(clk) then
      case state is
        when IDLE =>  -- wait for start bit
          if rxD = '0' then
            state <= START;
            bit_cnt <= 0;
          end if;
        when START =>  -- receive data bits
          if bit_cnt < 8 then
            rx_data(bit_cnt) <= rxD;
            bit_cnt <= bit_cnt + 1;
          else  -- start bit and 8 data bits received
            state <= STOP;
          end if;
        when DATA =>  -- store received byte and set dataReady
          rxdata <= rx_data;
          dataReady <= '1';
          state <= IDLE;
          byte_cnt <= byte_cnt + 1;
        when STOP =>  -- check stop bit
          if rxD = '1' then
            state <= DATA;
          else  -- framing error
            framErr <= '1';
            state <= IDLE;
          end if;
      end case;
    end if;
  end process;
  
  -- set overrun error if previous byte not read
  ovErr <= '1' when (dataReady = '1' and rxdone = '0') else '0';

end behavioral;


  
  
  
      
                  
          
          
          
          
      
  
  
    
    
    
    

    
    
