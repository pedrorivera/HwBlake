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

  type SigmaArray_t is array (9 downto 0, 15 downto 0) of integer range 0 to 15;
  type U64Array_t is array (integer range <>) of unsigned(63 downto 0);
  
  constant kSigma : SigmaArray_t := (
    (00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15),
    (14, 10, 04, 08, 09, 15, 13, 06, 01, 12, 00, 02, 11, 07, 05, 03),
    (11, 08, 12, 00, 05, 02, 15, 13, 10, 14, 03, 06, 07, 01, 09, 04),
    (07, 09, 03, 01, 13, 12, 11, 14, 02, 06, 05, 10, 04, 00, 15, 08),
    (09, 00, 05, 07, 02, 04, 10, 15, 14, 01, 11, 12, 06, 08, 03, 13),
    (02, 12, 06, 10, 00, 11, 08, 03, 04, 13, 07, 05, 15, 14, 01, 09),
    (12, 05, 01, 15, 14, 13, 04, 10, 00, 07, 06, 03, 09, 02, 08, 11),
    (13, 11, 07, 14, 12, 01, 03, 09, 05, 00, 15, 04, 08, 06, 02, 10),
    (06, 15, 14, 09, 11, 03, 00, 08, 12, 02, 13, 07, 01, 04, 10, 05),
    (10, 02, 08, 04, 07, 06, 01, 05, 15, 11, 09, 14, 03, 12, 13, 00)
  );

  signal V1 : U64Array_t(15 downto 0);
  signal V2 : U64Array_t(15 downto 0);

begin

  Compress: process(aReset, Clk)
  begin
    if aReset = '1' then
     
      
    elsif rising_edge(Clk) then
      
      

    end if;
  end process;

  Mixer1: MixG
  port map(
    aReset => aReset,
    Clk    => Clk,
    cA     => cV1(0),
    cB     => cV1(4),
    cC     => cV1(8),
    cD     => cV1(12),
    cX     => cX1,
    cY     => cY1,
    cAOut  => cV2(0),
    cBOut  => cV2(5),
    cCOut  => cV2(10),
    cDOut  => cV2(15),
    cValid => 
    );

  Mixer2: MixG
  port map(
    aReset => aReset,
    Clk    => Clk,
    cA     => cV1(1),
    cB     => cV1(5),
    cC     => cV1(9),
    cD     => cV1(13),
    cX     => cX2,
    cY     => cY2,
    cAOut  => cV2(1),
    cBOut  => cV2(6),
    cCOut  => cV2(11),
    cDOut  => cV2(12),
    cValid => 
    );

  Mixer3: MixG
  port map(
    aReset => aReset,
    Clk    => Clk,
    cA     => cV1(2),
    cB     => cV1(6),
    cC     => cV1(10),
    cD     => cV1(14),
    cX     => cX3,
    cY     => cY3,
    cAOut  => cV2(2),
    cBOut  => cV2(7),
    cCOut  => cV2(8),
    cDOut  => cV2(13),
    cValid => 
    );

  Mixer4: MixG
  port map(
    aReset => aReset,
    Clk    => Clk,
    cA     => cV1(3),
    cB     => cV1(7),
    cC     => cV1(11),
    cD     => cV1(15),
    cX     => cX4,
    cY     => cY4,
    cAOut  => cV2(3),
    cBOut  => cV2(4),
    cCOut  => cV2(9),
    cDOut  => cV2(14),
    cValid => 
    );


end rtl;