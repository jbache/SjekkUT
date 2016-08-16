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

    public String getImageUrl() {
        if (img != null && img.size() >= 1) {
            return img.get(0).url;
        } else {
            return null;
        }
    }

    public static class ImageUrl {
        public String url;
        public String width;
        public String height;
    }


}
