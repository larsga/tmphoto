<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/template' prefix='template'%>
<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/tolog' prefix='tolog'%>
<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/webed' prefix='webed'%>
<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/framework' prefix='framework'%>
<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/portlets' prefix='portlets'%>
<%@ taglib uri="http://java.sun.com/jstl/core" prefix="c"%>
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
  contentType="text/html; charset=utf-8"%>
<%
  String photo_url = 
    pageContext.getServletContext().getInitParameter("photo-server");
  boolean has_comments =
    pageContext.getServletContext().getInitParameter("score_database") != null &&
    pageContext.getServletContext().getInitParameter("score_database").equals("true");
  String tmrap_url = 
    pageContext.getServletContext().getInitParameter("tmrap-server");
  String gmapkey = 
    pageContext.getServletContext().getInitParameter("google-maps-key");
%>
