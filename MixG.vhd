-- MixG.vhd
-- This is the G mixing algorithm implemented in a modular block.
-- The current implementation doesn't latch the state of A-D inputs
-- or outputs when Start or Valid strobe. Therefore the data inputs
-- must remain valid throughout all the steps and outputs are only
-- valid when cValid is asserted. It is designed this way to save 
-- registers by delegating them to the logic that instantiates 
-- this block.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity MixG is
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    cStart : in boolean;
    cValid : out boolean;
    cA_in  : in unsigned(63 downto 0);
    cB_in  : in unsigned(63 downto 0);
    cC_in  : in unsigned(63 downto 0);
    cD_in  : in unsigned(63 downto 0);
    cX     : in unsigned(63 downto 0);
    cY     : in unsigned(63 downto 0);
    cA_out : out unsigned(63 downto 0);
    cB_out : out unsigned(63 downto 0);
    cC_out : out unsigned(63 downto 0);
    cD_out : out unsigned(63 downto 0)
  );
end MixG;

architecture rtl of MixG is
  signal cA, cB, cC, cD : unsigned(63 downto 0);
  signal cStep : unsigned(2 downto 0) := (others => '0');
begin

  Mix: process(aReset, Clk)
  begin
    if aReset = '1' then
      cStep  <= (others => '0');
      cA     <= (others => '0');
      cB     <= (others => '0');
      cC     <= (others => '0');
      cD     <= (others => '0');
      cValid <= false;
      
    elsif rising_edge(Clk) then
      
      cValid <= false;
      cStep <= cStep + 1;
      
      case(step) is
      
        when x"0" =>
          if  not cStart then
          -- Get stuck in here until start is asserted
            cStep <= cStep;
          else 
            cA <= cA_in + cB_in + cX;
          end if;

        when x"1" =>
          cD <= (cD_in xor cA) ror 32;
        when x"2" =>
          cC <= cC_in + cD;
        when x"3" =>
          cB <= (cB_in xor cC) ror 24;
        when x"4" =>
          cA <= cA + cB + cY;
        when x"5" =>
          cD <= (cD xor cA) ror 16;
        when x"6" =>
          cC <= cC + cD;
        when x"7" =>
          cB <= (cB xor cC) ror 63; -- Rotate left 1
          cValid <= true;
          
      end case;

    end if;
  end process;

  cA_out <= cA;
  cB_out <= cB;
  cC_out <= cC;
  cD_out <= cD;

end rtl;