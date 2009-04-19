<?xml version="1.0" encoding="iso-8859-1"?>        
<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/tolog' prefix='tolog'%>
<%@ page language="java" import="
  java.util.*,
  java.io.*,
  java.net.MalformedURLException,
  java.sql.SQLException,
  net.ontopia.infoset.core.*,
  net.ontopia.infoset.impl.basic.URILocator,
  net.ontopia.topicmaps.core.*,
  net.ontopia.topicmaps.query.core.*,
  net.ontopia.topicmaps.query.utils.*,
  net.ontopia.topicmaps.nav2.utils.*,
  net.ontopia.topicmaps.utils.*,
  net.ontopia.utils.*,
  net.ontopia.topicmaps.nav2.core.*,
  net.ontopia.topicmaps.nav2.taglibs.logic.*,
  net.ontopia.topicmaps.nav2.taglibs.tolog.*,
  net.ontopia.topicmaps.nav2.portlets.pojos.*,
  javax.servlet.jsp.*,
  no.priv.garshol.topicmaps.tmphoto.*"
 contentType="application/x-tm+xml; charset=utf-8"%>
<tolog:context topicmap="metadata.xtm">
<%@ include file="../../tolog.jsp"%>
<tolog:set var="person" reqparam="identifier"/>

<%!

private static TopicIF selectPhoto(Collection photos, TopicIF person) {
  List best = new ArrayList();
  double topscore = 0;
  Map scores;
  try {
    scores = ScoreManager.getAverageScores(photos);
  } catch (SQLException e) {
    scores = new HashMap();
  }

  Iterator it = photos.iterator();
  while (it.hasNext()) {
    TopicIF photo = (TopicIF) it.next();
    double score = 0;

    // subtract point for other people
    if (containsOtherPeople(photo, person))
      score -= 2;

    // add point for portrait
    if (isPortrait(photo))
      score += 1;

    // add points for average score
    Double av = (Double) scores.get(getId(photo));
    if (av != null)
      score += av.doubleValue();

    if (score == topscore)
      best.add(photo);
    else if (score > topscore) { 
      best.clear();
      best.add(photo);
      topscore = score;
    }
  }

  return (TopicIF) best.get((int) (Math.random() * best.size()));
}

private static boolean containsOtherPeople(TopicIF photo, TopicIF person) {
  TopicMapIF tm = photo.getTopicMap();
  TopicIF depictedin = getTopic(tm, "http://psi.garshol.priv.no/tmphoto/depicted-in");

  Iterator it = photo.getRoles().iterator();
  while (it.hasNext()) {
    AssociationRoleIF role1 = (AssociationRoleIF) it.next();
    AssociationIF assoc = role1.getAssociation();
    if (assoc.getType().equals(depictedin)) {
      AssociationRoleIF role2 = getOtherRole(assoc, role1);
      if (!role2.getPlayer().equals(person))
        return true;
    }
  }
  return false;
}

private static TopicIF getTopic(TopicMapIF tm, String psi) {
  try {
    URILocator loc = new URILocator(psi);
    return tm.getTopicBySubjectIdentifier(loc);
  } catch (MalformedURLException e) {
    return null;
  }
}

private static AssociationRoleIF getOtherRole(AssociationIF assoc, 
                                              AssociationRoleIF nearrole) {
  Iterator it = assoc.getRoles().iterator();
  while (it.hasNext()) {
    AssociationRoleIF role = (AssociationRoleIF) it.next();
    if (role != nearrole)
      return role;
  }
  return null;
}

private static boolean isPortrait(TopicIF photo) {
  TopicMapIF tm = photo.getTopicMap();
  TopicIF categorized = getTopic(tm, "http://psi.garshol.priv.no/tmphoto/in-category");
  TopicIF portrait = getTopic(tm, "http://en.wikipedia.org/wiki/Portrait");

  Iterator it = photo.getRoles().iterator();
  while (it.hasNext()) {
    AssociationRoleIF role1 = (AssociationRoleIF) it.next();
    AssociationIF assoc = role1.getAssociation();
    if (assoc.getType().equals(categorized)) {
      AssociationRoleIF role2 = getOtherRole(assoc, role1);
      if (role2.getPlayer().equals(portrait))
        return true;
    }
  }
  return false;
}

