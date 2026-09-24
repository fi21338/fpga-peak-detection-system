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
SIGNAL NumWordsDigit,VALUE, hundred, ten, unit,position: integer ;  --define different signals as integers 
SIGNAL Outctrl: std_ulogic; -- two phase protacal                                           -- a register for the ctrlin output
SIGNAL position_BCD: BCD_ARRAY_TYPE(2 downto 0);                      --Signal for maxIndex before output

-------------------------------------------------------------------------------------------------------------------------
BEGIN
  -- Comination of all states from s0 to s4, Mealy machine is used
  combi_nextState: PROCESS(curState,start,numWords_bcd,ctrlIn,NumWordsDigit,d1,d2,d3,d4,d5,d6,d7)
   
    BEGIN
      CASE curState IS
      
        --inital state
        WHEN s0 =>                                            --state 0 reset all counters and output signals
          nextState <= s1;
          dataReady<='0';
          seqDone<='0';
          Num<=0;
          Outctrl<='0';
          Ctrlout<='0';
          NumWordsDigit<=0;
          
        --start state   
        WHEN s1 =>

          dataReady<='0';                                    -- reset dataReady to 0 for every loop 
                     
          IF start = '1' THEN                                --only start when 1 from start is recieved
            
            NumWordsDigit<=(to_integer(unsigned(numWords_bcd(2)))*100)+ (to_integer(unsigned(numWords_bcd(1))) * 10) + to_integer(unsigned(numWords_bcd(0))); --assign the words in becd to a internal signal in digits
            IF Num<(NumWordsDigit)  Then                     -- compare the number of words recieved with the Num counter, 
                                                             --The num counter will run as much as it needed to reach the amount that the user required                
               
               Ctrlout<=Not Outctrl;                         --  They are the two phase communication protocals, where  Ctrlout outputs the reverse of itself
               Outctrl<=Not Outctrl;                                --and Outctrl stores the not value of the recent output
               nextState<=s2;
            ELSIf Num = (NumWordsDigit) then                 -- if Num counter is equal to NumWordsDigit, which means enough data is generated, therefore go tonext state
               nextState<=s3;
            END IF;
          ELSE 
            nextState<= s1;                                  --stays in state one if  start is not high
          END IF;
          
        --output state for data ready  
        WHEN s2=>
          IF rising_edge(ctrlin) THEN                               -- when ctrlin changes, it signals the input of data
            
            byte<=data;                                      -- output the current recieved data
            Num<=Num+1;                                      --increment the Num counter
            dataReady<='1';                                  -- output dataReady to command processor 
        
            nextState<=s1;                                   --goes back to state one until Num = NumwordsDigit
          END IF ;  
          
          IF falling_edge(ctrlin) THEN                               -- when ctrlin changes, it signals the input of data
            
            byte<=data;                                      -- output the current recieved data
            Num<=Num+1;                                      --increment the Num counter
            dataReady<='1';                                  -- output dataReady to command processor 
        
            nextState<=s1;                                   --goes back to state one until Num = NumwordsDigit
          END IF ;  
                
          
        --Delay state  
        WHEN s3=>                                            --extra state for one clock cycle before output to ensure the all data are stored
   
          nextState<=s4;
          
        --sequence done output state  
        WHEN s4=>                 
          seqDone<='1';
          nextState<=s0;                                     -- return to the initial state to get ready for next command
        
        -- Return state
        WHEN OTHERS =>                                       -- prevent glitching to other state and enables the system to initialize
           nextState<= s0 ;
      END CASE;
  END PROCESS;
