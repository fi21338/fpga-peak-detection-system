--Package for entities to share ports
--------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL; 
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL; 
 
USE work.common_pack.ALL; 

PACKAGE shared_variables_pkg IS
    SIGNAL  Sendbackp : std_logic;
    SIGNAL  SendBackl : std_logic;
    SIGNAL  nowP : std_logic;
    SIGNAL  nowL : std_logic;
    --SIGNAL  valid : std_logic;
    
END PACKAGE shared_variables_pkg;

----------------------------------------


LIBRARY IEEE;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL; 
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL; 
USE work.common_pack.ALL;
USE work.shared_variables_pkg.ALL;
ENTITY commandP IS
    PORT (
        clk : IN std_logic; -- Clock Input
        reset : IN std_logic; -- Reset Input
        --dataReady : IN std_logic; -- Added
        txData : OUT std_logic_vector (7 DOWNTO 0); -- Serial Output Data line connected to Input of receiver
        txNow : OUT std_logic; -- Sends operation
        txDone : IN std_logic; -- Stays low Until operation finIShed to send another Byte
        maxIndex : IN BCD_ARRAY_TYPE(2 DOWNTO 0); 
        dataResults : IN CHAR_ARRAY_TYPE(0 TO RESULT_BYTE_NUM - 1); -- Contains 56 lines
        HighP : IN std_logic; --High when Pcmd has been recieved
        --SendBackp : OUT std_logic := '0'; -- P command has been sent
        WaitSend : OUT std_logic --Waiting to send data
    );
END commandP;

ARCHITECTURE Pcmd OF commandP IS
	TYPE state_type IS (S0, S1, S2, S3); --Defining State machines
	SIGNAL curState, nextState : state_type;

	--Signals For counting And controlling data transmISsion
	SIGNAL count : INTEGER := 0; --counts iterations
	SIGNAL counter_enable : std_logic := '0';
	SIGNAL counter_reset : std_logic;

BEGIN
	dataSend : PROCESS (txDone, count, maxIndex, HighP, dataResults, curState) -- Determining next states
	BEGIN
		--Initialize
		--counter_enable <= '0';
		--counter_reset <= '0';
		--txData <= x"20";
		--txNow <= '0';
		--WaitSend <= '1';
		SendBackP <= '0';

		CASE curState IS -- Checks If an L Or P has been recieved

			WHEN S0 => 
				WaitSend <= '0';
				counter_reset <= '1';
				txNow <= '0';
				IF HighP = '1' THEN
					nextState <= S1; --If HighP=1 go to S1
				ELSE
					nextState <= S0; --If not stay at S0
				END IF;

			WHEN S1 => 
				txData <= dataResults(3);
				SendBackP <= '0';
				txNow <= '1';
				nextState <= S2; -- Go to S2

			WHEN S2 => 
				IF txDone = '1' THEN
					IF count = 3 THEN
						nextState <= S0; --If count=3 and txdone=1 move to S0
					ELSE
						txData <= x"20";
						txNow <= '1';
						nextState <= S1;
					END IF;
				ELSE
					nextState <= S2;
				END IF;

			WHEN S3 => 
				txData <= "0011" & maxIndex(2 - count); -- converts the numbers on Maxindex to ascii characters
				txNow <= '1';
				counter_enable <= '1';
				nextState <= S2; --Go to S2

			WHEN OTHERS => 
				nextState <= S0;

		END CASE;
	END PROCESS;

	counter : PROCESS (clk, counter_reset, counter_enable) -- Counter
	BEGIN
		IF counter_reset = '1' THEN
			count <= 0; -- Resets counter to zero
		ELSIF rising_edge(clk) AND counter_enable = '1' THEN
			count <= count + 1; --Adds 1 to count
		END IF;
	END PROCESS;

	stateChange : PROCESS (clk, reset) -- Updates state of state machine based on current And next state
	BEGIN
		IF reset = '1' AND clk'EVENT AND clk = '1' THEN
			curState <= S0; -- Sets curState to s0 when reset IS one
		ELSIF clk'EVENT AND clk = '1' THEN
			curState <= nextState; -- sets current state to next state
		END IF;
	END PROCESS;
	END Pcmd;
	----------------------------------------------------- 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.common_pack.ALL;
