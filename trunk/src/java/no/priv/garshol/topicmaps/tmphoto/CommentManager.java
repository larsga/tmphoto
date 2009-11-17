
package no.priv.garshol.topicmaps.tmphoto;

import java.util.List;
import java.sql.Timestamp;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;

import com.petebevin.markdown.MarkdownProcessor;

public class CommentManager {
  private static SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  
  public static void addComment(String photoid, String username, String content)
    throws SQLException {
    // check parameters
    verifyString(photoid, "Photo ID");
    verifyString(username, "Username");
    verifyString(content, "Comment content");    

    // add it
    JDBCUtils.update("insert into COMMENTS values " +
                     "(default, " + JDBCUtils.quote(photoid) + ", 1, now(), " +
                     JDBCUtils.quote(username) + ", " +
                     JDBCUtils.quote(content) + ", null, null, null)");
  }

  public static void addComment(String photoid, String name, String email,
                                String url, String content) throws SQLException {
    // check parameters
    verifyString(photoid, "Photo ID");
    verifyString(name, "Name");
    verifyString(content, "Comment content");
    email = toNull(email);
    url = toNull(url);

    // add it
    JDBCUtils.update("insert into COMMENTS values " +
                     "(default, " + JDBCUtils.quote(photoid) + ", 0, now(), " +
                     "'nobody', " + JDBCUtils.quote(content) + ", " +
                     JDBCUtils.quote(email) + ", " +
                     JDBCUtils.quote(name) + ", " +
                     JDBCUtils.quote(url) + ")");
  }

  public static void deleteComment(int id) throws SQLException {
    JDBCUtils.update("delete from COMMENTS where id = " + id);
  }

  public static List getCommentsOnPhoto(String photoid) throws SQLException {
    return JDBCUtils.queryForList("select * from COMMENTS where photo = " +
                                  JDBCUtils.quote(photoid) +
                                  " and verified=1 " +
                                  " order by datetime", new CommentBuilder());
  }

  public static List getCommentsFromUser(String user) throws SQLException {
    return JDBCUtils.queryForList("select * from COMMENTS where username = " +
                                  JDBCUtils.quote(user) +
                                  " order by datetime desc", new CommentBuilder());
  }

  public static List getRecentComments() throws SQLException {
    return JDBCUtils.queryForList(
      "select * " +
      "from COMMENTS " +
      "order by datetime desc limit 50", new CommentBuilder());
  }

  public static List getAllComments() throws SQLException {
    return JDBCUtils.queryForList("select * from COMMENTS",
                                  new CommentBuilder());
  }
  
  private static void verifyString(String value, String fieldname) {
    if (value == null)
      throw new NullPointerException(fieldname + " cannot be null!");
    if (value.trim().equals(""))
      throw new IllegalArgumentException(fieldname + " cannot be empty!");
  }

  private static String toNull(String value) {
    if (value == null || value.trim().equals(""))
      return null;
    return value;
  }

  // ----- Internal

  static class CommentBuilder implements JDBCUtils.RowMapperIF {

    public Object map(ResultSet rs) throws SQLException {
      return new Comment(rs.getInt("id"),
                         rs.getString("photo"),
                         rs.getString("username"),
                         rs.getString("content"),
                         rs.getTimestamp("datetime"),
                         rs.getString("name"),
                         rs.getString("email"),
                         rs.getString("url"),
                         rs.getInt("verified"));
    }
    
  }

  public static class Comment {
    private int id;
    private String photoid;
    private String username;
    private String content;
    private Timestamp datetime;
    private String name;
    private String email;
    private String url;
    private boolean verified;

    public Comment(int id, String photoid, String username, String content,
                   Timestamp datetime, String name, String email, String url,
                   int verified) {
      this.id = id;
      this.photoid = photoid;
      this.username = username;
      this.content = content;
      this.datetime = datetime;
      this.name = name;
      this.email = email;
      this.url = url;
      this.verified = (verified != 0);
    }

    public int getId() {
      return id;
    }

    public String getPhotoId() {
      return photoid;
    }

    public String getUser() {
      return username;
    }

    public boolean getIsVerified() {
      return verified;
    }

    public boolean getIsAuthenticated() {
      return !username.equals("nobody");
    }

    public String getContent() {
      return content;
    }

    public String getFormattedContent() {
      MarkdownProcessor proc = new MarkdownProcessor();
      return proc.markdown(content);
    }

    public String getFormattedDatetime() {
      return format.format(datetime);
    }

    public String getName() {
      return name;
    }

    public String getEmail() {
      return email;
    }

    public String getUrl() {
      return url;
    }
  }  
}
