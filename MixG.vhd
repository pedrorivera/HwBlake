library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity MixG is
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    cA     : in unsigned(63 downto 0);
    cB     : in unsigned(63 downto 0);
    cC     : in unsigned(63 downto 0);
    cD     : in unsigned(63 downto 0);
    cX     : in unsigned(63 downto 0);
    cY     : in unsigned(63 downto 0);
    cAOut  : out unsigned(63 downto 0);
    cBOut  : out unsigned(63 downto 0);
    cCOut  : out unsigned(63 downto 0);
    cDOut  : out unsigned(63 downto 0);
    cValid : out boolean
  );
end MixG;

architecture rtl of MixG is
  signal cStep : unsigned(2 downto 0) := (others => '0');
begin

  Mix: process(aReset, Clk)
  begin
    if aReset = '1' then
      cStep <= (others => '0');
      cAOut <= (others => '0');
      cBOut <= (others => '0');
      cCOut <= (others => '0');
      cDOut <= (others => '0');
      cValid <= false;
      
    elsif rising_edge(Clk) then
      
      cValid <= false;
      
      case(step) is
      
        when x"0" =>
          cA <= cA + cB + cX;
        when x"1" =>
          cD <= (cD xor cA) ror 32;
        when x"2" =>
          cA <= cC + cD;
        when x"3" =>
          cD <= (cB xor cC) ror 24;
        when x"4" =>
          cA <= cA + cB + cY;
        when x"5" =>
          cD <= (cD xor cA) ror 16;
        when x"6" =>
          cA <= cC + cD;
        when x"7" =>
          cD <= (cB xor cC) ror 63; -- Rotate left 1
          cValid <= true;
      end case;

      cStep <= cStep + 1;

    end if;
  end process;

end rtl;