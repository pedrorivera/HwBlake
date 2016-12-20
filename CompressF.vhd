-- CompressF.vhd
-- This is a full implementation of the Blake2b F compression function.
-- For reference look at:
--   https://tools.ietf.org/html/rfc7693#section-3.2
--   https://en.wikipedia.org/wiki/BLAKE_(hash_function)

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgBlake2b.vhd

entity CompressF is
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    -- Triggers the start of the compression. All data inputs must be valid.
    cStart : in boolean;  
    -- Specifies if it is the last block of the message
    cLast  : in boolean;  
    -- Will assert for a signal clock cycle to indicate the result is available in cHout.
    cDone  : out boolean; 
    -- Message block input
    cMsg   : in U64Array_t(15 downto 0);
    -- State vector in
    cHin   : in U64Array_t(7 downto 0);
    -- State vector out
    cHout  : out U64Array_t(7 downto 0);
    -- Full message length (Parameter 't')
    cNumBytes : in unsigned(kMaxMsgLen-1 downto 0)
  );
end CompressF;

architecture rtl of CompressF is
  
  constant kMixerNum  : integer := 4;
  constant kMixRounds : integer := 12;
  
  type State_t is (Idle, WaitMix1, WaitMix2, Done);
  signal cState : State_t;

  signal cA_in, cB_in, cC_in, cD_in, cX, cY : U64Array_t(0 to kMixerNum-1);
  signal cA_out, cB_out, cC_out, cD_out     : U64Array_t(0 to kMixerNum-1);
  signal cValid  : std_logic_vector(kMixerNum-1 downto 0);
  signal cStartG : std_logic_vector(kMixerNum-1 downto 0);
  signal cRound : integer range 0 to kMixRounds-1;

