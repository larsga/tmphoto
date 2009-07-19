
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;
import java.io.IOException;

/**
 * Interface to the operations performed on images. Used to isolate
 * the rest of the code from the details of which specific image
 * processing library is used.
 */
public interface ImageProcessor {

  /**
   * Scales the image in the source file and stores the scaled image
   * in the destination file. Aspect ratio is preserved, which is why
   * size is only specified as the length of the longest side of the
   * scaled image, using the maxside parameter.
   */
  public void scaleImage(File source, File destination, int maxside)
    throws IOException;

// used by tagger.py, so might be useful to add, for more flexibility
//   public void rotateImage(File image, int direction)
//     throws IOException;
  
}