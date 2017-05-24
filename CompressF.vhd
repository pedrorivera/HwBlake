-- CompressF.vhd
-- This is a full implementation of the Blake2b F compression function.
-- For reference look at:
--   https://tools.ietf.org/html/rfc7693#section-3.2
--   https://en.wikipedia.org/wiki/BLAKE_(hash_function)

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgBlake2b.all;

entity CompressF is
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    -- Triggers the start of the compression. All data inputs must be valid.
    Start : in boolean;  
    -- Specifies if it is the last block of the message
    Last  : in boolean;  
    -- Will assert for a signal clock cycle to indicate the result is available in Hout.
    Done  : out boolean; 
    -- Message block input
    Msg   : in U64Array_t(15 downto 0);
    -- State vector in
    Hin   : in U64Array_t(7 downto 0);
    -- State vector out
    Hout  : out U64Array_t(7 downto 0);
    -- Bytes compressed so far (Parameter 't')
    Offset : in unsigned(kMaxMsgLen-1 downto 0)
  );
end CompressF;

architecture rtl of CompressF is
  
  constant kMixerNum  : integer := 4;
  constant kMixRounds : integer := 12;
  
  type State_t is (Idle, WaitMix1, WaitMix2);
  signal State : State_t;

  signal A_in, B_in, C_in, D_in, X, Y : U64Array_t(0 to kMixerNum-1);
  signal A_out, B_out, C_out, D_out     : U64Array_t(0 to kMixerNum-1);
  signal Valid  : unsigned(kMixerNum-1 downto 0);
  signal StartG : boolean;
  signal Round : natural range 0 to kMixRounds-1;

