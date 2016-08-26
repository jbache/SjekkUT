package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;

import com.squareup.picasso.Picasso;

import java.util.Comparator;
import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Checkin;
import no.dnt.sjekkut.network.Place;

/**
 * Copyright Den Norske Turistforening 2016
 * <p/>
 * Created by espen on 25.08.2016.
 */
public class PlaceAdapter extends ArrayAdapter<Place> {

    private final List<Checkin> mCheckins;
    private final int mDisplayWidth;
    private Location mLocation;

    public PlaceAdapter(Context context, List<Checkin> checkins) {
        super(context, android.R.layout.simple_list_item_1);
        mCheckins = checkins;
        mDisplayWidth = Utils.getDisplayWidth(context);
    }

    public void sortByDistance(Location location) {
        mLocation = location;
        if (location != null) {
            sort(new PlaceAdapter.SortByDistance(location));
        }
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        ViewHolder holder;
        if (convertView != null) {
            holder = (ViewHolder) convertView.getTag();
        } else {
            LayoutInflater inflater = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            convertView = inflater.inflate(R.layout.adapter_mountain, parent, false);
            holder = new ViewHolder();
            holder.name = (TextView) convertView.findViewById(R.id.name);
            holder.countyAndHeight = (TextView) convertView.findViewById(R.id.county_and_height);
            holder.summits = (TextView) convertView.findViewById(R.id.summits);
            holder.distance = (TextView) convertView.findViewById(R.id.distance);
            holder.checkin = (CheckBox) convertView.findViewById(R.id.checkin);
            holder.image = (ImageView) convertView.findViewById(R.id.image);
            holder.checkinText = (TextView) convertView.findViewById(R.id.checkinText);
            convertView.setTag(holder);
        }

        Place place = getItem(position);
        Picasso.with(getContext())
                .load(place.getImageUrl((int) (mDisplayWidth * 0.25f)))
                .error(place.getImageFallback())
                .placeholder(place.getImageFallback())
                .fit()
                .centerCrop()
                .into(holder.image);
        holder.name.setText(place.navn);
        // TODO: height of place needs to be fetched from somewhere
        holder.countyAndHeight.setText(getContext().getString(R.string.county_and_height, place.fylke, 0.0f));
        // TODO: number of checkins needs to be fetched from somewhere
        holder.summits.setText(getContext().getString(R.string.summits, 0));
        String distanceString = getContext().getString(R.string.not_available);
        if (mLocation != null && place.hasLocation()) {
            distanceString = Utils.formatDistance(getContext(), place.getDistanceTo(mLocation));
        }
        holder.distance.setText(getContext().getString(R.string.distance_to_you, distanceString));
        Checkin checkin = null; // TODO: implement getting latest checkin for place
        String checkinString = "Ikke besteget";
        if (checkin != null) {
            checkinString = "Besteget " + Utils.getTimeSpanFromNow(checkin.timestamp);
        }
        holder.checkin.setChecked(checkin != null);
        holder.checkinText.setText(checkinString);
        return convertView;
    }

    private static class ViewHolder {
        TextView name;
        TextView countyAndHeight;
        TextView summits;
        TextView distance;
        ImageView image;
        CheckBox checkin;
        TextView checkinText;
    }

    public static class SortByDistance implements Comparator<Place> {

        private final Location mLocation;

        public SortByDistance(Location location) {
            mLocation = location;
        }

        @Override
        public int compare(Place place1, Place place2) {
            return Utils.nullSafeCompareTo(place1.getDistanceTo(mLocation), place2.getDistanceTo(mLocation));
        }

        @Override
        public boolean equals(Object o) {
            return super.equals(o);
        }
    }
}