USE work.shared_variables_pkg.ALL;

ENTITY commandL IS
    PORT (
        clk : IN std_logic;
        reset : IN std_logic;
        --dataReady : IN std_logic; -- Added
        txData : OUT std_logic_vector (7 DOWNTO 0);
        txNow : OUT std_logic;
        txDone : IN std_logic;
        dataResults : IN CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
        Highl : IN std_logic;
        WaitSend : OUT std_logic
    );
END commandL;

ARCHITECTURE Lcmd OF commandL IS
	TYPE state_type IS (S0, S1, S2, S3, S4);
	SIGNAL curState, nextState : state_type;

	SIGNAL counter_enable : std_logic := '0';
	SIGNAL DataResults2 : std_logic_vector(7 DOWNTO 0);
	SIGNAL counter_reset : std_logic;
	SIGNAL counter2_reset : std_logic;
	SIGNAL count2 : INTEGER := 0;
	SIGNAL count : INTEGER := 0;

BEGIN
	combi_nextState : PROCESS (clk, curState, dataResults, Highl, count, txDone)
	BEGIN
		--counter_reset <= '0';
		--counter_enable <= '0';
		--txData <= DataResults2;
		--txNow <= '0';
		SendBackl <= '0';
		WaitSend <= '1';

		CASE curState IS
			WHEN S0 => 
				WaitSend <= '0';
				counter_reset <= '1';
				IF Highl = '1' THEN
					nextState <= S1;
				ELSE
					nextState <= S0;
				END IF;

			WHEN S1 => 
				counter_reset <= '0';
				WaitSend <= '1';
				SendBackl <= '1';
				IF Highl = '0' THEN
					nextState <= S2;
				ELSE
					nextState <= S1;
				END IF;

			WHEN S2 => 
				txData <= dataResults2;
				txNow <= '1';
				SendBackl <= '0';
				nextState <= S3;

			WHEN S3 => 
				txnow <= '0';
				txdata <= dataResults2;
				IF txdone = '0' THEN
					nextState <= S4;
				ELSE
					nextState <= S3;
				END IF;

			WHEN S4 => 
				IF txDone = '1' AND count = 55 THEN
					nextState <= S0;
				ELSIF txDone = '1' THEN
					nextState <= S2;
				ELSE
					nextState <= S4;
				END IF;

			WHEN OTHERS => 
				nextState <= S0;

		END CASE;

	END PROCESS;

	stateChange : PROCESS (clk, reset) 
	BEGIN
		IF reset = '1' AND clk'EVENT AND clk = '1' THEN
			curState <= S0;
		ELSIF clk'EVENT AND clk = '1' THEN
			curState <= nextState;
		END IF;
	END PROCESS;

	counter : PROCESS (clk, counter_reset, counter_enable)
	BEGIN
		IF counter_reset = '1' THEN
			count <= 0;
		ELSIF rising_edge(clk) AND counter_enable = '1' AND count < 55 THEN
			count <= count + 4;
		END IF;
	END PROCESS;

	counter2 : PROCESS (clk, counter2_reset, counter_enable)
	BEGIN
		IF counter2_reset = '1' THEN
			count2 <= 0;
		ELSIF rising_edge(clk) AND counter_enable = '1' AND count2 < 1 THEN
			count2 <= count2 + 1;
		END IF;
	END PROCESS;