begin

  ---------------------------------------------------------------------
  -- Mixer instatiation. We're using 4 mixers in this implementation
  ---------------------------------------------------------------------
  MixerGen: for i in 0 to kMixerNum-1 generate

    Mixer: MixG
    port map(
      aReset => aReset,
      Clk    => Clk,
      cA_in  => cA_in(i),
      cB_in  => cB_in(i),
      cC_in  => cC_in(i),
      cD_in  => cD_in(i),
      cX     => cX(i),
      cY     => cY(i),
      cA_out => cA_out(i),
      cB_out => cB_out(i),
      cC_out => cC_out(i),
      cD_out => cD_out(i),
      cValid => cValid(i)
    );

  end generate MixerGen;

  --------------------------------------------------------------------
  -- Control FSM
  --------------------------------------------------------------------
  Compress: process(aReset, Clk)
  begin

    if aReset = '1' then

      cState  <= Idle;
      cRound  <= 0;
      cDone   <= false;
      cStartG <= false;
      cA_in   <= (others => (others => '0'));
      cB_in   <= (others => (others => '0'));
      cC_in   <= (others => (others => '0'));
      cD_in   <= (others => (others => '0'));
      cX      <= (others => (others => '0'));
      cY      <= (others => (others => '0'));
      
    elsif rising_edge(Clk) then

      -- Default values of flag signals
      cDone   <= false;
      cStartG <= false;
      
      case(cState) is
        
        -- Do nothing until cStart asserted
        when Idle =>
          
          if cStart then 

            -- Initialize the mix vector
            cA_in(0) <= cHin(0);  -- V0
            cA_in(1) <= cHin(1);  -- V1
            cA_in(2) <= cHin(2);  -- V2
            cA_in(3) <= cHin(3);  -- V3

            cB_in(0) <= cHin(4);  -- V4
            cB_in(1) <= cHin(5);  -- V5
            cB_in(2) <= cHin(6);  -- V6
            cB_in(3) <= cHin(7);  -- V7

            cC_in(0) <= kIV(0); -- V8
            cC_in(1) <= kIV(1); -- V9
            cC_in(2) <= kIV(2); -- V10
            cC_in(3) <= kIV(3); -- V11

            cD_in(0) <= kIV(4) xor cNumBytes(31 downto 0);
            cD_in(1) <= kIV(5) -- xor cNumBytes(63 downto 32);
            cD_in(2) <= kIV(6); -- V14
            cD_in(3) <= kIV(7); -- V15

            -- Mesage feed, round = 0
            cX(0) <= cMsg(kSigma(0, 0));
            cY(0) <= cMsg(kSigma(0, 1));
            cX(1) <= cMsg(kSigma(0, 2));
            cY(1) <= cMsg(kSigma(0, 3));
            cX(2) <= cMsg(kSigma(0, 4));
            cY(2) <= cMsg(kSigma(0, 5));
            cX(3) <= cMsg(kSigma(0, 6));
            cY(3) <= cMsg(kSigma(0, 7));
            
            -- Override V14 to inverted if last block
            if cLast then
              cD_in(2) <= not kIV(6); 
            end if;

            cRound  <= 0;
            cStartG <= true;
            cState  <= WaitMix1;

          end if;

        when WaitMix1 =>

          -- If all the Mixers have finished. OPT: check just one
          if cValid = cValid'high then
            -- Feed the result into the next mix
            cA_in(0) <= cA_out(0); -- V0
            cA_in(1) <= cA_out(1); -- V1 
            cA_in(2) <= cA_out(2); -- V2  
            cA_in(3) <= cA_out(3); -- V3 

            cB_in(0) <= cB_out(1); -- V5
            cB_in(1) <= cB_out(2); -- V6
            cB_in(2) <= cB_out(3); -- V7  
            cB_in(3) <= cB_out(0); -- V4

            cC_in(0) <= cC_out(2); -- V10
            cC_in(1) <= cC_out(3); -- V11
            cC_in(2) <= cC_out(0); -- V8
            cC_in(3) <= cC_out(1); -- V9

            cD_in(0) <= cD_out(3); -- V15
            cD_in(1) <= cD_out(0); -- V12
            cD_in(2) <= cD_out(1); -- V13
            cD_in(3) <= cD_out(2); -- V14

            -- Mesage feed
            cX(0) <= cMsg(kSigma(cRound mod 10, 8));
            cY(0) <= cMsg(kSigma(cRound mod 10, 9));
            cX(1) <= cMsg(kSigma(cRound mod 10, 10));
            cY(1) <= cMsg(kSigma(cRound mod 10, 11));
            cX(2) <= cMsg(kSigma(cRound mod 10, 12));
            cY(2) <= cMsg(kSigma(cRound mod 10, 13));
            cX(3) <= cMsg(kSigma(cRound mod 10, 14));
            cY(3) <= cMsg(kSigma(cRound mod 10, 15));

            cStartG <= true;
            cState  <= WaitMix1;

          end if;

        when WaitMix2 =>

          -- If all the Mixers have finished OPT: check just one
          if cValid = cValid'high then

            if cRound < kMixRounds then

              cRound <= cRound + 1;

              -- Feed the result into the next mix
              -- OPT: A & C vectors do the same operation,
              -- these could be combinationally assigned. (MUX vs FFs)
              cA_in(0) <= cA_out(0); -- V0
              cA_in(1) <= cA_out(1); -- V1 
              cA_in(2) <= cA_out(2); -- V2  
              cA_in(3) <= cA_out(3); -- V3 

              cB_in(0) <= cB_out(3); -- V4
              cB_in(1) <= cB_out(0); -- V5
              cB_in(2) <= cB_out(1); -- V6
              cB_in(3) <= cB_out(2); -- V7

              cC_in(0) <= cC_out(2); -- V8
              cC_in(1) <= cC_out(3); -- V9
              cC_in(2) <= cC_out(0); -- V10
              cC_in(3) <= cC_out(1); -- V11

              cD_in(0) <= cD_out(1); -- V12
              cD_in(1) <= cD_out(2); -- V13
              cD_in(2) <= cD_out(3); -- V14
              cD_in(3) <= cD_out(0); -- V15

              -- Mesage feed
              cX(0) <= cMsg(kSigma(cRound mod 10, 0));
              cY(0) <= cMsg(kSigma(cRound mod 10, 1));
              cX(1) <= cMsg(kSigma(cRound mod 10, 2));
              cY(1) <= cMsg(kSigma(cRound mod 10, 3));
              cX(2) <= cMsg(kSigma(cRound mod 10, 4));
              cY(2) <= cMsg(kSigma(cRound mod 10, 5));
              cX(3) <= cMsg(kSigma(cRound mod 10, 6));
              cY(3) <= cMsg(kSigma(cRound mod 10, 7));

              cStartG <= true;
              cState  <= WaitMix1;

            -- If we've done all 12 rounds
            else

              cHout(0) <= cHin(0) xor cA_out(0) xor cC_out(2); -- H0 xor V0 xor V8
              cHout(1) <= cHin(1) xor cA_out(1) xor cC_out(3); -- H0 xor V1 xor V9
              cHout(2) <= cHin(2) xor cA_out(2) xor cC_out(0); -- H0 xor V2 xor V10
              cHout(3) <= cHin(3) xor cA_out(3) xor cC_out(1); -- H0 xor V3 xor V11
              cHout(4) <= cHin(4) xor cB_out(3) xor cD_out(1); -- H0 xor V4 xor V12
              cHout(5) <= cHin(5) xor cB_out(0) xor cD_out(2); -- H0 xor V5 xor V13
              cHout(6) <= cHin(6) xor cB_out(1) xor cD_out(3); -- H0 xor V6 xor V14
              cHout(7) <= cHin(7) xor cB_out(2) xor cD_out(0); -- H0 xor V7 xor V15

              cDone  <= true;
              cState <= Idle;

            end if;

          end if;
          
      end case;

    end if;

  end process;

end rtl;