begin

  ---------------------------------------------------------------------
  -- Mixer instatiation. We're using 4 mixers in this implementation
  ---------------------------------------------------------------------
  MixerGen: for i in 0 to kMixerNum-1 generate

    Mixer: entity work.MixG
    port map(
      aReset => aReset,
      Clk   => Clk,
      Start => StartG,
      A_in  => A_in(i),
      B_in  => B_in(i),
      C_in  => C_in(i),
      D_in  => D_in(i),
      X     => X(i),
      Y     => Y(i),
      A_out => A_out(i),
      B_out => B_out(i),
      C_out => C_out(i),
      D_out => D_out(i),
      Valid => Valid(i)
    );

  end generate MixerGen;

  --------------------------------------------------------------------
  -- Control FSM
  --------------------------------------------------------------------
  Compress: process(aReset, Clk)
  begin

    if aReset = '1' then

      State <= Idle;
      Round  <= 0;
      Done   <= false;
      StartG <= false;
      A_in   <= (others => (others => '0'));
      B_in   <= (others => (others => '0'));
      C_in   <= (others => (others => '0'));
      D_in   <= (others => (others => '0'));
      X      <= (others => (others => '0'));
      Y      <= (others => (others => '0'));
      Hout   <= (others => (others => '0'));
      
    elsif rising_edge(Clk) then

      -- Default values of flag signals
      Done   <= false;
      StartG <= false;
      
      case(State) is
        
        -- Do nothing until Start asserted
        when Idle =>
          
          if Start then 

            -- Initialize the mix vector
            A_in(0) <= Hin(0);  -- V0
            A_in(1) <= Hin(1);  -- V1
            A_in(2) <= Hin(2);  -- V2
            A_in(3) <= Hin(3);  -- V3

            B_in(0) <= Hin(4);  -- V4
            B_in(1) <= Hin(5);  -- V5
            B_in(2) <= Hin(6);  -- V6
            B_in(3) <= Hin(7);  -- V7

            C_in(0) <= kIV(0); -- V8
            C_in(1) <= kIV(1); -- V9
            C_in(2) <= kIV(2); -- V10
            C_in(3) <= kIV(3); -- V11

            D_in(0) <= kIV(4) xor x"00000000" & Offset(31 downto 0); --Something is wrong here
            D_in(1) <= kIV(5); -- xor Offset(127 downto 64);
            D_in(2) <= kIV(6); -- V14
            D_in(3) <= kIV(7); -- V15

            -- Mesage feed, round = 0
            X(0) <= Msg(kSigma(0, 0));
            Y(0) <= Msg(kSigma(0, 1));
            X(1) <= Msg(kSigma(0, 2));
            Y(1) <= Msg(kSigma(0, 3));
            X(2) <= Msg(kSigma(0, 4));
            Y(2) <= Msg(kSigma(0, 5));
            X(3) <= Msg(kSigma(0, 6));
            Y(3) <= Msg(kSigma(0, 7));
            
            -- Override V14 to inverted if last block
            if Last then
              D_in(2) <= not kIV(6); 
            end if;

            Round  <= 0;
            StartG <= true;
            State  <= WaitMix1;

          end if;

        when WaitMix1 =>

          -- If all the Mixers have finished. OPT: check just one
          if Valid(0) = '1' then
            -- Feed the result into the next mix
            A_in(0) <= A_out(0); -- V0
            A_in(1) <= A_out(1); -- V1 
            A_in(2) <= A_out(2); -- V2  
            A_in(3) <= A_out(3); -- V3 

            B_in(0) <= B_out(1); -- V5
            B_in(1) <= B_out(2); -- V6
            B_in(2) <= B_out(3); -- V7  
            B_in(3) <= B_out(0); -- V4

            C_in(0) <= C_out(2); -- V10
            C_in(1) <= C_out(3); -- V11
            C_in(2) <= C_out(0); -- V8
            C_in(3) <= C_out(1); -- V9

            D_in(0) <= D_out(3); -- V15
            D_in(1) <= D_out(0); -- V12
            D_in(2) <= D_out(1); -- V13
            D_in(3) <= D_out(2); -- V14

            -- Mesage feed
            X(0) <= Msg(kSigma(Round mod 10, 8));
            Y(0) <= Msg(kSigma(Round mod 10, 9));
            X(1) <= Msg(kSigma(Round mod 10, 10));
            Y(1) <= Msg(kSigma(Round mod 10, 11));
            X(2) <= Msg(kSigma(Round mod 10, 12));
            Y(2) <= Msg(kSigma(Round mod 10, 13));
            X(3) <= Msg(kSigma(Round mod 10, 14));
            Y(3) <= Msg(kSigma(Round mod 10, 15));

            StartG <= true;
            State  <= WaitMix2;

          end if;

        when WaitMix2 =>

          -- If all the Mixers have finished OPT: check just one
          if Valid(0) = '1' then

            if Round < kMixRounds-1 then

              -- Feed the result into the next mix
              -- OPT: A & C vectors do the same operation in both rounds,
              -- these could be combinationally assigned. (MUX vs FFs)
              A_in(0) <= A_out(0); -- V0
              A_in(1) <= A_out(1); -- V1 
              A_in(2) <= A_out(2); -- V2  
              A_in(3) <= A_out(3); -- V3 

              B_in(0) <= B_out(3); -- V4
              B_in(1) <= B_out(0); -- V5
              B_in(2) <= B_out(1); -- V6
              B_in(3) <= B_out(2); -- V7

              C_in(0) <= C_out(2); -- V8
              C_in(1) <= C_out(3); -- V9
              C_in(2) <= C_out(0); -- V10
              C_in(3) <= C_out(1); -- V11

              D_in(0) <= D_out(1); -- V12
              D_in(1) <= D_out(2); -- V13
              D_in(2) <= D_out(3); -- V14
              D_in(3) <= D_out(0); -- V15

              -- Mesage feed
              X(0) <= Msg(kSigma((Round + 1) mod 10, 0));
              Y(0) <= Msg(kSigma((Round + 1) mod 10, 1));
              X(1) <= Msg(kSigma((Round + 1) mod 10, 2));
              Y(1) <= Msg(kSigma((Round + 1) mod 10, 3));
              X(2) <= Msg(kSigma((Round + 1) mod 10, 4));
              Y(2) <= Msg(kSigma((Round + 1) mod 10, 5));
              X(3) <= Msg(kSigma((Round + 1) mod 10, 6));
              Y(3) <= Msg(kSigma((Round + 1) mod 10, 7));

              StartG <= true;
              Round  <= Round + 1;
              State  <= WaitMix1;

            -- If we've done all 12 rounds
            else

              Hout(0) <= Hin(0) xor A_out(0) xor C_out(2); -- H0 xor V0 xor V8
              Hout(1) <= Hin(1) xor A_out(1) xor C_out(3); -- H0 xor V1 xor V9
              Hout(2) <= Hin(2) xor A_out(2) xor C_out(0); -- H0 xor V2 xor V10
              Hout(3) <= Hin(3) xor A_out(3) xor C_out(1); -- H0 xor V3 xor V11
              Hout(4) <= Hin(4) xor B_out(3) xor D_out(1); -- H0 xor V4 xor V12
              Hout(5) <= Hin(5) xor B_out(0) xor D_out(2); -- H0 xor V5 xor V13
              Hout(6) <= Hin(6) xor B_out(1) xor D_out(3); -- H0 xor V6 xor V14
              Hout(7) <= Hin(7) xor B_out(2) xor D_out(0); -- H0 xor V7 xor V15

              Done  <= true;
              State <= Idle;

            end if;

          end if;
          
      end case;

    end if;

  end process;

end rtl;