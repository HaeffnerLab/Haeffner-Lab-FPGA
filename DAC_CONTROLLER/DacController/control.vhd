library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;
library UNISIM;
use UNISIM.VComponents.all;
entity control is
    Port ( 
		LED : out  STD_LOGIC_VECTOR (7 downto 0);
		
		---OK Stuff----
		hi_in     : in    STD_LOGIC_VECTOR(7 downto 0);
		hi_out    : out   STD_LOGIC_VECTOR(1 downto 0);
		hi_inout  : inout STD_LOGIC_VECTOR(15 downto 0);
		hi_muxsel : out   STD_LOGIC;
		
		clk_100 : in  STD_LOGIC;
      clk : out  STD_LOGIC_VECTOR (1 downto 0);
      dat : out  STD_LOGIC_VECTOR (1 downto 0);
      rst : out  STD_LOGIC_VECTOR (1 downto 0));
end control;

architecture Behavioral of control is

	------ fifo to store voltage sets from pc ---------
	component fifo PORT (
		rst : IN STD_LOGIC;
		wr_clk : IN STD_LOGIC;
		rd_clk : IN STD_LOGIC;
		din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		wr_en : IN STD_LOGIC;
		rd_en : IN STD_LOGIC;
		dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		full : OUT STD_LOGIC;
		empty : OUT STD_LOGIC);
	end component;
	
	-- Target interface bus:
	signal ti_clk    : STD_LOGIC;
	signal ok1       : STD_LOGIC_VECTOR(30 downto 0);
	signal ok2       : STD_LOGIC_VECTOR(16 downto 0);
	signal ok2s      : STD_LOGIC_VECTOR(17-1 downto 0);

	------ Trigger in ------
	signal ep40wire        : STD_LOGIC_VECTOR(15 downto 0);
	--- These are for pipe logic ----
	
	signal pipe_in_write   : STD_LOGIC;
	signal pipe_in_ready   : STD_LOGIC;
	signal pipe_in_data    : STD_LOGIC_VECTOR(15 downto 0);
	signal bs_in, bs_out   : STD_LOGIC;

	----- dacbox fifo ----
	signal   fifo_rst 		: STD_LOGIC;
	signal	fifo_rd_clk	: STD_LOGIC;
	signal	fifo_rd_en		: STD_LOGIC;
	signal	fifo_dout		: STD_LOGIC_VECTOR(31 downto 0);
	signal	fifo_full		: STD_LOGIC;
	signal	fifo_empty		: STD_LOGIC;
	signal   fifo_wr_en    : STD_LOGIC;

	------- TO DAC -------
	signal dac_clk : STD_LOGIC_VECTOR (1 downto 0);
	signal dac_data : STD_LOGIC_VECTOR (1 downto 0);
	signal dac_rst :  STD_LOGIC_VECTOR (1 downto 0);
	signal cur_pos : STD_LOGIC_VECTOR (4 downto 0);
	signal cur_set : STD_LOGIC_VECTOR (9 downto 0);
	signal cur_voltage : STD_LOGIC_VECTOR (15 downto 0);
	
	signal clk_slow : STD_LOGIC := '0';
	signal clk_1           : STD_LOGIC := '0';
	

begin