private static String getId(TopicIF photo) {
  Iterator it = photo.getItemIdentifiers().iterator();
  while (it.hasNext()) {
    LocatorIF loc = (LocatorIF) it.next();
    String url = loc.getAddress();
    int pos = url.indexOf('#');
    if (pos != -1)
      return url.substring(pos + 1);
  }
  return null;
}
%>

<topic-pages xmlns="http://psi.ontopia.net/tmrap/"
             xmlns:tmrap="http://psi.ontopia.net/tmrap/" 
             xmlns:tm="http://psi.ontopia.net/xml/tm-xml/" 
             xmlns:iso="http://psi.topicmaps.org/iso13250/model/"
             xmlns:ph="http://psi.garshol.priv.no/tmphoto/"> 
  <server id="tmphoto"> 
    <iso:topic-name> 
      <tm:value>tmphoto</tm:value> 
    </iso:topic-name> 
  </server>

  <topicmap id="tmphototm"> 
    <iso:topic-name> 
      <tm:value>tmphoto</tm:value> 
    </iso:topic-name> 
    <handle datatype="http://www.w3.org/2001/XMLSchema#anyURI" 
     >http://psi.garshol.priv.no/junk/tmphototm</handle> 
    <contained-in role="tmrap:containee" otherrole="tmrap:container" 
                  topicref="tmphoto"/> 
  </topicmap>

<tolog:if var="person">
  <tm:subject id="the-person">
    <tm:identifier><%= request.getParameter("identifier") %></tm:identifier>
    <iso:topic-name> 
      <tm:value><tolog:out var="person"/></tm:value> 
    </iso:topic-name> 
  </tm:subject>

  <view-page id="person-page">
    <tm:locator>http://www.garshol.priv.no/tmphoto/person.jsp?id=<tolog:id var="person"/></tm:locator>
    <iso:topic-name> 
      <tm:value>Photos of <tolog:out var="person"/></tm:value> 
    </iso:topic-name> 
    <contained-in role="tmrap:containee" otherrole="tmrap:container" 
                  topicref="tmphototm"/> 
  </view-page>

<tolog:set var="photos" query="
  ph:depicted-in(%person% : ph:depicted, $PHOTO : ph:depiction)?"/>
<%
  TopicIF person = (TopicIF) ContextUtils.getSingleValue("person", pageContext);
  Collection topics = ContextUtils.getValue("photos", pageContext);
  TopicIF photo = selectPhoto(topics, person);
  ContextUtils.setSingleValue("photo", pageContext, photo);
%>

  <ph:portrait-page id="photo-page">
    <tm:locator>http://www.garshol.priv.no/tmphoto/photo.jsp?id=<tolog:id var="photo"/></tm:locator>
    <iso:topic-name> 
      <tm:value><tolog:out var="photo"/></tm:value> 
    </iso:topic-name> 
    <contained-in role="tmrap:containee" otherrole="tmrap:container" 
                  topicref="tmphototm"/> 
  </ph:portrait-page>

  <ph:thumbnail id="photo-thumbnail">
    <tm:locator>http://larsga.geirove.org/photoserv.fcgi?<tolog:id var="photo"/>;thumb</tm:locator>
    <iso:topic-name> 
      <tm:value><tolog:out var="photo"/> [thumbnail]</tm:value> 
    </iso:topic-name> 
    <contained-in role="tmrap:containee" otherrole="tmrap:container" 
                  topicref="tmphototm"/> 
  </ph:thumbnail>

  <ph:big-photo id="photo-big">
    <tm:locator>http://larsga.geirove.org/photoserv.fcgi?<tolog:id var="photo"/></tm:locator>
    <iso:topic-name> 
      <tm:value><tolog:out var="photo"/> [big]</tm:value> 
    </iso:topic-name> 
    <contained-in role="tmrap:containee" otherrole="tmrap:container" 
                  topicref="tmphototm"/> 
  </ph:big-photo>
</tolog:if>
</topic-pages>
</tolog:context>