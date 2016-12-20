-- Blake2b.vhd
-- This is the top-level of a full implementation of the Blake2b algorithm.
-- A state machine controls the rounds of compression to be executed depending
-- on the size of the message. The message is fed to this entity in an array of
-- 16 words (64 bits each)
-- For reference look at:
--   https://tools.ietf.org/html/rfc7693#section-3.2
--   https://en.wikipedia.org/wiki/BLAKE_(hash_function)

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgBlake2b.vhd

entity Blake2b is
  generic(
    kHashSize : integer := 512; -- Defines the length of the hashed result
    kKeySize  : integer := 64   -- Defines the length of the optional key
  );
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    cPush  : in boolean;  
    cReady : out boolean;  
    -- Will assert for a single clock cycle to indicate the result is available.
    cDone  : out boolean; 
    -- Partial message input
    cMsg   : in U64Array_t(15 downto 0);
    -- Message length in bytes.
    cMsgLen : in unsigned(kMaxMsgLen-1 downto 0) ;
    -- Optional key parameter
    cKey   : in std_logic_vector(63 downto 0);
    -- Result
    cHashOut  : out U64Array_t(7 downto 0)
  );
end Blake2b;

architecture rtl of Blake2b is
  
  type State_t is (Idle, WaitMix1, WaitMix2, Done);
  signal cState : State_t;

  signal H : U64Array_t(7 downto 0);

begin

  ---------------------------------------------------------------------
  -- Compressor Instantiation
  ---------------------------------------------------------------------

  Compressor: CompressF
  port map(
    aReset => aReset,
    Clk    => Clk,
    cStart => 
    cLast  =>
    cDone  =>
    cMsg   =>
    cHin   =>
    cHout  =>
    cNumBytes =>
  );


  --------------------------------------------------------------------
  -- Control FSM
  --------------------------------------------------------------------
  Compress: process(aReset, Clk)
  begin

    if aReset = '1' then

      cState  <= Idle;
      
      
    elsif rising_edge(Clk) then

      -- Default values of flag signals
      cDone   <= false;
      cStartG <= false;
      
      case(cState) is
        
        -- Do nothing until cStart asserted
        when Idle =>
          
          if cStart then 

           

          end if;

        when WaitMix1 =>

         

        when WaitMix2 =>

          

          
      end case;

    end if;

  end process;

end rtl;