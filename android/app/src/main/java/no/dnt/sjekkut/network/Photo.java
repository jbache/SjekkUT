package no.dnt.sjekkut.network;

import java.util.List;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public class Photo {
    public String _id;
    public String beskrivelse;
    public String navn;
    public List<ImageUrl> img;

    public Photo(String _id) {
        this._id = _id;
    }

    public String getImageUrl(int preferredWidth) {
        if (img != null && img.size() > 0) {
            int minimumDelta = Integer.MAX_VALUE;
            ImageUrl preferredImage = img.get(0);
            for (int i = 0; i < img.size(); ++i) {
                ImageUrl currentImage = img.get(i);
                int currentDelta = currentImage.getWidthDelta(preferredWidth);
                if (currentDelta < minimumDelta) {
                    minimumDelta = currentDelta;
                    preferredImage = currentImage;
                }
            }
            return preferredImage.url;
        } else {
            return null;
        }
    }

    public static class ImageUrl {
        public String url;
        public String width;
        public String height;

        int getWidthDelta(int preferredWidth) {
            if (width != null && !width.isEmpty()) {
                try {
                    return Math.abs(Integer.parseInt(width) - preferredWidth);
                } catch (NumberFormatException ignored) {
                }
            }
            return Integer.MAX_VALUE;
        }
    }
}
