-- Autor reseni: Iveta Strnadova, xstrna14

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ledc8x8 is
port ( -- Sem doplnte popis rozhrani obvodu.
	SMCLK : in std_logic; --hodinovy signal
	RESET : in std_logic; --reset signal
	ROW : out std_logic_vector(0 to 7); --output ROW, vektor, vzdy jen jedna 1 zbytek 0, signalizuje ktera rada sviti
	LED : out std_logic_vector(0 to 7) --output LED, vektor, signalizuje, ktere LED vystupu sviti a ktere ne
);
end ledc8x8;

architecture main of ledc8x8 is
	signal ROW_CNT: std_logic_vector (2 downto 0);
	signal LED_SIGNAL: std_logic_vector (7 downto 0);
	signal DISPLAY_ACTIVE: std_logic;
	signal CLK_FOR_FSM: std_logic;
	signal ADD_TO_ROW: std_logic;
    -- Sem doplnte definice vnitrnich signalu.
	type FSMstate is (first_on, temp_off, always_on);
	signal pstate : FSMstate;
	signal nstate : FSMstate;
	signal fsm_cnt: std_logic_vector (21 downto 0);
	signal cnt: std_logic_vector (7 downto 0);

begin

    -- Sem doplnte popis obvodu. Doporuceni: pouzivejte zakladni obvodove prvky
    -- (multiplexory, registry, dekodery,...), jejich funkce popisujte pomoci
    -- procesu VHDL a propojeni techto prvku, tj. komunikaci mezi procesy,
    -- realizujte pomoci vnitrnich signalu deklarovanych vyse.

    -- DODRZUJTE ZASADY PSANI SYNTETIZOVATELNEHO VHDL KODU OBVODOVYCH PRVKU,
    -- JEZ JSOU PROBIRANY ZEJMENA NA UVODNICH CVICENI INP A SHRNUTY NA WEBU:
    -- http://merlin.fit.vutbr.cz/FITkit/docs/navody/synth_templates.html.
	
	--COUNTER casu pro FINITE STATE MACHINE
	--ADDR <= cnt;
	
	fsm_counter: process(RESET, SMCLK)
	begin
		--	CLK_FOR_FSM <= '1' when (fsm_cnt="1110000100000000000000") else '0'; --posle 1, pokud napocita do pul s
		if fsm_cnt = "1110000100000000000000" then
			CLK_FOR_FSM <= '1';
		else 
			CLK_FOR_FSM <= '0';
		end if;

		if rising_edge(SMCLK) then
			if (RESET='1') then
				fsm_cnt <= (others => '0');
			else
				if (CLK_FOR_FSM='1') then
					fsm_cnt <= (others => '0');
				else
					fsm_cnt <= fsm_cnt + 1;
				end if;
			end if;
		end if;
	end process;	
	
	--FSM, tri stavy, zapnuto na pul sekundy, vypnuto na pul sekundy, zapnuto furt
	--present_state_registr
	pstatereg: process(RESET, CLK_FOR_FSM)
	begin
		if RESET = '1' then
			pstate <= first_on;
		elsif rising_edge(CLK_FOR_FSM) then
			pstate <= nstate;
		end if;
	end process;
	
	--Next State logic
	nstate_logic: process(pstate)
	begin
		-- default values
		nstate <= first_on;
		-- nstate
		case pstate is
			when first_on =>
				nstate <= temp_off;
			when temp_off =>
				nstate <= always_on;
			when always_on =>
				nstate <= always_on;
			when others => null;
		end case;
	end process;
 
	--Output logic
	output_logic: process(pstate)
	begin
		-- default values
		DISPLAY_ACTIVE <= '0';
 
		case pstate is
			when first_on =>
				DISPLAY_ACTIVE <= '1';
			when temp_off =>
				DISPLAY_ACTIVE <= '0';
			when always_on =>
				DISPLAY_ACTIVE <= '1';
			when others =>
				null;
		end case;
	end process;
	
	--COUNTER, ktery kazdou (dopln cas) posle impuls do counter na radky
 
	process(RESET, SMCLK)
	begin
		--ADD_TO_ROW <= '1' when (cnt="11111111") else '0';
		if cnt = "11111111" then
			ADD_TO_ROW <= '1';
		else
			ADD_TO_ROW <= '0';
		end if;
		
		if rising_edge(SMCLK) then
			if (RESET = '1') then
				cnt <= (others => '0');
			else
				if (ADD_TO_ROW='1') then
					cnt <= (others => '0');
				else
					cnt <= cnt + 1;
				end if;
			end if;
		end if;
	end process;
	
	--COUNTER na radky, pri impulsu od casovace COUNTER zmeni aktualni radek
	row_counter: process(ADD_TO_ROW, RESET)
	begin
		if RESET = '1' then
			ROW_CNT <= "000";
		elsif rising_edge(ADD_TO_ROW) then
			case ROW_CNT is
				when "000" => ROW_CNT <= "001";
				when "001" => ROW_CNT <= "010";
				when "010" => ROW_CNT <= "011";
				when "011" => ROW_CNT <= "100";
				when "100" => ROW_CNT <= "101";
				when "101" => ROW_CNT <= "110";
				when "110" => ROW_CNT <= "111";
				when others => ROW_CNT <= "000";
			end case;
		end if;
	end process row_counter;
	
	--MUX ktery podle counteru vyhodi na ROW vystup signal rady
	choose_row: process(ROW_CNT)
	begin
		case ROW_CNT is
			when "000" => ROW <= "10000000";
			when "001" => ROW <= "01000000";
			when "010" => ROW <= "00100000";
			when "011" => ROW <= "00010000";
			when "100" => ROW <= "00001000";
			when "101" => ROW <= "00000100";
			when "110" => ROW <= "00000010";
			when others => ROW <= "00000001";
		end case;
	end process choose_row;
	
	--MUX co podle counteru vyhodi odpovidajici signal na radek
	choose_leds: process(ROW_CNT)
	begin
		case ROW_CNT is
			when "000" => LED_SIGNAL <= "00011111";
			when "001" => LED_SIGNAL <= "10111111";
			when "010" => LED_SIGNAL <= "10111111";
			when "011" => LED_SIGNAL <= "10111000";
			when "100" => LED_SIGNAL <= "00010111";
			when "101" => LED_SIGNAL <= "11111001";
			when "110" => LED_SIGNAL <= "11111110";
			when others => LED_SIGNAL <= "11110001";
		end case;
	end process choose_leds;
	
	--MUX na vystupu, jestli se bude zobrazovat display, nebo 0
	activate_display: process (DISPLAY_ACTIVE, LED_SIGNAL)
	begin
		case DISPLAY_ACTIVE is
			when '1' => LED <= LED_SIGNAL;
			when others => LED <= "11111111";
		end case;
	end process activate_display;

end main;




-- ISID: 75579
