package PkgBlake2b is
  
  type U64Array_t is array (integer range <>) of unsigned(63 downto 0);
  type SigmaArray_t is array (0 to 9, 0 to 15) of integer range 0 to 15;

  -- Message schedule for Blake2b
  -- Reference: https://tools.ietf.org/html/rfc7693#section-2.7
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

  constant kIV : U64Array_t(0 to 7) := (
  	x"cbbb9d5dc1059ed8",
  	x"629a292a367cd507",
  	x"9159015a3070dd17",
  	x"152fecd8f70e5939",
  	x"67332667ffc00b31",
  	x"8eb44a8768581511",
  	x"db0c2e0d64f98fa7",
  	x"47b5481dbefa4fa4"
  );

  -- kMaxMsgLen defines the width of the MsgLen port in the Blake2b core.
  -- According to the standard this can be up to 128-bits, which represents
  -- as much as 3.4x10^29 GB. For practicity the default value is set to 32,
  -- enabling up to ~4.3 GB.
  constant kMaxMsgLen : integer := 32;
  
  -- Length in bytes of the hashed result
  constant kHashLen : integer := 512;
  
  -- Length in bytes of the optional key
  constant kKeyLen  : integer := 64;
  
end PkgBlake2b;
