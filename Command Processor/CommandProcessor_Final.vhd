LIBRARY IEEE;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL; 
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL; 
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


 
 
 
	TYPE state_type IS (RESETSTATE, INIT, SELCTCOMMAND ,A1, P1, L1, A2, A3,A4,P2,L2,P3, WAITFORTX, WAITFORDOUBLETX); 
	SIGNAL curState, nextState: state_type;
	SIGNAL USEcounter : std_logic := '0'; 
	SIGNAL reset_counter : std_logic := '0'; 
	SIGNAL count : INTEGER := 0; 
	SIGNAL ascii : INTEGER := 0; 
	
	SIGNAL internal_seqdone: std_logic := '0'; 
	SIGNAL seqdone_en: std_logic := '0'; 
	SIGNAL txing: INTEGER := 0; 
	SIGNAL waitingtx_reg: INTEGER := 0; 
	SIGNAL waitingtx: INTEGER := 0; 
	SIGNAL txstart: std_logic := '0'; 
    SIGNAL txnow_en: std_logic :='0';
    
    
    SIGNAL store_en : std_logic := '0';
    SIGNAL dataResults_store : CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
    SIGNAL maxIndex_store : BCD_ARRAY_TYPE(2 DOWNTO 0);
    
    SIGNAL dataResults_reg : CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
    SIGNAL maxIndex_reg : BCD_ARRAY_TYPE(2 DOWNTO 0);   
 
	SIGNAL numWords_en : std_logic := '0'; 
	SIGNAL numWords_bcd_reset : std_logic := '0';
	SIGNAL numWords_bcd_reg : BCD_ARRAY_TYPE(2 DOWNTO 0) := ("0000", "0000", "0000"); 
 
	SIGNAL ADONE_en : std_logic := '0'; 
	SIGNAL ADONE_reg : std_logic := '0'; 
	SIGNAL ADONE : std_logic := '0'; 
	
    SIGNAL start_en : std_logic:= '0';
 
    SIGNAL txData2 :  std_logic_vector (7 DOWNTO 0):= "11111111"; 
 	SIGNAL txData2_en : std_logic := '0'; 
	SIGNAL txData2_reg : std_logic_vector (7 DOWNTO 0) := "11111111"; 
	SIGNAL txData_en : std_logic := '0'; 
	SIGNAL txData_reg : std_logic_vector (7 DOWNTO 0) := "11111111"; 
 
	SIGNAL cmd_mode_en : std_logic := '0'; 
	SIGNAL cmd_mode_reg : std_logic_vector (1 DOWNTO 0) := "00"; 
	SIGNAL cmd_mode : std_logic_vector (1 DOWNTO 0) := "00";
 
 
BEGIN
	--Handle logic 
	combi_nextState : PROCESS (clk, curState, rxNow, rxdata, seqDone, count, txDone, dataReady, numWords_bcd_reg, ADONE, cmd_mode, framErr, ovErr, txing) 
	BEGIN

------------------------------------------------------------------------------------------------------------------------------------------------

	
		CASE curState IS 
			WHEN RESETSTATE =>
			--ALL output signals on command processor set low
				start<='0'; 
				seqdone_en<='0';
				reset_counter <= '1';
				
				ADONE_en <= '1'; 
	            ADONE_reg <= ADONE;
				
			    
				
				cmd_mode_en <= '0'; 
				cmd_mode_reg <= "00"; 
 
				rxDone <= '0'; 
 
				txNow <= '0'; 
				txing<=0;
				
 
				txData_en <= '0'; 
				txData_reg <= "00000000"; 

				USEcounter <= '0'; 
				cmdNow <= '0'; 

 
				numWords_en <= '1'; 
				numWords_bcd_reg <= ("0000", "0000", "0000"); 
		
				
				nextState <= INIT;
				
