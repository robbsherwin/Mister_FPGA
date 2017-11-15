library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.sdram_pkg.all;
use work.video_controller_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;
use work.target_pkg.all;

entity target_top is
  port
    (
      CLK_50M      	: in  std_logic;
		LED 				: out std_logic;
		reset 			: in  std_logic;

      AUDIO_L			: out std_logic_vector(15 downto 0);
      AUDIO_R       	: out std_logic_vector(15 downto 0);
		
      VGA_R         	: out std_logic_vector( 7 downto 0);
      VGA_G         	: out std_logic_vector( 7 downto 0);
      VGA_B         	: out std_logic_vector( 7 downto 0);
      VGA_VS        	: out std_logic;
      VGA_HS        	: out std_logic;
      VGA_DE        	: out std_logic;
		pixel_clock    : out std_logic;

		ps2Clk       	: in  std_logic;
		ps2Data       	: in  std_logic;
      joystick1 		: in  std_logic_vector( 7 downto 0);
      joystick2 		: in  std_logic_vector( 7 downto 0);
		status        	: in  std_logic_vector(31 downto 0);
      buttons     	: in  std_logic_vector( 1 downto 0)
  );    
  
end target_top;

architecture SYN of target_top is

  signal init       	: std_logic := '1';  
  signal clock_50       : std_logic;
  
  signal clkrst_i       : from_CLKRST_t;
  signal buttons_i      : from_BUTTONS_t;
  signal switches_i     : from_SWITCHES_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal flash_i        : from_FLASH_t;
  signal flash_o        : to_FLASH_t;
  signal sram_i			: from_SRAM_t;
  signal sram_o			: to_SRAM_t;	
  signal sdram_i        : from_SDRAM_t;
  signal sdram_o        : to_SDRAM_t;
  signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;
  signal audio_i        : from_AUDIO_t;
  signal audio_o        : to_AUDIO_t;
  signal ser_i          : from_SERIAL_t;
  signal ser_o          : to_SERIAL_t;
  signal project_i      : from_PROJECT_IO_t;
  signal project_o      : to_PROJECT_IO_t;
  signal platform_i     : from_PLATFORM_IO_t;
  signal platform_o     : to_PLATFORM_IO_t;
  signal target_i       : from_TARGET_IO_t;
  signal target_o       : to_TARGET_IO_t;
  signal kbd_joy0 	: std_logic_vector(9 downto 0);
 
  
  
  component keyboard
	PORT(
	  clk : in std_logic;
	  reset : in std_logic;
	  ps2_kbd_clk : in std_logic;
	  ps2_kbd_data : in std_logic;
	  joystick : out std_logic_vector (9 downto 0)
	);
  end component;
  
  
component pll50
	PORT
		(
		refclk			: IN  STD_LOGIC  := '0';
		rst				: IN  STD_LOGIC;
		outclk_0			: OUT STD_LOGIC;
		outclk_1			: OUT STD_LOGIC 	
		);
  end component;
  
begin

LED <= '1';
pixel_clock		<=clkrst_i.clk(1);
	 
u_keyboard : keyboard
    port  map(
	clk 				=> clock_50,
	reset 			=> reset,
	ps2_kbd_clk 	=> ps2Clk,
	ps2_kbd_data 	=> ps2Data,
	joystick 		=> kbd_joy0
);

