

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.common_pack.all;
ENTITY cmdProc IS
--Declare all ports
	PORT (
		clk : IN std_logic;
		reset : IN std_logic;
		rxnow : IN std_logic;
		rxData : IN std_logic_vector (7 DOWNTO 0);
		txData : OUT std_logic_vector (7 DOWNTO 0);
		rxdone : OUT std_logic;
		valid : IN std_logic;
		OE : IN std_logic;
		FE : IN std_logic;
		txnow : OUT std_logic;
		txdone : IN std_logic;
		start : out std_logic;
		numWords_bcd : OUT BCD_ARRAY_TYPE(2 DOWNTO 0);
		dataReady : IN std_logic;
		byte : IN std_logic_vector(7 DOWNTO 0);
		maxIndex : IN BCD_ARRAY_TYPE(2 DOWNTO 0);
		--dataResults : IN CHAR_ARRAY_TYPE(0 TO RESULT_BYTE_NUM - 1);
		seqDone : IN std_logic;
		dataResults: in std_logic_vector(55 downto 0)
		
	);
END cmdProc;

ARCHITECTURE behavioural OF cmdProc IS
    --Set signals required for the architecture
    SIGNAL aNow, aRecieve, nowL, highL, SendBackl, nowP, highP, SendBackp : std_logic := '0';
    SIGNAL txNow_cmdAnalyse, txNow_dataProc, txNow_Lcmd, txNow_Pcmd : std_logic := '0';
    SIGNAL txData_cmdAnalyse, txData_dataProc, txData_Lcmd, txData_Pcmd : std_logic_vector (7 DOWNTO 0) := "00011000";
    SIGNAL dataProc_TxHold, Lcmd_TxHold, Pcmd_TxHold, printNow, printSpace : std_logic := '0';
BEGIN
	cmd_parse : ENTITY work.cmdAnalyze(parseCommands)
		PORT MAP(
			clk => clk, 
			oe => oe,
			fe=>fe,
			reset => reset, 
 
			rxnow => rxnow, 
			Data => rxData, 
			rxdone => rxdone, 
			dataready =>dataready,
			byte=>byte,
			maxindex=>maxindex,
			dataresults=>dataresults,
			valid=>valid,
 
			txData => txData_cmdAnalyse, 
			txnow => txnow_cmdAnalyse, 
			txdone => txdone, 
			numWords_bcd => numWords_bcd, 
 
			cmdNow => aNow, 
			cmdReceive => aRecieve, 
 
			nowL => nowL, 
			SendBackl => SendBackl, 

			nowP => nowP, 
			SendBackp => SendBackp, 
 
			seqDone => seqDone
		);


	data_process : ENTITY work.dataConsume(processData)
		PORT MAP(
			clk => clk, 
			reset => reset, 

			Data => txData_dataProc, 
			--txnow => txnow_dataProc, 
			--done => txdone, 
 
			start => start, 
			dataReady => dataReady, 
			byte => byte, 
			seqDone => seqDone, 
 
			cmdNow => aNow, 
			cmdRecieve => aRecieve, 
 
			txHold => dataProc_TxHold
		);
 
	l_cmd : ENTITY work.commandL(Lcommand)
		PORT MAP(
			clk => clk, 
			reset => reset, 

			txData => txData_Lcmd, 
			txnow => txnow_Lcmd, 
			txdone => txdone,
			highl => highl,
			
 
			dataResults => dataResults, 
 
			--nowL => nowL, 
			SendBackl => SendBackl, 
 
			waitsend => Lcmd_TxHold
		);
 
	p_cmd : ENTITY work.commandP(Pcommand)
		PORT MAP(
			clk => clk, 
			reset => reset, 

			txData => txData_Pcmd, 
			txnow => txnow_Pcmd, 
			txdone => txdone, 
 
			dataResults => dataResults, 
			maxIndex => maxIndex, 
			highp => highp,
 
			--pNow => pNow, 
			SendBackp => SendBackp, 
 
			waitsend => Pcmd_TxHold
		); 
 
	tx_print : PROCESS(clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
		  txNow <= '0';
		  txData <= "11111111";
		  
			IF dataProc_TxHold = '1' THEN
				txNow <= txNow_dataProc;
				txData <= txData_dataProc;
			ELSIF Lcmd_TxHold = '1' THEN
				txNow <= txNow_Lcmd;
				txData <= txData_Lcmd;
			ELSIF Pcmd_TxHold = '1' THEN
				txNow <= txNow_Pcmd;
				txData <= txData_Pcmd;
			ELSE
				txNow <= txNow_cmdAnalyse;
				txData <= txData_cmdAnalyse; 
			END IF; 
 
 
			--txDone <= txDone;
		ELSE NULL;
		END IF;
 
	END PROCESS;
 
	END;