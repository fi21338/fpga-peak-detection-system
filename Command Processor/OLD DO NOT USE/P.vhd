-- Code For the procesing the data For the P Cmd
LIBRARY ieee;		-- Listing Library
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE work.common_pack.ALL;

Entity commandP is
	PORT (
  			clk : IN std_logic;		-- Clock Input
  			reset : IN std_logic;	-- Reset Input
      		txData : OUT std_logic_vector (7 DOWNTO 0);		-- Serial Output Data line connected to Input of receiver
			txNow : OUT std_logic;		-- Sends operation
			txDone : IN std_logic;		-- Stays low Until operation finished to send another Byte
      		maxIndex : IN BCD_ARRAY_TYPE(2 DOWNTO 0);		
      		dataResults : IN CHAR_ARRAY_TYPE(0 TO RESULT_BYTE_NUM - 1);	-- Contains 56 lines
			HighP : IN std_logic;		--High when Pcmd has been recieved
  	   	 	SendBackP : OUT std_logic; 	-- P command has been sent
  			WaitSend : OUT std_logic	--Waiting to send data
		);
END commandP;

ARCHITECTURE Pcmd OF commandP IS
TYPE state_type IS (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10);	--Defining State machines
		SIGNAL curState, nextState : state_type;
		
		--Signals For counting And controlling data transmission
		SIGNAL count : INTEGER := 0;		--counts iterations
		SIGNAL counter_enable : std_logic := '0';
		SIGNAL counter_reset : std_logic;



BEGIN
		dataSend : PROCESS(txDone, count, maxIndex, HighP, dataresults, curState)  -- Determining next states
		BEGIN
				--Initialize
				counter_enable <= '0';
				counter_reset <= '0';
				txData <= x"20";
				txNow <= '0';
				WaitSend <= '1';
				SendBackP <= '0';

				CASE curState IS		-- Checks If an L Or P has been recieved 

					WHEN s0 =>
						WaitSend <= '0';
							counter_reset <= '1';
							txNow <= '0'; 
							IF HighP = '1' THEN
									nextstate <= S1;		--If HighP=1 go to S1
							ELSE
									nextstate <= S0;		--If not stay at S0
							END IF;

					WHEN S2 => 
							txData <= dataResults(3);
							SendBackP <= '0';
							txNow <= '1';
							nextstate <= S3;		-- Go to S3

					WHEN S3 =>
							txNow <= '0';
							IF txDone = '0' THEN 
									nextstate <= S4;	-- If txdone=0 then move to S4
							ELSE
									nextstate <= S3;    -- If not then stay at S3
							END IF;

					WHEN S4 => 
			  				txData <= dataResults(3);	
							IF txDone = '1' THEN
									nextstate <= S5;	--If txdone=1 then move to S5
							ELSE
									nextstate <= S4;	--If not then stay at S4
							END IF;

					WHEN S5 => 
							txData <= x"20"; 
							txNow <= '1';
							nextstate <= S6;		--Go to S6

					WHEN S6 => 
			  				txData <= x"20";
								txNow <= '0';
								IF txDone = '0' THEN 
									nextstate <= S7;		--If txdone=0 move to S7
								ELSE
									nextstate <= S6;		--If not stay at S6
								END IF;

					WHEN S7 => 
			  				txData <= x"20";
							IF txDone = '1' THEN 
								nextstate <= S8;		--If txdone=1 then move to S8
							ELSE
								nextstate <= S7;		--If not stay at S7
							END IF;

					WHEN S8 => 
							txData <= "0011" & maxIndex(2 - count);		-- converts the numbers on Maxindex to ascii characters
							txNow <= '1';
							counter_enable <= '1';
							nextstate <= S9;		--Go to S9

					WHEN S9 =>
							txData <= "0011" & maxIndex(2 - count); 
							counter_enable <= '0';
							txNow <= '0';
							IF txDone = '0' THEN --- waits until Tx modules is sending before the module can wait until it the byte has been sent
								nextstate <= S10; --If txdone=0 then go to S10
							ELSE
          						nextstate <= S9;  --If not stay at S9
							END IF;
                              
                   WHEN S10 =>
							txData <= "0011" & maxIndex(2 - count); 
							IF txDone = '1' THEN 
								IF count = 3 THEN 
									nextstate <= S0;		--If count=3 and txdone=1 move to S0
								ELSE
									nextstate <= S5;
								END IF; 
							ELSE
								nextstate <= S10;
							END IF;
           		   
                   WHEN OTHERS => 
							nextstate <= S0;
 
		END CASE;
END PROCESS;


    counter : PROCESS(clk, counter_reset, counter_enable)		-- Counter
	BEGIN
		IF counter_reset = '1' THEN
			count <= 0;		-- Resets counter to zero
		ELSIF rising_edge(clk) AND counter_enable = '1' THEN
			count <= count + 1;		--Adds 1 to count
		END IF;
	END PROCESS; 
	
                              
                              
	stateChange : PROCESS (clk, reset)		-- Updates state of state machine based on current And next state
	BEGIN
		IF reset = '1' AND clk'EVENT AND clk = '1' THEN
			curState <= S0;		-- Sets curstate to s0 when reset is one
		ELSIF clk'EVENT AND clk = '1' THEN
			curState <= nextState;		-- sets current state to next state
		END IF;
	END PROCESS; 
	
	END;