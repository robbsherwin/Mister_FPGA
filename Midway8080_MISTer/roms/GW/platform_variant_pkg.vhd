library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package platform_variant_pkg is


-- Galaxy Wars
	constant ROM_0_NAME		: string := "roms/galxwars0.hex";
	constant ROM_1_NAME		: string := "roms/galxwars1.hex";
	constant VRAM_NAME		: string := "../sivram.hex";
end;