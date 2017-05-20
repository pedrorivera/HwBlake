-- MixG.vhd
-- This is the G mixing algorithm implemented in a modular block.
-- The current implementation doesn't latch the state of A-D inputs
-- or outputs when Start or Valid strobe. Therefore the data inputs
-- must remain valid throughout all the steps and outputs are only
-- valid when Valid is asserted. It is designed this way to save 
-- registers by delegating them to the logic that instantiates 
-- this block.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity MixG is
  port(
    aReset: in  std_logic;
    Clk   : in  std_logic;
    Start : in  boolean;
    Valid : out std_logic;
    A_in  : in  unsigned(63 downto 0);
    B_in  : in  unsigned(63 downto 0);
    C_in  : in  unsigned(63 downto 0);
    D_in  : in  unsigned(63 downto 0);
    X     : in  unsigned(63 downto 0);
    Y     : in  unsigned(63 downto 0);
    A_out : out unsigned(63 downto 0);
    B_out : out unsigned(63 downto 0);
    C_out : out unsigned(63 downto 0);
    D_out : out unsigned(63 downto 0)
  );
end MixG;

architecture rtl of MixG is
  signal A, B, C, D : unsigned(63 downto 0);
  signal cStep : natural range 0 to 7 := 0;
begin

  Mix: process(aReset, Clk)
  begin
    if aReset = '1' then
      cStep  <= 0;
      A     <= (others => '0');
      B     <= (others => '0');
      C     <= (others => '0');
      D     <= (others => '0');
      Valid <= '0';
      
    elsif rising_edge(Clk) then
      
      Valid <= '0';
      cStep <= cStep + 1;
      
      case(cStep) is
      
        when 0 =>
          if  not Start then
          -- Get stuck in here until start is asserted
            cStep <= cStep;
          else 
            A <= A_in + B_in + X;
          end if;

        when 1 =>
          D <= (D_in xor A) ror 32;
        when 2 =>
          C <= C_in + D;
        when 3 =>
          B <= (B_in xor C) ror 24;
        when 4 =>
          A <= A + B + Y;
        when 5 =>
          D <= (D xor A) ror 16;
        when 6 =>
          C <= C + D;
        when 7 =>
          B <= (B xor C) ror 63; -- Rotate left 1
          Valid <= '1';
          
      end case;

    end if;
  end process;

  A_out <= A;
  B_out <= B;
  C_out <= C;
  D_out <= D;

end rtl;