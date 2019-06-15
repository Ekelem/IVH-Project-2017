
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.vga_controller_cfg.all;
use work.lightsout_pack.ALL;

architecture main of tlv_pc_ifc is

   signal vga_mode  : std_logic_vector(60 downto 0); -- default 640x480x60

   signal irgb : std_logic_vector(8 downto 0);

   signal row : std_logic_vector(11 downto 0);
   signal col : std_logic_vector(11 downto 0);
	
	signal INTERN_RESET : std_logic :='0';
	signal MENU : std_logic :='1';
	signal SELECT_VAR : std_logic_vector(1 downto 0):="00";
	
	signal keyboard_keys		: std_logic_vector(15 downto 0);
   signal keyboard_vld			: std_logic;
   signal keys 	            : std_logic_vector (4 downto 0);
	
	signal EN_CNT : STD_LOGIC := '0';
	signal NUMB1 : STD_LOGIC_VECTOR (3 downto 0) := "0000";
	signal NUMB2 : STD_LOGIC_VECTOR (3 downto 0) := "0000";
	signal NUMB3 : STD_LOGIC_VECTOR (3 downto 0) := "0000";
	signal CARRY : STD_LOGIC := '0';
	
	signal char_data0 : std_logic;
	signal char_data1 : std_logic;
	signal char_data2 : std_logic;
	
	signal char_dataA : std_logic;
	signal char_dataB : std_logic;
	signal char_dataC : std_logic;
	signal char_dataD : std_logic;
	
	constant IDX_TOP    		: natural := 0;
	constant IDX_LEFT   		: natural := 1;
	constant IDX_RIGHT  		: natural := 2;
	constant IDX_BOTTOM 		: natural := 3;
	constant IDX_ENTER  		: natural := 4;
	
	constant SIZE				: natural := 5;
	
	type cells_table is array(0 to SIZE - 1) of std_logic_vector(SIZE - 1 downto 0);
	signal cells_sel 		: cells_table := ( others => (others => '0'));
	signal cells_act 		: cells_table := ( others => (others => '0'));
	
	signal cells_sel_initA		: cells_table := ( "00000", "00000", "00100", others => (others => '0'));
	signal cells_act_initA		: cells_table := ( "10001", "01010", "00100", "01010", "10001");

	type cells_idx is array(0 to SIZE - 1) of std_logic_vector(SIZE*4 - 1 downto 0);
	signal cells_sel_idx : cells_idx := (others => (others => '0'));
	signal cells_act_idx : cells_idx := (others => (others => '0'));
	signal hf : std_logic_vector(3 downto 0);
   
