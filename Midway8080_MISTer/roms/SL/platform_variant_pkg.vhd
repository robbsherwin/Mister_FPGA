library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package platform_variant_pkg is


-- Space Laser
	constant ROM_0_NAME		: string := "roms/laser1.hex";
	constant ROM_1_NAME		: string := "";
	constant VRAM_NAME		: string := "roms/laser2.hex";
end;