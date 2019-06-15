----------------------------------------------------------------------------------
-- Author: Erik Kelemen
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.lightsout_pack.ALL; -- vysledek z prvniho ukolu
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;


entity cell is
   GENERIC (
      MASK              : mask_t := (others => '1') -- mask_t definovano v baliku math_pack
   );
   Port ( 
      INVERT_REQ_IN     : in   STD_LOGIC_VECTOR (3 downto 0);
      INVERT_REQ_OUT    : out  STD_LOGIC_VECTOR (3 downto 0);
      
      KEYS              : in   STD_LOGIC_VECTOR (4 downto 0);
      
      SELECT_REQ_IN     : in   STD_LOGIC_VECTOR (3 downto 0);
      SELECT_REQ_OUT    : out  STD_LOGIC_VECTOR (3 downto 0);
      
      INIT_ACTIVE       : in   STD_LOGIC;
      ACTIVE            : out  STD_LOGIC;
      
      INIT_SELECTED     : in   STD_LOGIC;
      SELECTED          : out  STD_LOGIC;

      CLK               : in   STD_LOGIC;
      RESET             : in   STD_LOGIC
   );
end cell;

architecture Behavioral of cell is
  constant IDX_TOP    : NATURAL := 0; -- index sousedni bunky nachazejici se nahore v signalech *_REQ_IN a *_REQ_OUT, index klavesy posun nahoru v signalu KEYS
                                      -- tzn. 1) pokud chci poslat kurzor sousedni bunce nahore, musim nastavit na jeden hodinovy takt SELECT_REQ_OUT(IDX_TOP) na '1'
                                      --      2) pokud plati, ze KEYS(IDX_TOP)='1', pak byla stisknuta klavesa nahoru
  constant IDX_LEFT   : NATURAL := 1; -- ... totez        ...                vlevo
  constant IDX_RIGHT  : NATURAL := 2; -- ... totez        ...                vpravo
  constant IDX_BOTTOM : NATURAL := 3; -- ... totez        ...                dole
  
  constant IDX_ENTER  : NATURAL := 4; -- index klavesy v KEYS, zpusobujici inverzi bunky (enter, klavesa 5)
  
  signal INTERN_SELECT : STD_LOGIC := '1';
  signal INTERN_ACTIVE : STD_LOGIC := '0';
begin

-- Pozadavky na funkci (sekvencni chovani vazane na vzestupnou hranu CLK)
--   pri resetu se nastavi ACTIVE a SELECTED na vychozi hodnotu danou signaly INIT_ACTIVE a INIT_SELECTED
--   pokud je bunka aktivni a prijde signal z klavesnice, tak se bud presune aktivita pomoci SELECT_REQ na dalsi bunky nebo se invertuje stav bunky a jejiho okoli pomoci INVERT_REQ (klavesa ENTER)
--   pokud bunka neni aktivni a prijde signal INVERT_REQ, invertuje svuj stav
--   pozadavky do okolnich bunek se posilaji a z okolnich bunek prijimaji, jen pokud je maska na prislusne pozici v '1'

process(CLK) --RESET, ACTIVE, SELCT handling

begin
if (rising_edge(CLK)) then
	INVERT_REQ_OUT <= "0000";
	SELECT_REQ_OUT <= "0000";
	
	if (RESET = '1') then
	
		ACTIVE<=INIT_ACTIVE;
		SELECTED<=INIT_SELECTED;
		INTERN_ACTIVE <= INIT_ACTIVE;
		INTERN_SELECT <= INIT_SELECTED;
		
		
	elsif (INTERN_SELECT = '1') then
		if (KEYS(IDX_TOP) = '1') then										--KEYPRESS TOP
		
			if (MASK.top = '1') then
				SELECT_REQ_OUT(IDX_TOP) <= '1';
				INTERN_SELECT <= '0';
			end if;
			
		elsif (KEYS(IDX_LEFT) = '1') then								--KEYPRESS LEFT
		
			if (MASK.left = '1') then
				SELECT_REQ_OUT(IDX_LEFT) <= '1';
				INTERN_SELECT <= '0';
			end if;
			
		elsif (KEYS(IDX_RIGHT) = '1') then								--KEYPRESS RIGHT
		
			if (MASK.right = '1') then
				SELECT_REQ_OUT(IDX_RIGHT) <= '1';
				INTERN_SELECT <= '0';
			end if;
			
		elsif (KEYS(IDX_BOTTOM) = '1') then								--KEYPRESS BOTTOM
		
			if (MASK.bottom = '1') then
				SELECT_REQ_OUT(IDX_BOTTOM) <= '1';
				INTERN_SELECT <= '0';
			end if;
			
		elsif (KEYS(IDX_ENTER) = '1') then								--KEYPRESS ENTER
			if (MASK.top = '1') then
				INVERT_REQ_OUT(IDX_TOP) <= '1';
			end if;
			if (MASK.left = '1') then
				INVERT_REQ_OUT(IDX_LEFT) <= '1';
			end if;
			if (MASK.right = '1') then
				INVERT_REQ_OUT(IDX_RIGHT) <= '1';
			end if;
			if (MASK.bottom = '1') then
				INVERT_REQ_OUT(IDX_BOTTOM) <= '1';
			end if;
			INTERN_ACTIVE <= not INTERN_ACTIVE;
			ACTIVE <= not INTERN_ACTIVE;
		end if;
	else
		if (INVERT_REQ_IN /= 0) then
		INTERN_ACTIVE <= NOT INTERN_ACTIVE;
		ACTIVE <= NOT INTERN_ACTIVE;
		end if;
		SELECTED <= ((SELECT_REQ_IN(0) OR SELECT_REQ_IN(1)) OR ((SELECT_REQ_IN(2) OR SELECT_REQ_IN(3)) OR INTERN_SELECT));
		INTERN_SELECT <= ((SELECT_REQ_IN(0) OR SELECT_REQ_IN(1)) OR (SELECT_REQ_IN(2) OR SELECT_REQ_IN(3)));
	end if;
end if;
end process;

end Behavioral;