begin

   -- Nastaveni grafickeho rezimu (640x480, 60 Hz refresh)
   setmode(r640x480x60, vga_mode);

   vga: entity work.vga_controller(arch_vga_controller) 
      generic map (REQ_DELAY => 1)
      port map (
         CLK    => CLK, 
         RST    => RESET,
         ENABLE => '1',
         MODE   => vga_mode,

         DATA_RED    => irgb(8 downto 6),
         DATA_GREEN  => irgb(5 downto 3),
         DATA_BLUE   => irgb(2 downto 0),
         ADDR_COLUMN => col,
         ADDR_ROW    => row,

         VGA_RED   => RED_V,
         VGA_BLUE  => BLUE_V,
         VGA_GREEN => GREEN_V,
         VGA_HSYNC => HSYNC_V,
         VGA_VSYNC => VSYNC_V
      );

  counter: entity work.cnt_decimal
      port map (
         CLK 		=> CLK, 
         RST		=> INTERN_RESET,
         EN			=> EN_CNT,
         NUMB1		=> NUMB1,
         NUMB2		=> NUMB2,
         NUMB3		=> NUMB3,
			CARRY		=> CARRY
      );

	
	cells: for X in 0 to SIZE - 1 generate
		row: for Y in 0 to SIZE - 1 generate
			--active_cell: if X = 2 and Y = 2 generate
				active_cell: entity work.cell 
				generic map(
					MASK 		=> getmask(X, Y, SIZE, SIZE)
				)

				port map(
					CLK				=> CLK,
					RESET 			=> INTERN_RESET,
					ACTIVE 			=> cells_act(Y)(X),
					SELECTED 		=> cells_sel(Y)(X),

					KEYS 			=> keys,
					--	IDX_TOP => keyboard_keys(4),
					--	IDX_BOTTOM => keyboard_keys(6),
					--	IDX_LEFT => keyboard_keys(1),
					--	IDX_RIGHT => keyboard_keys(9),
					--	IDX_ENTER => keyboard_keys(5)),
					
					INVERT_REQ_OUT(IDX_TOP)		=> cells_act_idx((Y-1) mod SIZE)(X * (SIZE - 1) + IDX_BOTTOM),
					INVERT_REQ_OUT(IDX_LEFT)	=> cells_act_idx(Y)(((X-1) mod SIZE) * (SIZE -1) + IDX_RIGHT),
					INVERT_REQ_OUT(IDX_RIGHT)	=> cells_act_idx(Y)(((X+1) mod SIZE) * (SIZE -1) + IDX_LEFT),
					INVERT_REQ_OUT(IDX_BOTTOM)	=> cells_act_idx((Y+1) mod SIZE)(X * (SIZE - 1) + IDX_TOP),
					
					SELECT_REQ_OUT(IDX_TOP)		=> cells_sel_idx((Y-1) mod SIZE)(X * (SIZE - 1) + IDX_BOTTOM),
					SELECT_REQ_OUT(IDX_LEFT)	=> cells_sel_idx(Y)(((X-1) mod SIZE) * (SIZE -1) + IDX_RIGHT),
					SELECT_REQ_OUT(IDX_RIGHT)	=> cells_sel_idx(Y)(((X+1) mod SIZE) * (SIZE -1) + IDX_LEFT),
					SELECT_REQ_OUT(IDX_BOTTOM)	=> cells_sel_idx((Y+1) mod SIZE)(X * (SIZE - 1) + IDX_TOP),
					
					INVERT_REQ_IN		=> cells_act_idx(Y)(X * 4 + 3 downto X * 4),
					
					SELECT_REQ_IN		=> cells_sel_idx(Y)(X * 4 + 3 downto X * 4),

					INIT_ACTIVE		=> cells_act_initA(Y)(X),
					INIT_SELECTED 	=> cells_sel_initA(Y)(X)
				);

		end generate;
	end generate;
	
   -- Keyboard controller
   kbrd_ctrl: entity work.keyboard_controller(arch_keyboard)
      port map (
         CLK => SMCLK,
         RST => RESET,

         DATA_OUT => keyboard_keys(15 downto 0),
         DATA_VLD => keyboard_vld,
         
         KB_KIN   => KIN,
         KB_KOUT  => KOUT
      );
	
   process(col, row)
   		variable x: std_logic_vector(11 downto 0);
   		variable y: std_logic_vector(11 downto 0);
    begin
    	x := col + conv_std_logic_vector(32, 12);	--offset_x = 32
    	y := row + conv_std_logic_vector(32, 12);		--offset_y = 32
	
		irgb <= "000000000";
		if (MENU = '1') then
			if row (11 downto 7) = "00001" then
				if col (11 downto 6) = "000011" then
					if char_dataA='1' then
						if SELECT_VAR = "00" then
							irgb <= "111111111";
						else
							irgb <= "010010010";
						end if;
					end if;
				end if;
				if col (11 downto 6) = "000100" then
					if char_dataB='1' then
						if SELECT_VAR = "01" then
							irgb <= "111111111";
						else
							irgb <= "010010010";
						end if;
					end if;
				end if;
				if col (11 downto 6) = "000101" then
					if char_dataC='1' then
						if SELECT_VAR = "10" then
							irgb <= "111111111";
						else
							irgb <= "010010010";
						end if;
					end if;
				end if;
				if col (11 downto 6) = "000110" then
					if char_dataD='1' then
						if SELECT_VAR = "11" then
							irgb <= "111111111";
						else
							irgb <= "010010010";
						end if;
					end if;
				end if;
			end if;
		
		else
		
    	x := col - conv_std_logic_vector(160, 12);	--offset_x = 160
    	y := row - conv_std_logic_vector(80, 12);		--offset_y = 80

			if (x(11 downto 9) = "000") and ((x(8) and x(7)) /= '1') and ((x(8) and x(6)) /= '1') and (y(11 downto 9) = "000") and ((y(8) and y(7)) /= '1') and ((y(8) and y(6)) /= '1') and x(5 downto 1) /= "11111" and y(5 downto 1) /= "11111" then
    		if cells_act(conv_integer(y(8 downto 6)))(conv_integer(x(8 downto 6))) = '1' then
			irgb <= "000000111";
	    	else
	    		irgb <= "111000000";
    		end if;
			y := y -16;
			x := x -16;
			if cells_sel(conv_integer(y(8 downto 6)))(conv_integer(x(8 downto 6))) = '1' and y(5) = '0' and x(5) = '0' then
    			irgb <= "000111111";
			end if;
			y := y +16;
			x := x +16;
			else
				
				if row (11 downto 5) = "00111" then
					if col (11 downto 4) = "100000" then
						if char_data0='1' then
							irgb <= "111111111";
						end if;
					end if;
					
					if col (11 downto 4) = "100001" then
						if char_data1='1' then
							irgb <= "111111111";
						end if;
					end if;
					
					if col (11 downto 4) = "100010" then
						if char_data2='1' then
							irgb <= "111111111";
						end if;
					end if;
				end if;
			end if;
		end if;
    end process;
	 
   chardec0 : entity work.char_rom
      port map (
         ADDRESS => NUMB3,
         ROW => row(4 downto 1),
         COLUMN => col(3 downto 1),
         DATA => char_data0
      );
		
   chardec1 : entity work.char_rom --abc
      port map (
         ADDRESS => NUMB2,
         ROW => row(4 downto 1),
         COLUMN => col(3 downto 1),
         DATA => char_data1
      );
		
   chardec2 : entity work.char_rom
      port map (
         ADDRESS => NUMB1,
         ROW => row(4 downto 1),
         COLUMN => col(3 downto 1),
         DATA => char_data2
      );
		
   variantA : entity work.char_rom
      port map (
         ADDRESS => "1010",
         ROW => row(6 downto 3),
         COLUMN => col(5 downto 3),
         DATA => char_dataA
      );
		
   variantB : entity work.char_rom
      port map (
         ADDRESS => "1011",
         ROW => row(6 downto 3),
         COLUMN => col(5 downto 3),
         DATA => char_dataB
      );
		
   variantC: entity work.char_rom
      port map (
         ADDRESS => "1100",
         ROW => row(6 downto 3),
         COLUMN => col(5 downto 3),
         DATA => char_dataC
      );
		
   variantD : entity work.char_rom
      port map (
         ADDRESS => "1101",
         ROW => row(6 downto 3),
         COLUMN => col(5 downto 3),
         DATA => char_dataD
      );
		
	
   keyboard_proc: process(CLK, RESET)
      variable in_access : std_logic := '0';
   begin
      if CLK'event and CLK='1' then 
		if MENU = '1' then
			keys <= "00000";
			EN_CNT <= '0';
			INTERN_RESET <= RESET;
				if in_access='0' then
					if keyboard_vld='1' then 
						in_access:='1';
						if keyboard_keys(11)='1' then    -- key #
							MENU <= '0';
							INTERN_RESET <= '1';
						elsif keyboard_keys(12)='1' then    -- key A
							SELECT_VAR <= "00";
							cells_sel_initA <= ( "00000", "00000", "00100", others => (others => '0'));
							cells_act_initA <= ( "10001", "01010", "00100", "01010", "10001");
						elsif keyboard_keys(13)='1' then    -- key B
							SELECT_VAR <= "01";
							cells_sel_initA <= ( "00000", "00000", "00100", others => (others => '0'));
							cells_act_initA <= ( "10100", "00100", "00100", "00100", "00101");
						elsif keyboard_keys(14)='1' then    -- key C
							SELECT_VAR <= "10";
							cells_sel_initA <= ( "00000", "00000", "00100", others => (others => '0'));
							cells_act_initA <= ( "00000", "00100", "01110", "00100", "00000");
						elsif keyboard_keys(15)='1' then    -- key D
							SELECT_VAR <= "11";
							cells_sel_initA <= ( "00000", "00000", "00100", others => (others => '0'));
							cells_act_initA <= ( "11111", "00000", "11111", "00000", "11111");
						end if;
					end if;
            else
            if keyboard_vld='0' then 
               in_access:='0';
            end if;
			end if;
		else
			keys <= "00000";
			EN_CNT <= '0';
			INTERN_RESET <= RESET;
         if in_access='0' then
            if keyboard_vld='1' then 
               in_access:='1';
               if keyboard_keys(9)='1' then  -- key 6
                  keys <= "00100";
               elsif keyboard_keys(1)='1' then  -- key 4
                  keys <= "00010";
               elsif keyboard_keys(4)='1' then  -- key 2
                  keys <= "00001";
               elsif keyboard_keys(6)='1' then  -- key 8
                  keys <= "01000";
               elsif keyboard_keys(5)='1' then     -- key 5
                  keys <= "10000";
						if (CARRY /= '1') then
							EN_CNT <= '1';
						end if;
               
               elsif keyboard_keys(11)='1' then    -- key #
						MENU <= '1';                   
               end if;
            end if;
         else
            if keyboard_vld='0' then 
               in_access:='0';
            end if;
         end if;
		end if;
		
		end if;
      
   end process;

end main;