------------------------------------------------------------------------------------------------------------------------------------------------
				
            WHEN INIT =>
                reset_counter <= '0';
                IF framErr = '0' THEN
                    
                    IF rxnow  = '1' THEN -- Check if rxnow is high
     
                        CASE rxdata IS 
         
                            WHEN "01100001" | "01000001" => --CMD A 
    
        
                                cmd_mode_en <= '1';  -- Store command into register
                                cmd_mode_reg <= "00"; 
         
                                nextState <= SELCTCOMMAND; -- Valid input, go to SELECTCOMMAND
                                
         
                            WHEN "01101100" | "01001100" => --CMD L 
                                IF ADONE = '1' THEN  -- Check if A has been completed before
                         
         
                                    cmd_mode_en <= '1'; -- Store command into register
                                    cmd_mode_reg <= "01"; 
         
   
                                    nextState <= SELCTCOMMAND; -- Valid input, go to SELECTCOMMAND
                                ELSE 
                                    nextState <= RESETSTATE; -- If A not complete, go to INIT
                                END IF; 
         
                            WHEN "01110000" | "01010000" => --CMD P 
                                IF ADONE = '1' THEN -- Check if A has been completed before
    
                                    cmd_mode_en <= '1'; -- Store command into register
                                    cmd_mode_reg <= "10"; 
         
         
                                    nextState <= SELCTCOMMAND; -- Valid input, go to SELECTCOMMAND
                                ELSE 
                                    nextState <= RESETSTATE;  -- If A not complete, go to INIT
                                END IF; 
         
                            WHEN OTHERS => -- Others go to INIT
                                nextState <= RESETSTATE; 
         
                        END CASE; 
                    
                        rxdone <='1'; -- set rxdone back up to high after receiving
                        txData_en <= '1'; 
                        txData_reg <= rxdata; -- set txdata to received (Send back what user set)
   
                        txing <= 1;
                    END IF; -- If rxnow =1
            

                    
                    
                END IF; --IF framErr = '0'     
                    
                
                

                
            
            
------------------------------------------------------------------------------------------------------------------------------------------------
            
            
  

 
			WHEN SELCTCOMMAND =>
			    USEcounter <= '0'; -- Set use counter to 0 for default
			    

				IF cmd_mode = "01" THEN -- L
				
					nextState <= L1; 
				ELSIF cmd_mode = "10" THEN -- P
					nextState <= P1; 
				ELSE 
					nextState <= A1; -- A 
				END IF; 




				
------------------------------------------------------------------------------------------------------------------------------------------------


			WHEN A1 => --Start of A
			
			    rxDone <= '1';


				IF count = 3 THEN --Check if counter is 3
					--Send Space
			
					txData_en <= '1'; 
                    txData_reg <= "00100000"; -- set txdata to space
					
					txing<= 1;--Enable send
					nextState <= A2; -- Send to A2

				ELSE -- Count not 3, so store into BCD

					IF rxnow = '1' and txing =0 THEN -- Wait for new rx and previous tx is sent
						txData_en <= '1'; 
                        txData_reg <= rxdata; -- set txdata to received (Send back what user set)
	
						txing <= 1;--Enable send
						
						
						
						
						IF  (rxdata >= "00110000" AND rxdata <= "00111001") THEN
							IF count = 0 THEN -- Count 0, store first digit
								numWords_en <= '1';
								numWords_bcd_reg(0) <= rxdata(3 DOWNTO 0);
							ELSIF count = 1 THEN -- Count 1, store 2nd digit
								numWords_en <= '1';
								numWords_bcd_reg(1) <= rxdata(3 DOWNTO 0);
							ELSIF count = 2 THEN
								numWords_en <= '1';-- Count 2, store 3rd digit
								numWords_bcd_reg(2) <= rxdata(3 DOWNTO 0);
							END IF;
 
							USEcounter <= '1'; -- Enable positive counter

							nextState <= A1;-- Carry on A1
						ELSE
							nextState <= RESETSTATE; -- A non-integer was sent, so reset
						END IF;
					ELSE -- rxnow = 1?
						nextState <= A1;
					END IF;
				END IF;

 
 
