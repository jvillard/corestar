// Tests for instantiating logical vaiables.

procedure Test18a:
  { $g_x = _x } ($g_x) { $g_x != _x }
?
  assign { $g_x = _y } ($g_x) { $g_x != _y } ();
end;

