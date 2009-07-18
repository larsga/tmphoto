
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;
import java.io.IOException;

/**
 * Interface to the operations performed on images. Used to isolate
 * the rest of the code from the details of which specific image
 * processing library is used.
 */
public interface ImageProcessor {

  public void scaleImage(File source, File destination, int maxside)
    throws IOException;

//   public void rotateImage(File image, int direction)
//     throws IOException;
  
}