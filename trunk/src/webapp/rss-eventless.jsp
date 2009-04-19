<%@ page 
  contentType="application/rss+xml; charset=utf-8"
%><%@ taglib uri='http://psi.ontopia.net/jsp/taglib/tolog' prefix='tolog'
%><?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN" 
                     "http://my.netscape.com/publish/formats/rss-0.91.dtd">
<rss version="0.91">
  <channel>
    <title>Lars Marius Garshol's random photos</title>
    <link>http://www.garshol.priv.no/tmphoto/</link>
    <description>Photos without events from the photo collection of
    Lars Marius Garshol.</description>
    <managingEditor>larsga@garshol.priv.no</managingEditor>
    <webMaster>larsga@garshol.priv.no</webMaster>

<tolog:context topicmap="metadata.xtm"
><%@ include file="tolog.jsp"
%><tolog:foreach query="select $PHOTO, $DATE, $DESC from
  instance-of($PHOTO, op:Image),
  ph:time-taken($PHOTO, $DATE),
  { dc:description($PHOTO, $DESC) },
  not(ph:taken-during($EVENT : op:Event, $PHOTO : op:Image))
order by $DATE desc limit 50?
">
    <item>
       <title><tolog:out var="PHOTO"/></title>
       <link>http://www.garshol.priv.no/tmphoto/photo.jsp?id=<tolog:id var="PHOTO"/></link>
       <tolog:if var="DESC"
         ><description><tolog:out var="DESC"/></description></tolog:if>
       <author>Lars Marius Garshol</author>
       <pubDate><tolog:out var="DATE"/></pubDate>
     </item>
</tolog:foreach></tolog:context>
   </channel>
</rss>
