----------------------------------------------------------------------------------
-- Company: fffff
-- Engineer: 
-- 
-- Create Date: 2023/03/03 16:31:27
-- Design Name: 
-- Module Name: data_processer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.common_pack.all;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dataConsume is
port (
  clk:		in std_logic;
  reset:        in std_logic; -- synchronous reset
  start:  std_logic; -- goes high to signal data transfer
  numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
  ctrlIn: in std_logic;
  ctrlOut: out std_logic;
  data: in std_logic_vector(7 downto 0);
  dataReady: out std_logic;
  byte: out std_logic_vector(7 downto 0);
  seqDone: out std_logic;
  maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
  dataResults: out CHAR_ARRAY_TYPE(55 to 0); -- index 3 holds the peak
   binary_in : in std_logic_vector(11 downto 0);
           bcd_out : out std_logic_vector(39 downto 0)
  
  
);
end dataConsume;

Architecture dataflow of dataConsume is 
TYPE state_type IS (s0, s1, s2); 
SIGNAL curState, nextState: state_type;
SIGNAL data1, data2, data3 ,data4, data5, data6, data7, data8, data9, data10, data11 : std_logic_vector(7 downto 0);
SIGNAL N ,W, COUNT,y,numWords: integer range 0 to 31;
--SIGNAL maxIndex: BCD_ARRAY_TYPE(2 downto 0);
--SIGNAL INTconv: BCD_TO_INT(maxindex);
--SIGNAL outputbyte,datavalid : out std_logic;

BEGIN
  combi_nextState: PROCESS(curState)
    BEGIN
      CASE curState IS
      
        WHEN s0 =>
        
         if start = '0' then
        N <= 0;
        COUNT <= 0;
        nextState <= s1;
        end if;
        
         WHEN s1 =>
         
         if start = '0' then 
           nextState <= s1;
            if start = '1' then
            IF reset = '1' OR start='0'  THEN
                  curState <= s0;
                  N <= 0 ;
                  COUNT <= 0 ;
                  w <= 0 ;
                  END IF;
                  --converting the 12 bits from bcd to decimal
                  NumWords <= (to_integer(unsigned (numWords_bcd(2)))* 100) + (to_integer(unsigned(numWords_bcd(1)))* 10)+(to_integer(unsigned(numWords_bcd(0))));
                  W <= numWords;
            end if;
           end if;
          
          
         WHEN s2 =>
         
         if N > W then
         maxindex <= '1';
         --dataresult;  put together from d1 to d7 ; bcd (55 downto 0) e.g 55 to 47 is d1
         dataresult <= d1 (55 downto 47);
         dataresult <= d2 (47 downto 39);
         dataresult <= d3 (39 downto 31);
         dataresult <= d4 (31 downto 23);
         dataresult <= d5 (23 downto 15);
         dataresult <= d6 (15 downto 7);
         dataresult <= d7 (7 downto 0);         
              
         seqDone <= '1';
         if N < W then
         y <= 1;
         N <= N + 1;
         if ctrlIn = '0' then 
         nextState <= curstate;
         elsif ctrlIn = '1' then
         dataready <= '1'; 
         outputbyte <= '1'; 
         datavalid <= '1';
         nextState <= s1;
         end if;
         end if;
         end if;
   END CASE;
  END PROCESS;