------------------------------------------------------------------------------------------------------------------------------------------------
-- State to manage controlling start signal and check if seqdone is high
			WHEN A2 => 
			    rxDone <= '1';
			    seqdone_en<='0';
			    start <='1'; -- Start data processor


				IF seqDone = '1' or internal_seqdone='1' THEN -- Check if sequence is complete
				    
				    seqdone_en<='0';
				
					reset_counter <= '1'; 
					ADONE_en <= '1';
					ADONE_reg <='1';
                    store_en<='1';
                    maxindex_reg<=maxindex;
                    dataresults_reg<=dataresults;
                    nextState <= RESETSTATE;
                    
			    
 
					nextState <= RESETSTATE; -- All sequence complete, send back to resetstate

                ELSIF dataReady = '1' THEN --Wait for data processor
                   -- Send user data from data processor
                   
                                      
                    txData_en <= '1'; 
                    txData2_en <= '1'; 
                   

                    CASE byte(7 downto 4) IS
                        
                        when "1010" => txData_reg<= "01000001"; -- ASCII 'A'
                        when "1011" => txData_reg<= "01000010"; -- ASCII 'B'
                        when "1100" => txData_reg<= "01000011"; -- ASCII 'C'
                        when "1101" => txData_reg<="01000100"; -- ASCII 'D'
                        when "1110" => txData_reg<="01000101"; -- ASCII 'E'
                        when "1111" => txData_reg<= "01000110"; -- ASCII 'F'
                        when others => txData_reg <="0011"& byte(7 downto 4); -- ASCII Number
                         
                    END case;
                    
                    txData2_en <= '1';
                         
                   
                    CASE byte(3 downto 0) IS
                        
                        when "1010" => txData2_reg<= "01000001"; -- ASCII 'A'
                        when "1011" => txData2_reg<= "01000010"; -- ASCII 'B'
                        when "1100" => txData2_reg<= "01000011"; -- ASCII 'C'
                        when "1101" => txData2_reg<="01000100"; -- ASCII 'D'
                        when "1110" => txData2_reg<="01000101"; -- ASCII 'E'
                        when "1111" => txData2_reg<= "01000110"; -- ASCII 'F'
                        when others => txData2_reg <="0011"& byte(3 downto 0); -- ASCII Number
                         
                    END case;
                                            
                    
                    
                    
                    txing <= 2;--MODE 2 Send
                    
                    start <='0'; -- Pause data processor until TX complete
       
                    
                        
                    nextState <= A3; 
                ELSE 
                    nextState <= A2; 
                END IF; 
                    
                    
                    
                    
                    
------------------------------------------------------------------------------------------------------------------------------------------------
 -- State to check if seqdone is high

     
			WHEN A3 => 
				IF seqDone = '1' or internal_seqdone='1' THEN -- Check if sequence is complete
				    
				    seqdone_en<='1';
				
					reset_counter <= '1'; --Reset counter
					ADONE_en <= '1'; --Save ADONE, so L & P can be used in the future
					

 
					nextState <= A2; -- All sequence complete, send back to resetstate
				ELSE -- If sequence not done, go back to A2
					nextState <= A2; 
				END IF; 
				
------------------------------------------------------------------------------------------------------------------------------------------------
 -- State to save dataresults & maxindex to registers for future use
				
	
			    
			
------------------------------------------------------------------------------------------------------------------------------------------------
 --Start of L command
			WHEN L1 =>
			    USEcounter <= '1';
	            IF count = 7 THEN -- Wait until count is 7
	               nextState<=RESETSTATE; --Send back one count is 7
	            ELSE

                    txData_en <= '1'; 
                    txData2_en <= '1'; 
                   
            
                   

                    CASE dataresults(count)(7 downto 4) IS
                        
                        when "1010" => txData_reg<= "01000001"; -- ASCII 'A'
                        when "1011" => txData_reg<= "01000010"; -- ASCII 'B'
                        when "1100" => txData_reg<= "01000011"; -- ASCII 'C'
                        when "1101" => txData_reg<="01000100"; -- ASCII 'D'
                        when "1110" => txData_reg<="01000101"; -- ASCII 'E'
                        when "1111" => txData_reg<= "01000110"; -- ASCII 'F'
                        when others => txData_reg <="0011"& dataresults(count)(7 downto 4); -- ASCII Number
                         
                    END case;
                    
                    txData2_en <= '1';
                         
                   
                    CASE dataresults(count)(3 downto 0) IS
                        
                        when "1010" => txData2_reg<= "01000001"; -- ASCII 'A'
                        when "1011" => txData2_reg<= "01000010"; -- ASCII 'B'
                        when "1100" => txData2_reg<= "01000011"; -- ASCII 'C'
                        when "1101" => txData2_reg<="01000100"; -- ASCII 'D'
                        when "1110" => txData2_reg<="01000101"; -- ASCII 'E'
                        when "1111" => txData2_reg<= "01000110"; -- ASCII 'F'
                        when others => txData2_reg <="0011"& dataresults(count)(3 downto 0); -- ASCII Number
                         
                    END case;
                                            
                    

				   txing<= 2;--Enable TX
				   nextState <= L1; --Repeat state
				   
				END IF;         
			