--	byte_test : PROCESS (dataResults, count)
--	BEGIN
--		IF dataResults((55 - count) DOWNTO (52 - count)) < "1010" AND count < 8 THEN
--			DataResults2 <= "0011" & dataResults((55 - count) DOWNTO (52 - count));
--		ELSIF dataResults((55 - count) DOWNTO (52 - count)) > "1001" AND count < 8 THEN
--			DataResults2 <= std_logic_vector(unsigned(std_logic_vector'("0011" & dataResults((55 - count) DOWNTO (52 - count)))) + ("00000111"));
--		END IF;
--	END PROCESS;

END;


LIBRARY IEEE;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL; 
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL; 
USE work.shared_variables_pkg.ALL;

USE work.common_pack.ALL; 



ENTITY cmdProc IS 
	PORT (
 
 
		clk : IN std_logic;
		reset : IN std_logic;
		rxNow : IN std_logic;
		rxData : IN std_logic_vector (7 DOWNTO 0);
		txData : OUT std_logic_vector (7 DOWNTO 0);
		rxDone : OUT std_logic;
		ovErr : IN std_logic;
		framErr : IN std_logic;
		txNow : OUT std_logic;
		txDone : IN std_logic;
		
		start : OUT std_logic;
		numWords_bcd : OUT BCD_ARRAY_TYPE(2 DOWNTO 0);
		dataReady : IN std_logic;
		byte : IN std_logic_vector(7 DOWNTO 0);
		maxIndex : IN BCD_ARRAY_TYPE(2 DOWNTO 0);
		dataResults : IN CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
		seqDone : IN std_logic
		
 
 
	);
END cmdProc; 
 
	----------------------------------------------------- 

ARCHITECTURE arch_cmdProc OF cmdProc IS 
    signal cmdNow :  std_logic ;


 
 
 
	TYPE state_type IS (INIT, FIRST, WAIT_FOR_VALID, SECOND, AStart, AFinISh, StartL, StartP, ISVALID, INVALID, SPACE, WAIT_FOR_VALID_SPACE, WAIT_FOR_TX); 
	SIGNAL curState, nextState : state_type; 
	SIGNAL USEcounter : std_logic := '0'; 
	SIGNAL reset_counter : std_logic := '0'; 
	SIGNAL count : INTEGER := 0; 

 
	SIGNAL numWords_en : INTEGER := 0; 
	SIGNAL numWords_bcd_reset : std_logic := '0'; 
	SIGNAL numWords_bcd_reg : BCD_ARRAY_TYPE(2 DOWNTO 0) := ("0000", "0000", "0000"); 
 
	SIGNAL ADONE_en : std_logic := '0'; 
	SIGNAL ADONE_reg : std_logic := '0'; 
	SIGNAL ADONE : std_logic := '0'; 
 
	SIGNAL txData_en : std_logic := '0'; 
	SIGNAL txData_reg : std_logic_vector (7 DOWNTO 0) := "11111111"; 
 
	SIGNAL cmd_mode_en : std_logic := '0'; 
	SIGNAL cmd_mode_reg : std_logic_vector (1 DOWNTO 0) := "00"; 
	SIGNAL cmd_mode : std_logic_vector (1 DOWNTO 0) := "00";
 
 
BEGIN
	--Handle logic 
	combi_nextState : PROCESS (clk, curState, rxNow, rxdata, seqDone, count, txDone, dataReady, SendBackl, SendBackp, numWords_bcd_reg, ADONE, cmd_mode, framErr, ovErr) 
	BEGIN
	

	
		CASE curState IS 
			WHEN INIT =>
			    report "INIT";
			    
 
				--ALL output signals on command processor set low
				cmd_mode_en <= '0'; 
				cmd_mode_reg <= "00"; 
 
				rxDone <= '0'; 
 
				txNow <= '0'; 
				
				start <='0';
 
				txData_en <= '0'; 
				txData_reg <= "00000000"; 
				txData <= "11111111";
 
				nowL <= '0'; 
				nowP <= '0'; 
 
				USEcounter <= '0'; 
				reset_counter <= '0'; 
				cmdNow <= '0'; 

 
				numWords_en <= 4; 
				numWords_bcd_reset <= '0'; 
				numWords_bcd_reg <= ("0000", "0000", "0000"); 

 
				ADONE_en <= '0'; 
				ADONE_reg <= '0';
 
 
 
 
				CASE rxdata IS 
 
					WHEN "01100001" | "01000001" => --CMD A 
 
						txData_en <= '1'; 
						txData_reg <= rxdata; 
 
 
						cmd_mode_en <= '1'; 
						cmd_mode_reg <= "00"; 
 
						nextState <= ISVALID; 
 
					WHEN "01101100" | "01001100" => --CMD L 
						IF seqDone = '1' AND ADONE = '1' THEN 
							nowL <= '1'; 
 
							cmd_mode_en <= '1'; 
							cmd_mode_reg <= "01"; 
 
							txData_en <= '1'; 
							txData_reg <= rxdata; 
 
							nextState <= ISVALID; 
						ELSE 
							nextState <= INIT; 
						END IF; 
 
					WHEN "01110000" | "01010000" => --CMD P 
						IF seqDone = '1' AND ADONE = '1' THEN 
							nowP <= '1'; 
 
							cmd_mode_en <= '1'; 
							cmd_mode_reg <= "10"; 
 
							txData_en <= '1'; 
							txData_reg <= rxdata; 
 
							nextState <= ISVALID; 
						ELSE 
							nextState <= INIT; 
						END IF; 
 
					WHEN OTHERS => 
 
						nextState <= INVALID; 
 
			END CASE; 
 
			-------------------------------------------------------------------------------------------------------------------------------------------------------- 
 
			WHEN INVALID => 
			    report "INVALID";
				reset_counter <= '1'; 
				txNow <= '1'; -- Send back the letter typed 
				rxDone <= '1'; -- Set done to high 
				nextState <= INIT; 
				-------------------------------------------------------------------------------------------------------------------------------------------------------- 
			WHEN ISVALID => 
			    report "isvalid";
				txNow <= '1'; -- Send back the letter typed 
				rxdone <= '1'; -- Set done to high 
 
				IF framErr = '0' THEN --IS framErr set to low?
					nextState <= WAIT_FOR_TX;
				ELSE
					nextState <= INIT;
 
				END IF;
 
				-- Send back to INIT if framErr IS high
				-------------------------------------------------------------------------------------------------------------------------------------------------------- 
 
			WHEN WAIT_FOR_TX =>
			    report "wait for tx";
				IF txDone = '1' THEN
					nextState <= WAIT_FOR_VALID;
				ELSE
					nextState <= WAIT_FOR_TX;
				END IF;
 
 
 
 
				-------------------------------------------------------------------------------------------------------------------------------------------------------- 
 
			WHEN WAIT_FOR_VALID => -- wait - IS valid set to high? 
 
                report "wait for valid";
				IF dataReady = '1' AND ovErr = '0' THEN -- Check if valid high and ovErr low 
					nextState <= FIRST;
				ELSIF dataReady = '1' AND ovErr = '1' THEN -- IF ovErr IS high, go back to INIT
					nextState <= INIT;
 
				ELSE 
					nextState <= WAIT_FOR_VALID; 
				END IF; 
				-------------------------------------------------------------------------------------------------------------------------------------------------------- 
 
			WHEN FIRST => 
                report "first";
				rxDone <= '0'; 
 
				USEcounter <= '0'; 
 
				txData_en <= '1'; 
				txData_reg <= rxdata; 
				txNow <= '0'; 
 
				IF rxnow = '0' AND txDone = '1' THEN 
					IF cmd_mode = "01" THEN -- l command 
						nextState <= StartL; 
					ELSIF cmd_mode = "10" THEN -- p command 
						nextState <= StartP; 
					ELSE 
						nextState <= SECOND; -- a command 
					END IF; 
				ELSE 
					nextState <= FIRST; 
				END IF; 
				-------------------------------------------------------------------------------------------------------------------------------------------------------- 
 
			WHEN SECOND => 
			
                report "second";
				IF count = 3 THEN
					txData_en <= '1';
					txData_reg <= "00100000";
 
					nextState <= SPACE;
				ELSE
					rxDone <= '0';
 
					IF rxnow = '1' THEN
 
						IF rxdata(7 DOWNTO 4) = "0011" AND (rxdata(3 DOWNTO 0) > "0000" OR rxdata(3 DOWNTO 0) < "1001") THEN
							IF count = 0 THEN
								numWords_en <= 1;
								numWords_bcd_reg(0) <= rxdata(3 DOWNTO 0);
							ELSIF count = 1 THEN
								numWords_en <= 2;
								numWords_bcd_reg(1) <= rxdata(3 DOWNTO 0);
							ELSIF count = 2 THEN
								numWords_en <= 3;
								numWords_bcd_reg(2) <= rxdata(3 DOWNTO 0);
							END IF;
 
							USEcounter <= '1';
 
							txNow <= '1';
 
							txData_en <= '1';
							txData_reg <= rxdata;
 
							nextState <= ISVALID;
						ELSE
							txData_en <= '1';
							txData_reg <= rxdata;
 
							nextState <= INVALID;
						END IF;
					ELSE
						nextState <= SECOND;
					END IF;
				END IF;
 
			WHEN SPACE => 
				txNow <= '1'; 
				cmdNow <= '1'; 
				nextState <= WAIT_FOR_VALID_SPACE; 
 
			WHEN WAIT_FOR_VALID_SPACE => 
				txData_en <= '1'; 
				txData_reg <= rxdata; 
 
				IF txDone = '0' THEN 
					nextState <= AStart; 
				ELSE 
					nextState <= WAIT_FOR_VALID_SPACE; 
				END IF; 
 
			WHEN AStart => 
				IF dataReady = '1' THEN 
					cmdNow <= '0'; 
					nextState <= AFinISh; 
				ELSE 
					cmdNow <= '1'; 
					nextState <= AStart; 
				END IF; 
 
			WHEN AFinISh => 
				IF seqDone = '1' THEN 
					reset_counter <= '1'; 
 
					ADONE_en <= '1'; 
					ADONE_reg <= '1'; 
 
					nextState <= INIT; 
				ELSE 
					nextState <= AFinISh; 
				END IF; 
 
			WHEN StartL => 
				IF SendBackl = '1' AND txDone = '1' THEN 
					nowL <= '0'; 
					nextState <= INIT; 
				ELSE 
					nowL <= '1'; 
					nextState <= StartL; 
				END IF; 
 
			WHEN StartP => 
				IF SendBackp = '1' AND txDone = '1' THEN 
					nowP <= '0'; 
					nextState <= INIT; 
				ELSE 
					nowP <= '1'; 
					nextState <= StartP; 
				END IF; 
 
			WHEN OTHERS => 
				nextState <= INIT; 
 
		END CASE; 
 
	END PROCESS; 
 
	----------------------------------------------------- 
	reg : PROCESS (clk, numWords_en, numWords_bcd_reg, numWords_bcd_reset, ADONE_en, txData_en, cmd_mode_en)
	BEGIN
		IF rising_edge(clk) THEN
			IF numWords_en = 1 THEN
				numWords_bcd(2) <= numWords_bcd_reg(0);
			ELSIF numWords_en = 2 THEN
				numWords_bcd(1) <= numWords_bcd_reg(1);
			ELSIF numWords_en = 3 THEN
				numWords_bcd(0) <= numWords_bcd_reg(2);
				
		    ELSIF numWords_en = 4 THEN
		      numWords_bcd(0) <= numWords_bcd_reg(2);
		      numWords_bcd(1) <= numWords_bcd_reg(1);
		      numWords_bcd(2) <= numWords_bcd_reg(0);
			END IF;
 
 
			IF txData_en = '1' THEN
				txData <= txData_reg;
			END IF;
 
			IF cmd_mode_en = '1' THEN
				cmd_mode <= cmd_mode_reg;
			END IF;
 
			IF ADONE_en = '1' THEN
				ADONE <= ADONE_reg;
			END IF;
		END IF;
	END PROCESS;
 
 
 
	--Increment counter 
	counter : PROCESS (clk, USEcounter, reset_counter) 
	BEGIN
		IF reset_counter = '1' THEN 
			count <= 0; 
		ELSIF rising_edge(clk) AND USEcounter = '1' THEN 
			count <= count + 1; 
		END IF; 
	END PROCESS; 
 
 
 
	----------------------------------------------------- 
 
	--Process to change states + handle reset at every rising clock edge 
	seq_state : PROCESS (clk, reset) 
	BEGIN
		IF reset = '1' THEN 
			curState <= INIT; 
		ELSIF clk'EVENT AND rising_edge(clk) THEN 
			curState <= nextState; 
		END IF; 
	END PROCESS; 
 
	END arch_cmdProc; 
