-- Testbench for Blake2b.vhd

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgBlake2b.all;

entity Blake2b_tb is end Blake2b_tb;

architecture test of Blake2b_tb is

  signal aReset: std_logic;
  signal Busy: boolean;
  signal Clk: std_logic;
  signal Done: boolean;
  signal HashOut: U64Array_t(7 downto 0);
  signal Key: std_logic_vector(63 downto 0);
  signal Msg: U64Array_t(15 downto 0);
  signal MsgLen: unsigned(kMaxMsgLen-1 downto 0);
  signal Push: boolean;

  constant kTestMsg : U64Array_t(15 downto 0) := (
    x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000",
    x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", 
    x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", 
    x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000636261"
  );

  constant kExpectedH : U64Array_t(7 downto 0) := (
    x"0D4D1C983FA580BA", x"E9F6129FB697276A", x"B7C45A68142F214C", x"D1A2FFDB6FBB124B", 
    x"2D79AB2A39C5877D", x"95CC3345DED552C2", x"5A92F1DBA88AD318", x"239900D4ED8623B9"
  );

  --shared variable Rand : Random_t;

  procedure WaitClk(N : positive := 1) is
  begin
   for i in 1 to N loop
      wait until rising_edge(Clk);
    end loop;
  end procedure WaitClk;

begin

  aReset <= '1', '0' after 10 ns;
  Clk <= not Clk after 10 ns when aReset = '0' else '0';

  DUT: entity work.Blake2b
    port map (
      aReset  => aReset,  
      Clk     => Clk,     
      Push    => Push,    
      Busy    => Busy,    
      Done    => Done,    
      Msg     => Msg,     
      MsgLen  => MsgLen,   
      Key     => Key,      
      HashOut => HashOut); 

  Main: process
  begin
    wait until aReset = '0';
    
    -- Check initial state of flags
    assert not Done report "Done should be initially false" severity error;
    assert not Busy report "Busy should be initially false" severity error;

    -- Push a single block test message to the core
    Msg    <= kTestMsg;
    MsgLen <= to_unsigned(128, MsgLen'length);
    Push   <= true;

    wait until Done;
    assert HashOut = kExpectedH report "Result does not match kExpectedH" severity error;

    wait;
  end process;

end test;
