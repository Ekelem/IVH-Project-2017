library IEEE;
use IEEE.STD_LOGIC_1164.all;

package lightsout_pack is

type mask_t is
	record
		top        : std_logic;
		left       : std_logic;
		right      : std_logic;
		bottom     : std_logic;
end record;

function getmask(x,y : natural; COLUMNS, ROWS : natural) return mask_t;


end lightsout_pack;

package body lightsout_pack is


function getmask(x,y : natural; COLUMNS, ROWS : natural) return mask_t is
	variable mask : mask_t := ('1', '1', '1', '1');
begin
	if (x=0) then
		mask.left:='0';
	end if;
	if (x=COLUMNS-1) then
		mask.right:='0';
	end if;
	if (y=0) then
		mask.top:='0';
	end if;
	if (y=ROWS-1) then
		mask.bottom:='0';
	end if;
	return mask;
end getmask;
 
end lightsout_pack;
