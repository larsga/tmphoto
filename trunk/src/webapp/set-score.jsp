<%@ include file="declarations.jsp"%>
<%
  String id = request.getParameter("id");
  if (id == null)
    throw new NullPointerException("Photo ID must be given!");
  String referrer = request.getHeader("Referer");
  if (referrer == null)
    referrer = "photo.jsp?id=" + id;
  int score = Integer.parseInt(request.getParameter("score"));
  if (score < 1 || score > 5)
    throw new RuntimeException("Score must be between 1 and 5!");
  String username = (String) session.getAttribute("username");
  if (username == null)
    username = "nobody";

  // update database
  ScoreManager.setScore(id, username, score);

  // update topic map
  NavigatorApplicationIF navApp = NavigatorUtils.getNavigatorApplication(pageContext);
  TopicMapIF tm = navApp.getTopicMapById("metadata.xtm");
  TopicMapBuilderIF builder = tm.getBuilder();
  LocatorIF base = tm.getStore().getBaseAddress();

  LocatorIF psi = base.resolveAbsolute("http://psi.garshol.priv.no/tmphoto/vote-score");
  TopicIF scoret = tm.getTopicBySubjectIdentifier(psi);

  LocatorIF datatype = PSI.getXSDDecimal();

  // FIXME: move this into ScoreManager and use a constant!
  int votes = ScoreManager.getVoteCount(id);
  double thescore = (ScoreManager.getAverageScore(id)*votes + 2.5) / (votes+1);

  LocatorIF itemid = base.resolveAbsolute('#' + id);
  TopicIF photo = (TopicIF) tm.getObjectByItemIdentifier(itemid);
  OccurrenceIF occ = null;
  Iterator it = photo.getOccurrences().iterator();
  while (it.hasNext() && occ == null) {
    OccurrenceIF cand = (OccurrenceIF) it.next();
    if (cand.getType().equals(scoret))
      occ = cand;
  }
 
  if (occ == null)
    builder.makeOccurrence(photo, scoret, "" + thescore, datatype);
  else
    occ.setValue("" + thescore);

  // finished!
  response.sendRedirect(referrer);
%>
