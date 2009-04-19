<tolog:declare>
  using ph      for i"http://psi.garshol.priv.no/tmphoto/"
  using tech    for i"http://www.techquila.com/psi/thesaurus/#"
  using dc      for i"http://purl.org/dc/elements/1.1/"
  using dcc     for i"http://psi.ontopia.net/metadata/#"
  using op      for i"http://psi.ontopedia.net/"
  using userman for i"http://psi.ontopia.net/userman/"
  import "http://psi.ontopia.net/tolog/string/" as str

  year($DATE, $YEAR) :-
    str:substring($YEAR, $DATE, 0, 4).

  located-in($PAR, $CH) :- {
    op:located_in($PAR : op:Container, $CH : op:Containee) |
    op:located_in($PAR : op:Container, $MID : op:Containee),
    located-in($MID, $CH)
  }.

  broader-than($BROAD, $NARROW) :- {
    tech:broader-narrower($BROAD : tech:broader, $NARROW : tech:narrower) |
    tech:broader-narrower($BROAD : tech:broader, $MID : tech:narrower),
    broader-than($MID, $NARROW)
  }.
</tolog:declare>