------------------------------------------------------------------------------------------------------------------------------------------------
 --Start of P command
			WHEN P1 =>
			    reset_counter <= '1'; -- Reset counter
	
	            
	            

                txData_en <= '1'; 
                txData2_en <= '1'; 
                   
 
                

                CASE dataresults(3)(7 downto 4) IS
                    
                    when "1010" => txData_reg<= "01000001"; -- ASCII 'A'
                    when "1011" => txData_reg<= "01000010"; -- ASCII 'B'
                    when "1100" => txData_reg<= "01000011"; -- ASCII 'C'
                    when "1101" => txData_reg<="01000100"; -- ASCII 'D'
                    when "1110" => txData_reg<="01000101"; -- ASCII 'E'
                    when "1111" => txData_reg<= "01000110"; -- ASCII 'F'
                    when others => txData_reg <="0011"& dataresults(3)(7 downto 4); -- ASCII Number
                     
                END case;
                
                txData2_en <= '1';
                     
                
                CASE dataresults(3)(3 downto 0) IS
                    
                    when "1010" => txData2_reg<= "01000001"; -- ASCII 'A'
                    when "1011" => txData2_reg<= "01000010"; -- ASCII 'B'
                    when "1100" => txData2_reg<= "01000011"; -- ASCII 'C'
                    when "1101" => txData2_reg<="01000100"; -- ASCII 'D'
                    when "1110" => txData2_reg<="01000101"; -- ASCII 'E'
                    when "1111" => txData2_reg<= "01000110"; -- ASCII 'F'
                    when others => txData2_reg <="0011"& dataresults(3)(3 downto 0); -- ASCII Number
                     
                END case;
                                            
                    
                    
                    
                txing <= 2;--MODE 2 Send
                    


	         
	            
	            nextState <= P2;
------------------------------------------------------------------------------------------------------------------------------------------------
-- State to send space key	            
	        WHEN P2 => 
	           USEcounter <= '0';
	            IF count = 3 THEN
	           
	               nextState<=RESETSTATE; --Send back
	           
	           ELSE
	           	   txData_en <= '1'; 
                   txData_reg <= "00100000"; -- set txdata to received (Send back what user set)
					
				   txing<= 1; --Enable send
				   
				   nextState<=P3;
				 
			   END IF;
------------------------------------------------------------------------------------------------------------------------------------------------
--State to send corresponding byte in maxindex			   
		   WHEN P3=> 
		        USEcounter <= '1';
		        txData_en <= '1'; 
		        txData_reg <="0011" & maxIndex_store(2 - count);-- set txdata to corresponding byte in maxindex	
		        txing<= 1;--enable send
		        
		        nextState<=P2; -- Set next state to P2 for adding space
		        
		    
	               
	               
	           
	           
	           
	            
	            
			      

				
------------------------------------------------------------------------------------------------------------------------------------------------
--State to wait until single TX is complete, this state runs whenever txing is set to 1 or waitingtx is set to 1			    
			WHEN WAITFORTX => -- State to wait for TX to complete
			    USEcounter <= '0';--Pause counter
			    

			    

			    IF txdone ='1' and waitingtx_reg = 0 THEN -- Wait for tx not previously ran
                    txnow <='1';
                    waitingtx <=1;
                    txing<=0;
                
                END IF;   
      

			    IF txdone = '1' and waitingtx_reg = 1 THEN -- Wait for tx previously ran
			        waitingtx <=0;
			        txnow <= '0';
			        txing<=0;
			        
			    

			    END IF;
	
			    
			    
			    --If seqdone is sent during this state, it stores the seqdone

		        IF seqdone ='1' THEN
		             seqdone_en<='1';
		             txnow<='0';
		             txing<=0;
		             waitingtx<=0;
		             
		             
		        END IF;
		        
 ------------------------------------------------------------------------------------------------------------------------------------------------

