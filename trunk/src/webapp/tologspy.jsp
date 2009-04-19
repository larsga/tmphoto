<%@ page language="java" 
           import="net.ontopia.topicmaps.query.impl.basic.QueryProcessor" %>
<style>th, .event { vertical-align: top; text-align: left } td { vertical-align: top; text-align: right }</style>
<%
QueryProcessor.generateReport(out);
%>
