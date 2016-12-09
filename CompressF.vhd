library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity CompressF is
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    cLast  : in boolean;
    -- Message block input
    cMsg0  : in unsigned(63 downto 0);
    cMsg1  : in unsigned(63 downto 0);
    cMsg2  : in unsigned(63 downto 0);
    cMsg3  : in unsigned(63 downto 0);
    cMsg4  : in unsigned(63 downto 0);
    cMsg5  : in unsigned(63 downto 0);
    cMsg6  : in unsigned(63 downto 0);
    cMsg7  : in unsigned(63 downto 0);
    cMsg8  : in unsigned(63 downto 0);
    cMsg9  : in unsigned(63 downto 0);
    cMsg10 : in unsigned(63 downto 0);
    cMsg11 : in unsigned(63 downto 0);
    cMsg12 : in unsigned(63 downto 0);
    cMsg13 : in unsigned(63 downto 0);
    cMsg14 : in unsigned(63 downto 0);
    cMsg15 : in unsigned(63 downto 0);
    -- State vector in
    cHin0  : in unsigned(63 downto 0);
    cHin1  : in unsigned(63 downto 0);
    cHin2  : in unsigned(63 downto 0);
    cHin3  : in unsigned(63 downto 0);
    cHin4  : in unsigned(63 downto 0);
    cHin5  : in unsigned(63 downto 0);
    cHin6  : in unsigned(63 downto 0);
    cHin7  : in unsigned(63 downto 0);
    -- State vector out
    cHout0  : out unsigned(63 downto 0);
    cHout1  : out unsigned(63 downto 0);
    cHout2  : out unsigned(63 downto 0);
    cHout3  : out unsigned(63 downto 0);
    cHout4  : out unsigned(63 downto 0);
    cHout5  : out unsigned(63 downto 0);
    cHout6  : out unsigned(63 downto 0);
    cHout7  : out unsigned(63 downto 0);
    -- Parameter 't'. Likely doesn't need to be that wide
    cNumBytes : in unsigned(127 downto 0);
  );
end CompressF;

architecture rtl of CompressF is
  
  
begin

  Compress: process(aReset, Clk)
  begin
    if aReset = '1' then
     
      
    elsif rising_edge(Clk) then
      
      

    end if;
  end process;

end rtl;