pll : pll50
    port map
      (
		refclk  		=> CLK_50M,
		rst	  		=> reset,
		outclk_0		=> clock_50,			-- 20 MHz
		outclk_1		=> clkrst_i.clk(1)   -- 40 MHz video clock
		);



    clkrst_i.clk_ref <= CLK_50M;
	 clkrst_i.clk(0)	<= clock_50;

    
  -- FPGA STARTUP
	-- should extend power-on reset if registers init to '0'
	process (clock_50)
		variable count : std_logic_vector (11 downto 0) := (others => '0');
	begin
		if rising_edge(clock_50) then
			if count = X"FFF" then
				init <= '0';
			else
				count := count + 1;
				init <= '1';
			end if;
		end if;
	end process;

  clkrst_i.arst <= init or status(5) or buttons(1);
  clkrst_i.arst_n <= not clkrst_i.arst;

  GEN_RESETS : for i in 0 to 3 generate

    process (clkrst_i.clk(i), clkrst_i.arst)
      variable rst_r : std_logic_vector(2 downto 0) := (others => '0');
    begin
      if clkrst_i.arst = '1' then
        rst_r := (others => '1');
      elsif rising_edge(clkrst_i.clk(i)) then
        rst_r := rst_r(rst_r'left-1 downto 0) & '0';
      end if;
      clkrst_i.rst(i) <= rst_r(rst_r'left);
    end process;

  end generate GEN_RESETS;

		inputs_i.jamma_n.coin(1) <= kbd_joy0(3) or status(1);--ESC
		inputs_i.jamma_n.p(1).start <= kbd_joy0(1) or kbd_joy0(2) or status(2);--KB 1+2
		
		inputs_i.jamma_n.p(1).up <= not (joystick1(3) or joystick2(3) or kbd_joy0(4));
		inputs_i.jamma_n.p(1).down <= not (joystick1(2) or joystick2(2) or kbd_joy0(5));
		inputs_i.jamma_n.p(1).left <= not (joystick1(1) or joystick2(1) or kbd_joy0(6));
		inputs_i.jamma_n.p(1).right <= not (joystick1(0) or joystick2(0) or kbd_joy0(7));
		
		inputs_i.jamma_n.p(1).button(1) <= not (joystick1(4) or joystick2(4) or kbd_joy0(0)); --SPACE
		inputs_i.jamma_n.p(1).button(2) <= not (joystick1(5) or joystick2(5) or kbd_joy0(8)); --Left Alt
		inputs_i.jamma_n.p(1).button(3) <= '1';
		inputs_i.jamma_n.p(1).button(4) <= '1';
		inputs_i.jamma_n.p(1).button(5) <= '1';
		
		inputs_i.jamma_n.p(2).up <= not (joystick1(3) or joystick2(3) or kbd_joy0(4));
		inputs_i.jamma_n.p(2).down <= not (joystick1(2) or joystick2(2) or kbd_joy0(5));
		inputs_i.jamma_n.p(2).left <= not (joystick1(1) or joystick2(1) or kbd_joy0(6));
		inputs_i.jamma_n.p(2).right <= not (joystick1(0) or joystick2(0) or kbd_joy0(7));
		
		inputs_i.jamma_n.p(2).button(1) <= not (joystick1(4) or joystick2(4) or kbd_joy0(0)); --SPACE 
		inputs_i.jamma_n.p(2).button(2) <= not (joystick1(5) or joystick2(5) or kbd_joy0(8)); --Left Alt
		inputs_i.jamma_n.p(2).button(3) <= '1';
		inputs_i.jamma_n.p(2).button(4) <= '1';
		inputs_i.jamma_n.p(2).button(5) <= '1';

  
	-- not currently wired to any inputs
	inputs_i.jamma_n.coin_cnt <= (others => '1');
	inputs_i.jamma_n.coin(2) <= '1';
	inputs_i.jamma_n.service <= '1';
	inputs_i.jamma_n.tilt <= '1';
	inputs_i.jamma_n.test <= '1';
		
BLK_VIDEO : block
  begin

    video_i.clk 		<= clkrst_i.clk(1);	-- by convention
    video_i.clk_ena 	<= '1';
    video_i.reset 	<= clkrst_i.rst(1);
	 
    VGA_R	<= video_o.rgb.r(9 downto 2);
    VGA_G	<= video_o.rgb.g(9 downto 2);
    VGA_B	<= video_o.rgb.b(9 downto 2);
    VGA_HS	<= video_o.hsync;
    VGA_VS	<= video_o.vsync;
	 VGA_DE	<= video_o.de;
	 
  end block BLK_VIDEO;



  AUDIO_R <= audio_o.rdata(15 downto 0);
  AUDIO_L <= audio_o.ldata(15 downto 0);
  
 pace_inst : entity work.pace                                            
   port map
   (
     -- clocks and resets
     clkrst_i					=> clkrst_i,

     -- misc inputs and outputs
     buttons_i         => buttons_i,
     switches_i        => switches_i,
     leds_o            => open,
     
     -- controller inputs
     inputs_i          => inputs_i,

     	-- external ROM/RAM
     flash_i           => flash_i,
     flash_o           => flash_o,
     sram_i        		=> sram_i,
     sram_o        		=> sram_o,
     sdram_i           => sdram_i,
     sdram_o           => sdram_o,
  
      -- VGA video
      video_i           => video_i,
      video_o           => video_o,
      
      -- sound
      audio_i           => audio_i,
      audio_o           => audio_o,

      -- SPI (flash)
      spi_i.din         => '0',
      spi_o             => open,
  
      -- serial
      ser_i             => ser_i,
      ser_o             => ser_o,
      
      -- custom i/o
      project_i         => project_i,
      project_o         => project_o,
      platform_i        => platform_i,
      platform_o        => platform_o,
      target_i          => target_i,
      target_o          => target_o
    );
end SYN;