fifo1: fifo port map(
		rst=>fifo_rst,
		wr_en => pipe_in_write,
		wr_clk=>ti_clk,
		rd_clk=>fifo_rd_clk,
		din=> pipe_in_data,
		rd_en=> fifo_rd_en, 
		dout=> fifo_dout,
		full=> fifo_full,
		empty=> fifo_empty);

	fifo_rst <= ep40wire(8);
	pipe_in_ready <= '1';
		PROCESS
		VARIABLE count: integer range 0 to 10001 := 0;
	begin
		wait until rising_edge(clk_100);
		count := count + 1;
		IF (count = 500) THEN 
			clk_slow <= NOT clk_slow;
			count := 0;
		END IF;
	end PROCESS;
	
		PROCESS
		VARIABLE count: integer range 0 to 10001 := 0;
	begin
		wait until rising_edge(clk_100);
		count := count + 1;
		IF (count = 100) THEN 
			clk_1<= NOT clk_1;
			count := 0;
		END IF;
	end PROCESS;

	process
		variable cnt_serial : INTEGER range -6 to 116 := 0;
		variable cnt_fifo : INTEGER range 0 to 3 := 0;
		variable c : INTEGER range 0 to 1 := 0;
		VARIABLE pos : integer range 0 to 28 := 0;
		VARIABLE actual_pos : std_logic_vector(4 downto 0);
		variable test: integer range 0 to 28 := 0;
	begin
		wait until rising_edge(clk_slow);
		pos := CONV_INTEGER(UNSIGNED (cur_pos));
		if (pos < 20) then -- dacbox chip number
			c := 0;
			actual_pos := cur_pos;
		else
			c := 1;
			if (pos = 20) then
				actual_pos := "00001";
			elsif (pos = 21) then
				actual_pos := "00010";
			elsif (pos = 22) then
				actual_pos := "00011";
			elsif (pos = 23) then
				actual_pos := "00100";
			elsif (pos = 24) then
				actual_pos := "00101";
			elsif (pos = 25) then
				actual_pos := "00110";
			elsif (pos = 26) then
				actual_pos := "00111";
			elsif (pos = 27) then
				actual_pos := "01000";
			elsif (pos = 28) then
				actual_pos := "01001";
			end if;
		end if;
		

		case cnt_serial is
		
			when -6 => fifo_rd_en <= '0'; -- see if something's in the fifo
						  fifo_rd_clk <= '1';
			when -5 => fifo_rd_clk <= '0';
			when -4 => if (fifo_empty = '1') then -- 1 is empty
								cnt_serial := 115; -- go to the end
							end if;
			when -3 => fifo_rd_en <= '1';
						  fifo_rd_clk <= '1';
			when -2 => fifo_rd_clk <= '0';
			when -1 => cur_pos <= fifo_dout(15 downto 11);
						  --cur_set <= "0000000001";
						  --cur_voltage <= "1111111111111111";
						  --c := 0;
						  cur_set <= fifo_dout(10 downto 1);
						  cur_voltage <= fifo_dout(31 downto 16);
						  --cur_pos <= "10101";
						  --cur_set <= "0101010101";
						  --cur_voltage <= "1010101010101010";
			-- chip select --
			when 0 => dac_rst(c) <= '1';

			when 1 => dac_clk(c) <= '0';
			when 2 => dac_rst(c) <= '0';
			when 3 => dac_data(c) <= '1'; -- start bit
			when 4 => dac_clk(c) <= '1'; -- start bit clocked
			
			-- set --
			when 5 => dac_clk(c) <= '0';
			when 6 => dac_data(c) <= actual_pos(4);
			when 7 => dac_clk(c) <= '1'; -- clocked
			
			when 8 => dac_clk(c) <= '0';
			when 9 => dac_data(c) <= actual_pos(3);
			when 10 => dac_clk(c) <= '1'; -- clocked
			
			when 11 => dac_clk(c) <= '0';
			when 12 => dac_data(c) <= actual_pos(2);
			when 13 => dac_clk(c) <= '1'; -- clocked
			
			when 14 => dac_clk(c) <= '0';
			when 15 => dac_data(c) <= actual_pos(1);
			when 16 => dac_clk(c) <= '1'; -- clocked
			
			when 17 => dac_clk(c) <= '0';
			when 18 => dac_data(c) <= actual_pos(0);
			when 19 => dac_clk(c) <= '1'; -- clocked
			
			-- set number --
			
			when 20 => dac_clk(c) <= '0';
			when 21 => dac_data(c) <= cur_set(9);
			when 22 => dac_clk(c) <= '1'; -- clocked

			when 23 => dac_clk(c) <= '0';
			when 24 => dac_data(c) <= cur_set(8);
			when 25 => dac_clk(c) <= '1'; -- clocked

			when 26 => dac_clk(c) <= '0';
			when 27 => dac_data(c) <= cur_set(7);
			when 28 => dac_clk(c) <= '1'; -- clocked
			
			when 29 => dac_clk(c) <= '0';
			when 30 => dac_data(c) <= cur_set(6);
			when 31 => dac_clk(c) <= '1'; -- clocked
			
			when 32 => dac_clk(c) <= '0';
			when 33 => dac_data(c) <= cur_set(5);
			when 34 => dac_clk(c) <= '1'; -- clocked

			when 35 => dac_clk(c) <= '0';
			when 36 => dac_data(c) <= cur_set(4);
			when 37 => dac_clk(c) <= '1'; -- clocked

			when 38 => dac_clk(c) <= '0';
			when 39 => dac_data(c) <= cur_set(3);
			when 40 => dac_clk(c) <= '1'; -- clocked
			
			when 41 => dac_clk(c) <= '0';
			when 42 => dac_data(c) <= cur_set(2);
			when 43 => dac_clk(c) <= '1'; -- clocked
			
			when 44 => dac_clk(c) <= '0';
			when 45 => dac_data(c) <= cur_set(1);
			when 46 => dac_clk(c) <= '1'; -- clocked
			
			when 47 => dac_clk(c) <= '0';
			when 48 => dac_data(c) <= cur_set(0);
			when 49 => dac_clk(c) <= '1'; -- clocked
			
			-- voltage --
			when 50 => dac_clk(c) <= '0';
			when 51 => dac_data(c) <= cur_voltage(15);
			when 52 => dac_clk(c) <= '1'; -- clocked
			
			when 53 => dac_clk(c) <= '0';
			when 54 => dac_data(c) <= cur_voltage(14);
			when 55 => dac_clk(c) <= '1'; -- clocked
			
			when 56 => dac_clk(c) <= '0';
			when 57 => dac_data(c) <= cur_voltage(13);
			when 58 => dac_clk(c) <= '1'; -- clocked

			when 59 => dac_clk(c) <= '0';
			when 60 => dac_data(c) <= cur_voltage(12);
			when 61 => dac_clk(c) <= '1'; -- clocked
			
			when 62 => dac_clk(c) <= '0';
			when 63 => dac_data(c) <= cur_voltage(11);
			when 64 => dac_clk(c) <= '1'; -- clocked
			
			when 65 => dac_clk(c) <= '0';
			when 66 => dac_data(c) <= cur_voltage(10);
			when 67 => dac_clk(c) <= '1'; -- clocked
			
			when 68 => dac_clk(c) <= '0';
			when 69 => dac_data(c) <= cur_voltage(9);
			when 70 => dac_clk(c) <= '1'; -- clocked
			
			when 71 => dac_clk(c) <= '0';
			when 72 => dac_data(c) <= cur_voltage(8);
			when 73 => dac_clk(c) <= '1'; -- clocked

			when 74 => dac_clk(c) <= '0';
			when 75 => dac_data(c) <= cur_voltage(7);
			when 76 => dac_clk(c) <= '1'; -- clocked

			when 77 => dac_clk(c) <= '0';
			when 78 => dac_data(c) <= cur_voltage(6);
			when 79 => dac_clk(c) <= '1'; -- clocked
			
			when 80 => dac_clk(c) <= '0';
			when 81 => dac_data(c) <= cur_voltage(5);
			when 82 => dac_clk(c) <= '1'; -- clocked
			
			when 83 => dac_clk(c) <= '0';
			when 84 => dac_data(c) <= cur_voltage(4);
			when 85 => dac_clk(c) <= '1'; -- clocked
			
			when 86 => dac_clk(c) <= '0';
			when 87 => dac_data(c) <= cur_voltage(3);
			when 88 => dac_clk(c) <= '1'; -- clocked
			
			when 89 => dac_clk(c) <= '0';
			when 90 => dac_data(c) <= cur_voltage(2);
			when 91 => dac_clk(c) <= '1'; -- clocked
			
			when 92 => dac_clk(c) <= '0';
			when 93 => dac_data(c) <= cur_voltage(1);
			when 94 => dac_clk(c) <= '1'; -- clocked
			
			when 95 => dac_clk(c) <= '0';
			when 96 => dac_data(c) <= cur_voltage(0);
			when 97 => dac_clk(c) <= '1'; -- clocked
			
			-- parity bit --
			when 98 => dac_clk(c) <= '0';
			when 99 => dac_data(c) <= (actual_pos(0) xor actual_pos(1) xor actual_pos(2) xor actual_pos(3) xor actual_pos(4)
												xor cur_set(0) xor cur_set(1) xor cur_set(2) xor cur_set(3) xor cur_set(4)
												xor cur_set(5) xor cur_set(6) xor cur_set(7) xor cur_set(8) xor cur_set(9)
												xor cur_voltage(0) xor cur_voltage(1) xor cur_voltage(2) xor cur_voltage(3)
												xor cur_voltage(4) xor cur_voltage(5) xor cur_voltage(6) xor cur_voltage(7)
												xor cur_voltage(8) xor cur_voltage(9) xor cur_voltage(10) xor cur_voltage(11)
												xor cur_voltage(12) xor cur_voltage(13) xor cur_voltage(14) xor cur_voltage(15));
			when 100 => dac_clk(c) <= '1'; -- parity bit clocked
			
			-- stop bit --
			when 101 => dac_clk(c) <= '0';
			when 102 => dac_data(c) <= '1';
			when 103 => dac_clk(c) <= '1'; -- stop bit clocked
			-- a few delay clock cycles
			when 104 => dac_clk(c) <= '0';
			when 105 => dac_clk(c) <= '1';
			when 106 => dac_clk(c) <= '0';
			when 107 => dac_clk(c) <= '1';
			when 108 => dac_clk(c) <= '0';
			when 109 => dac_clk(c) <= '1';
			when 110 => dac_clk(c) <= '0';
			when 111 => dac_clk(c) <= '1';
			when 112 => dac_clk(c) <= '0';
			when 113 => dac_clk(c) <= '1';
			when 114 => dac_clk(c) <= '0';
			when 115 => dac_rst(c) <= '1'; -- turn off the chip select
			when 116 => dac_rst(c) <= '1'; -- we never get here
			end case;
			cnt_serial := cnt_serial + 1;
			
			if (cnt_serial = 116) then
				cnt_serial := -6;
			end if;
end process;

clk <= not (not dac_clk);
dat <= not (not dac_data);
rst <= not (not dac_rst);

--clk <= "00";
--dat <= "00";
--rst <= "00";

led(7 downto 1) <= "1111111";
led(0) <= fifo_empty;
---OK thing. Do not touch ----
hi_muxsel <= '0';

-- Instantiate the okHost and connect endpoints.
okHI : okHost port map (hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout, ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);
okWO : okWireOR    generic map (N=>1) port map (ok2=>ok2, ok2s=>ok2s);
ep40 : okTriggerIn  port map (ok1=>ok1, ep_addr=>x"40", ep_clk=>clk_1, ep_trigger=>ep40wire);
ep82 : okBTPipeIn  port map (ok1=>ok1, ok2=>ok2s( 1*17-1 downto 0*17 ), ep_addr=>x"82", 
                             ep_write=>pipe_in_write, ep_blockstrobe=>bs_in, ep_dataout=>pipe_in_data, ep_ready=>pipe_in_ready);

end Behavioral;