-------------------------------------------------------------------------------------------------------------------------  
  Peak_detecter: PROCESS(ctrlin, curState,Num,start,clk)     --Peak detector 
  
  BEGIN
    IF curState = s0 THEN      ---initialise all variables, counters and signals 
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
      position<=0;
    END IF;
    IF start='1'  then
        IF  rising_edge(ctrlin) or Num=NumWordsDigit THEN                  --updates when ctrlin is high and when it is the last run of the code
          b4<=signed(data);                                           --back up the latest data and the previous datat for every new input data
          b3<=b4;
          b2<=b3;
          b1<=b2;
          
          --peak and first three bits
          IF b4>d4 THEN                                             --comparator to compare the latest data with the old peak
            d4<=b4;                                                 -- If the input is the new peak, store data from b(1-4) signals for the new peak and the 3 values before
            d3<=b3;
            d2<=b2;     
            d1<=b1;
            d5<="00000000";
            d6<="00000000";
            d7<="00000000";
            position<=Num;                                          --store the maxIndex in position
            COUNT<=0;
         
          --first bit after peak  
          ELSIF b4<d4 THEN
          
            IF COUNT=0 THEN
              d5<=b4;
              COUNT <= COUNT+1;                                     -- count increment for the system to locate where the data should be put in for the last three bits
              
            --second bit after peak  
            ELSIF COUNT=1 THEN
              d6<=b4;
              COUNT <= COUNT+1;
              
            --third bit after peak    
            ELSIF COUNT=2 THEN
              d7<=b4;
              COUNT <= COUNT+1;
              
            END IF;

            
          END IF;   
          
        END IF;
        
        IF  falling_edge(ctrlin) or Num=NumWordsDigit THEN                  --updates when ctrlin is high and when it is the last run of the code
          b4<=signed(data);                                           --back up the latest data and the previous datat for every new input data
          b3<=b4;
          b2<=b3;
          b1<=b2;
          
          --peak and first three bits
          IF b4>d4 THEN                                             --comparator to compare the latest data with the old peak
            d4<=b4;                                                 -- If the input is the new peak, store data from b(1-4) signals for the new peak and the 3 values before
            d3<=b3;
            d2<=b2;     
            d1<=b1;
            d5<="00000000";
            d6<="00000000";
            d7<="00000000";
            position<=Num;                                          --store the maxIndex in position
            COUNT<=0;
         
          --first bit after peak  
          ELSIF b4<d4 THEN
          
            IF COUNT=0 THEN
              d5<=b4;
              COUNT <= COUNT+1;                                     -- count increment for the system to locate where the data should be put in for the last three bits
              
            --second bit after peak  
            ELSIF COUNT=1 THEN
              d6<=b4;
              COUNT <= COUNT+1;
              
            --third bit after peak    
            ELSIF COUNT=2 THEN
              d7<=b4;
              COUNT <= COUNT+1;
              
            END IF;

            
          END IF;   
          
        END IF;
  END if;
  END PROCESS;
-------------------------------------------------------------------------------------------------------------------------
  MaxIndex_converter: PROCESS(curState, d1,d2,d3,d4,d5,d6,d7,position)
  BEGIN
    --initialize the system
    if curState = s0 then
      VALUE<=0;
    end if;
    VALUE<= position-1;                                            -- assign position-1 to 'value' since the positon used for maxIndex starts counting at 0 but the Num starts counting at 1 
    hundred<= VALUE / 100;                                         -- divide the signal 'value' in its digits
    ten<= (VALUE mod 100) / 10;
    unit<= VALUE mod 10;
    
    maxIndex(2)<= std_logic_vector(to_unsigned(hundred,4));           -- assign the value in maxindex
    maxIndex(1)<= std_logic_vector(to_unsigned(ten,4));
    maxIndex(0)<= std_logic_vector(to_unsigned(unit,4));

    dataResults(0)<= std_logic_vector(d1);     
     dataResults(1)<= std_logic_vector(d2);
     dataResults(2)<= std_logic_vector(d3);
     dataResults(3)<= std_logic_vector(d4);
     dataResults(4)<= std_logic_vector(d5);
     dataResults(5)<= std_logic_vector(d6);
     dataResults(6)<= std_logic_vector(d7);
  END PROCESS;  
-------------------------------------------------------------------------------------------------------------------------------
  --sequential state
  seq_state: PROCESS (clk, reset)                                 
  BEGIN
    IF reset = '1'  THEN                                        -- reset signal returns to state 0 which reset the system .
      curState <= s0;
      
    ELSIF clk'EVENT AND clk='1'  THEN                           -- synchronous system that only refresh the states with respect to clock.
      curState <= nextState;
      
    END IF;
  END PROCESS;
END;