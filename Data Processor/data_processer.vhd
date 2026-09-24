                                                                      ----------------------------------------------------------------------------------
-- Company: 
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
  start: in std_logic; -- goes high to signal data transfer
  numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
  ctrlIn: in std_logic;
  ctrlOut: out std_logic;
  data: in std_logic_vector(7 downto 0);
  dataReady: out std_logic;
  byte: out std_logic_vector(7 downto 0);
  seqDone: out std_logic;
  maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
  dataResults: out CHAR_ARRAY_TYPE(0 to 6) -- index 3 holds the peak
);
end dataConsume;

architecture Behavioral of dataConsume is

TYPE state_type IS (s0, s1, s2, s3, s4,s5); 
SIGNAL curState, nextState: state_type; 
--SIGNAL dataGen: std_logic;
SIGNAL d1, d2, d3 ,d4, d5, d6, d7, b1, b2, b3, b4 : signed(7 downto 0); -- store internal variables, where d is the output and b represents back-up
SIGNAL COUNT, Num: integer ;                                --two counters Num (for number of works starting from 0), Count (for the sequence after peak) 
SIGNAL NumWordsDigit,VALUE, hundred, ten, unit: integer ;
SIGNAL Outctrl: std_ulogic; -- two phase protacal 
SIGNAL maxIndex_ready: BCD_ARRAY_TYPE(2 downto 0);                      --Signal for maxIndex before output

-------------------------------------------------------------------------------------------------------------------------
BEGIN
  combi_nextState: PROCESS(curState,start)
    BEGIN
      CASE curState IS
        WHEN s0 =>                                            --state 0 reset all counters
          nextState <= s1;
          Num<=0;
          COUNT<=0;

        WHEN s1 =>                                            --record the 
          IF Num = NumWordsDigit THEN
            nextState<= s5;
          END IF;
          
          IF start = '1' THEN 
            NumWordsDigit<=(to_integer(unsigned(numWords_bcd(2)))*100)+ (to_integer(unsigned(numWords_bcd(1))) * 10) + to_integer(unsigned(numWords_bcd(0)));
            nextState<= s2;
          ELSE 
            nextState<= s1;
          END IF;
          
        WHEN s2=>
          IF Num<NumWordsDigit Then
             Num<=Num+1;
             nextState<=s3;
          ELSIf Num = NumWordsDigit then
             nextState<=s5;
          END IF;
          
        WHEN s3=>
          nextState<=s4;
          
        WHEN s4=>
          IF ctrlin'EVENT THEN
            byte<=data;
            dataReady<='1'; 
            nextState<=s1;
          END IF ;  
          
        WHEN s5=>                  --output state
          dataResults(0)<= std_logic_vector(d1);
          dataResults(1)<= std_logic_vector(d2);
          dataResults(2)<= std_logic_vector(d3);
          dataResults(3)<= std_logic_vector(d4);
          dataResults(4)<= std_logic_vector(d5);
          dataResults(5)<= std_logic_vector(d6);
          dataResults(6)<= std_logic_vector(d7);
          maxIndex<=maxIndex_Ready;
          seqDone<='1';
          nextState<=s0;
        WHEN OTHERS => 
           nextState<= s0 ;
      END CASE;
  END PROCESS;
-------------------------------------------------------------------------------------------------------------------------  
  Peak_detecter: PROCESS(ctrlin, curState)     --Peak detector 
  
  BEGIN
    IF curState = s0 THEN      ---initialise all variables and signals
      d1<="00000000";
      d2<="00000000";
      d3<="00000000";
      d4<="00000000";
      d5<="00000000";
      d6<="00000000";
      d7<="00000000";
      b1<="00000000";
      b2<="00000000";
      b3<="00000000";
      b4<="00000000";
      COUNT<=0;
    END IF;
    
    IF ctrlin'EVENT THEN
      b4<=signed(data);          --back up the latest data and the previous datat for every new input data
      b3<=b4;
      b2<=b3;
      b1<=b2;
      
      
      IF b4>d4 THEN             --comparator to compare the latest data with the old peak
        d4<=b4;                 -- If the input is the new peak, store data from b(1-4) signals for the new peak and the 3 values before
        d3<=b3;
        d2<=b2;     
        d1<=b1;
        COUNT<=0;
      ELSIF b4<d4 THEN
      
        IF COUNT=0 THEN
          d5<=b4;
          COUNT <= COUNT+1;
        ELSIF COUNT=1 THEN
          d6<=b4;
          COUNT <= COUNT+1;
        ELSIF COUNT=2 THEN
          d7<=b4;
          COUNT <= COUNT+1;
        END IF;
        
      END IF;   
      
    END IF;

  END PROCESS;
-------------------------------------------------------------------------------------------------------------------------
  MaxIndex_converter: PROCESS(nextState)
  BEGIN
  VALUE<= to_integer(d4);
  hundred<= VALUE / 100;
  ten<= (VALUE mod 100) / 10;
  unit<= VALUE mod 10;
  
    IF VALUE >0 THEN
      maxIndex_ready(2)<= std_logic_vector(to_unsigned(hundred,4));
      maxIndex_ready(1)<= std_logic_vector(to_unsigned(ten,4));
      maxIndex_ready(0)<= std_logic_vector(to_unsigned(unit,4));
    ELSIF VALUE < 0 AND abs(VALUE) < 10 THEN
      maxIndex_ready(2)<=  "1000";
      maxIndex_ready(1)<=  "0000";
      maxIndex_ready(0)<= std_logic_vector(to_unsigned(unit,4));
    ELSIF VALUE < 0 AND abs(VALUE) < 100 THEN
      maxIndex_ready(2)<=  "1000";
      maxIndex_ready(1)<= std_logic_vector(to_unsigned(ten,4));
      maxIndex_ready(0)<= std_logic_vector(to_unsigned(unit,4));
    ELSIF VALUE < 0 AND abs(VALUE) > 100 THEN
      maxIndex_ready(2)<= std_logic_vector(to_signed(hundred,4));
      maxIndex_ready(1)<= std_logic_vector(to_unsigned(ten,4));
      maxIndex_ready(0)<= std_logic_vector(to_unsigned(unit,4));
    END IF;

    
    
    

  END PROCESS;  
-------------------------------------------------------------------------------------------------------------------------
  Generator_ctrl: PROCESS(start,curState)
  BEGIN
    IF curState =s0 THEN              ---initialise all variables and signals
      Outctrl<='0';
    END IF;
    IF curState=s3  THEN 
       IF Outctrl ='0' THEN
         Ctrlout<='1';
         Outctrl <='1';
       ELSIF Outctrl ='1' THEN
         Ctrlout<='0';
         Outctrl <='0';
       END IF;
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------------------------------------------------
  seq_state: PROCESS (clk, reset)
  BEGIN
    IF reset = '0'  THEN
      curState <= s0;
      
    ELSIF clk'EVENT AND clk='1'  THEN
      curState <= nextState;
      
    END IF;
  END PROCESS;
END;