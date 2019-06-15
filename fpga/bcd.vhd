library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity cnt_decimal is
    Port ( 	CLK : in  STD_LOGIC;
				RST: in STD_LOGIC;
				EN: in STD_LOGIC;
				NUMB1 : buffer  STD_LOGIC_VECTOR (3 downto 0) := "0000";
				NUMB2 : buffer  STD_LOGIC_VECTOR (3 downto 0) := "0000";
				NUMB3 : buffer  STD_LOGIC_VECTOR (3 downto 0) := "0000";
				CARRY : out STD_LOGIC);
end cnt_decimal;

architecture Behavioral of cnt_decimal is
begin
process(CLK, RST, EN)
begin
	if (RST = '1') then
		NUMB1 <= "0000" ;
		NUMB2 <= "0000" ;
		NUMB3 <= "0000" ;
		CARRY <= '0';
	elsif (CLK'event) and (CLK='1') then
		CARRY <= '0';
		if (EN = '1') then
			NUMB1 <= NUMB1 + 1;
		if (NUMB1 = 9) then
			NUMB1 <= "0000";
			NUMB2 <= NUMB2 + 1;
		end if;
		if (NUMB2 = 9) and (NUMB1 = 9) then
			NUMB2 <= "0000";
			NUMB3 <= NUMB3 + 1;
		end if;
		if (NUMB3 = 9) and (NUMB2 = 9) and (NUMB1 = 9) then
			CARRY <= '1';
		end if;
	 end if;
 end if;
end process;
end Behavioral;