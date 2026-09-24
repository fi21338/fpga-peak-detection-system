-- Code For the procesing the data For the L Cmd

LIBRARY ieee;			-- Listing Library
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL; 
USE work.common_pack.ALL;

ENTITY commandL IS
	PORT (
			clk : IN std_logic;				-- Clock Input
			reset : IN std_logic;			-- Reset Input
            txData : OUT std_logic_vector (7 DOWNTO 0);     --  Serial Output Data line connected to Input of receiver
      		txNow : OUT std_logic;			-- Sends operation
      		txDone : IN std_logic;			-- Stays low Until operation finished to send another Byte
      		dataResults: in std_logic_vector(55 downto 0);        -- Contains 56 lines
			Highl : IN std_logic;			-- High when Lcmd has been recieved
      		SendBackl : OUT std_logic;      -- L command has been sent
      		WaitSend : OUT std_logic		--Waiting to send data
 
		);
END commandL;

ARCHITECTURE Lcmd OF commandL IS
TYPE state_type IS (S0, S1, S2, S3, S4, S5, S6, S7, S8);		--Defining State machines
		SIGNAL curState, nextState : state_type;
		
		--Signals For counting And controlling data transmission
		SIGNAL counter_enable : std_logic := '0';
		SIGNAL DataResults2 : std_logic_vector(7 downto 0);
		SIGNAL counter_reset : std_logic;
		SIGNAL counter2_reset : std_logic;
		SIGNAL count2 : INTEGER := 0;   -- 	Counts iteration
		SIGNAL count : INTEGER := 0; 	-- Counts iteration
		

BEGIN
		combi_nextState : PROCESS(clk, curState, dataResults, Highl, count, txDone)  -- Determining next states
		BEGIN
				-- Initialize
				counter_reset <= '0';
				counter_enable <= '0';
				txData <= DataResults2;
				txNow <= '0';
				SendBackl <= '0';
				WaitSend <= '1'; 
				
		 
		
				CASE curState IS		-- Checks If an L Or P has been recieved 
			
					WHEN S0 => 
							WaitSend <= '0';
							counter_reset <= '1'; 
							IF Highl = '1' THEN		--If high move to S1
									nextstate <= S1;
							ELSE
									nextstate <= S0; 	-- If low stay at S0
							END IF;
 
				
					WHEN S1 => 
							counter_reset <= '0';
							WaitSend <= '1'; 
							SendBackl <= '1';
							IF Highl = '0' THEN
									nextstate <= S2;	--If high move to S2
							ELSE
									nextstate <= S1;	---- If low stay at S1
							END IF;
	
					
					WHEN S2 => 
			  				counter_enable <= '0';
							txData <= dataResults2;
							txNow <= '1';
							SendBackl <= '0';
							nextstate <= S3;		--Move to S3
				
			
					WHEN S3 =>		  
			  				txnow <= '0';
			  				txdata <= dataResults2;
			  				IF txdone = '0' THEN 
			    					nextstate <= S4;	-- If txdone is 0 move to S4
			  				ELSE
			    					nextstate <= S3;	-- If not stay at S3
			  				END IF;
			      
				
					WHEN S4 => 
							txData <= dataResults2;
							IF txDone = '1' THEN
									nextstate <= S5;	-- If txdone is 1 move to S5
							ELSE
									nextstate <= S4;	--If not high stay at S4
							END IF;	
				
				
		  			WHEN S5 =>
		     				counter_enable <= '1';
		    				IF count2 <= 1 THEN
					 			nextstate <= S6;		--If count2=1 go to S6
				 			ELSE 
					 			nextstate <= S2;		--If not then move to S2
				 			END IF;				
				
					WHEN S6 => 
							counter2_reset <= '1'; 
		   				 	counter_enable <= '0';			  
							txData <= x"20"; 
							txNow <= '1';
							nextstate <= S7;			--Send to S7
				
      
					WHEN S7 =>
							counter2_reset <= '0';         
        					txdata <= x"20";
        					txnow <= '0';
        					IF txdone = '0' THEN 
          						nextstate <= S8;	-- If txdone=0 next state S8
       						ELSE
          						nextstate <= S7;	-- Otherwise stay at S7
        					END IF;
 
			
					WHEN S8 => 
			  				txData <= x"20";
							IF txDone = '1' THEN 
							IF Count = 55 THEN 
								nextstate <= S0;	-- IF count=55 And txdone=1 next state is S0
							ELSE
								nextstate <= S2;
							END IF;
							ELSE
								nextstate <= S8;
							END IF;
				
					WHEN OTHERS => 
							nextstate <= S0;
							
			END CASE;
 
	END PROCESS;
	

stateChange : PROCESS (clk, reset)		-- Updates state of state machine based on current And next state
	BEGIN
		IF reset = '1' AND clk'EVENT AND clk = '1' THEN
			curState <= S0;		-- Sets curstate to s0 when reset is one
		ELSIF clk'EVENT AND clk = '1' THEN
			curState <= nextState;	-- sets current state to next state
		END IF;
	END PROCESS; 
	

counter : PROCESS(clk, counter_reset, counter_enable)		-- Counter
	BEGIN
		IF counter_reset = '1' THEN
			count <= 0;			-- Resets counter to zero
ELSIF rising_edge(clk) AND counter_enable = '1' AND count < 55  THEN  -- Counts up to fifty-five
			count <= count + 4;		-- Adds four to the count
		END IF;
	END PROCESS; 
	

counter2 : PROCESS(clk, counter2_reset, counter_enable)		-- Counter 2
	BEGIN
		IF counter2_reset = '1' THEN
			count2 <= 0;		-- Resets counter to zero
		ELSIF rising_edge(clk) AND counter_enable = '1' AND count2 < 1 THEN	-- Counts up to one
			count2 <= count2 + 1;	-- Adds one to count
		END IF;
	END PROCESS; 
	

byte_test: process(dataResults, count)
	BEGIN
		-- If current count is less than 8 And 4-bit less than "1010" then add "0011 to 4-bit and store in data results 2
	  IF dataResults((55-count) downto (52-count)) < "1010" AND count < 8 THEN
	    DataResults2 <= "0011" & dataResults((55-count) downto (52-count));
		
		-- If current count is less than 8 And the 4-bit is more than "1001", add 7 to Unsigned value And store in data results 2 
	  ELSIF dataResults((55-count) downto (52-count)) > "1001" AND count < 8 THEN
	    DataResults2 <= std_logic_vector( unsigned(  std_logic_vector'("0011"&dataResults((55-count) downto (52-count))))  + ("00000111"));
	    
	END IF;
	END PROCESS; 

	END;
