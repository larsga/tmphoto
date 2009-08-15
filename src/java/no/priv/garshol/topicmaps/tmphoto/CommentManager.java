
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

  public static void deleteComment(int id) throws SQLException {
    JDBCUtils.update("delete from COMMENTS where id = " + id);
  }

  public static List getCommentsOnPhoto(String photoid) throws SQLException {
    return JDBCUtils.queryForList("select * from COMMENTS where photo = " +
                                  JDBCUtils.quote(photoid) +
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

  // ----- Internal

  static class CommentBuilder implements JDBCUtils.RowMapperIF {

    public Object map(ResultSet rs) throws SQLException {
      return new Comment(rs.getInt("id"),
                         rs.getString("photo"),
                         rs.getString("username"),
                         rs.getString("content"),
                         rs.getTimestamp("datetime"));
    }
    
  }

  public static class Comment {
    private int id;
    private String photoid;
    private String username;
    private String content;
    private Timestamp datetime;

    public Comment(int id, String photoid, String username, String content,
                   Timestamp datetime) {
      this.id = id;
      this.photoid = photoid;
      this.username = username;
      this.content = content;
      this.datetime = datetime;
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
  }
}