--State to wait until 2 TX are complete, this state runs whenever txing is set to 2 or waitingtx is set to 2		    
			WHEN WAITFORDOUBLETX => -- State to wait for 2 TX to complete
			    USEcounter <= '0';--Pause counter
			    

			    

			    IF txdone ='1' and waitingtx_reg = 0 THEN -- Wait for tx not previously ran
                    txnow <='1';
                    waitingtx <=2;
                    txing<=0;
                
                END IF;   
      

			    IF txdone = '1' and waitingtx_reg = 2 THEN -- Wait for double tx previously ran
			        waitingtx <=0;
			        txnow <= '0';
			        txing<=1;
			        txdata_en<='1';
			        txdata_reg<=txdata2;
			        
			    

			    END IF;
	
			    
			    
			    --If seqdone is sent during this state, it stores the seqdone

		        IF seqdone ='1' THEN
		             seqdone_en<='1';
		             txnow<='0';
		             txing<=0;
		             waitingtx<=0;
		             
		             
		        END IF;		    
		      
			 
 ------------------------------------------------------------------------------------------------------------------------------------------------
--Others go back to init
			WHEN OTHERS => 
				nextState <= RESETSTATE; 
 
		END CASE; 
 
	END PROCESS; 
 
	----------------------------------------------------- 
	reg : PROCESS (clk, numWords_en, numWords_bcd_reg, numWords_bcd_reset, ADONE_en, txData_en, cmd_mode_en,internal_seqdone,seqdone_en,waitingtx_reg,dataresults_reg,maxindex_reg)
	BEGIN
		IF rising_edge(clk) THEN
		
		--Store numwords BCD on registers

		    IF numWords_en = '1' THEN
		      numWords_bcd(0) <= numWords_bcd_reg(2);
		      numWords_bcd(1) <= numWords_bcd_reg(1);
		      numWords_bcd(2) <= numWords_bcd_reg(0);
			END IF;
			
		--Store dataresults and maxindex on registers
			
			IF store_en ='1' THEN
			    dataresults_store<=dataresults_reg;
			    maxindex_store<=maxindex_reg;
			 
			END IF;
		--Store seqdone for internal use
			
			IF seqdone_en ='1' THEN
			    internal_seqdone<='1';
			    
			ELSE
			    internal_seqdone<='0';
			    
			END IF;
			
	--Store waitingtx 
			IF waitingtx=1 THEN
			    waitingtx_reg<=1;
			ELSIF waitingtx=2 then
			    waitingtx_reg<=2;
			ELSE
			    waitingtx_reg<=0;
			END IF;
 
             --Store txdata onto register
			IF txData_en = '1' THEN
				txData <= txData_reg;
			END IF;

			IF txData2_en = '1' THEN
				txData2 <= txData2_reg;
			END IF;			
			
            --Stores which command was selected
			IF cmd_mode_en = '1' THEN
				cmd_mode <= cmd_mode_reg;
			END IF;
 
			IF ADONE_en = '1' THEN -- If A done, then it stores for ever that A is DONE
				ADONE <= ADONE_reg;		

				
			END IF;
		END IF;
	END PROCESS;
 
 
 	----------------------------------------------------- 

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
	seq_state : PROCESS (clk, reset, txing, txdone, waitingtx) 
	BEGIN
		IF rising_edge(clk) THEN 
			curState <= nextState; 
		END IF; 
		

		IF (txing =1 OR waitingtx = 1)  AND rising_edge(clk) THEN -- If the TX module is sending, then set state to wait for tx
		     curState <= WAITFORTX;
		END IF;
		
		IF (txing =2 OR waitingtx = 2)  AND rising_edge(clk) THEN -- If the TX module is sending, then set state to wait for tx
		     curState <= WAITFORDOUBLETX;
		END IF;

		IF rising_edge(clk) and reset = '1' THEN 
			curState <= RESETSTATE; -- if reset is 1, go back to resetstate
	    END IF;
	    
	END PROCESS; 
 
	END arch_cmdProc; 
