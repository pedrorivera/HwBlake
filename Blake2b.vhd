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
  use work.PkgBlake2b.all;

entity Blake2b is
  port(
    aReset : in std_logic;
    Clk    : in std_logic;
    -- Loads data in Msg and starts the hashing process.
    Push  : in boolean;  
    -- Indicates the interface is not ready to receive data.
    Busy : out boolean;  
    -- Will assert for a single clock cycle to indicate the final hash is available.
    Done  : out boolean; 
    -- Partial message input
    Msg   : in U64Array_t(15 downto 0);
    -- Full message length in bytes. Only needs to be valid if Done is true.
    MsgLen : in unsigned(kMaxMsgLen-1 downto 0) ;
    -- Optional key parameter (currently not implemented)
    Key   : in std_logic_vector(63 downto 0);
    -- Result, only valid when Done is true.
    HashOut  : out U64Array_t(7 downto 0)
  );
end Blake2b;

architecture rtl of Blake2b is
  
  type State_t is (HashDone, LoadMsg, Compress);
  signal State : State_t;
  signal StartF : boolean;
  signal DoneF  : boolean;
  signal Last   : boolean;

  signal MsgPart   : U64Array_t(15 downto 0);
  signal Hin, Hout : U64Array_t(7 downto 0);
  signal MaxOffset, Offset : unsigned(kMaxMsgLen-1 downto 0); -- TODO: revise MaxOffset

begin
  ---------------------------------------------------------------------
  -- Compressor Instantiation
  ---------------------------------------------------------------------

  Compressor: entity work.CompressF
  port map(
    aReset   => aReset,
    Clk      => Clk,
    Start    => StartF,
    Last     => Last,
    Done     => DoneF,
    Msg      => MsgPart,
    Hin      => Hin,
    Hout     => Hout,
    Offset   => Offset
  );

  --------------------------------------------------------------------
  -- Control FSM
  --------------------------------------------------------------------
  Main: process(aReset, Clk)
  begin

    if aReset = '1' then
      
      Busy   <= false;
      Last   <= false;
      StartF <= false;
      Done   <= false;
      Hin    <= kIV;
      State  <= HashDone;
      Offset    <= (others => '0');
      MaxOffset <= (others => '0');
      MsgPart   <= (others => (others => '0'));
      HashOut   <= (others => (others => '0'));

    elsif rising_edge(Clk) then
      
      case(State) is
        
        -- Idle state
        when HashDone =>
          if Push then
            -- Load first partial message
            Hin(7 downto 1) <= kIV(7 downto 1);
            Hin(0)    <= kIV(0) xor (x"000000000101" & kKeyLen & kHashLen);
            MsgPart   <= Msg;
            Offset    <= Offset + 3; -- !!! TODO: Fix to adjust according to msg len
            MaxOffset <= MsgLen;
            Last      <= MsgLen <= 128;
            Busy      <= true;
            StartF    <= true;
            State     <= Compress;
          end if;

        -- Waits for compression to be done
        when Compress =>
          StartF <= false;
          if DoneF then
            Busy  <= false;
            -- If there are blocks remaining
            if Offset < MaxOffset then
              Offset <= Offset + 128;
              State <= LoadMsg;
            -- Finished!
            else
              HashOut <= Hout; -- First kHashLen bytes of H in little endian
              Done    <= true;
              State   <= HashDone;
            end if;

          end if;

        -- Wait for push and load partial 128-bit messag into the compressor
        when LoadMsg =>

          if Push then
            MsgPart <= Msg;
            Hin     <= Hout;
            Last    <= Offset = MaxOffset;
            StartF  <= true;
            Busy    <= true;
            State   <= Compress;
          end if;
          
      end case;

    end if;

  end process;

end rtl;