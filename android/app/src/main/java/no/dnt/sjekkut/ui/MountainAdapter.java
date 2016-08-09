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
import no.dnt.sjekkut.network.Mountain;

/**
 * Copyright Den Norske Turistforening 2015
 * <p/>
 * Created by espen on 06.02.2015.
 */
public class MountainAdapter extends ArrayAdapter<Mountain> {

    private final List<Checkin> mCheckins;
    private Location mLocation;

    public MountainAdapter(Context context, List<Checkin> checkins) {
        super(context, android.R.layout.simple_list_item_1);
        mCheckins = checkins;
    }

    public void sortByDistance(Location location) {
        mLocation = location;
        if (location != null) {
            sort(new MountainAdapter.SortByDistance(location));
        }
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

        Mountain mountain = getItem(position);
        Picasso.with(getContext()).load(mountain.getImageUrl()).fit().centerCrop().into(holder.image);
        holder.name.setText(mountain.name);
        holder.countyAndHeight.setText(getContext().getString(R.string.county_and_height, mountain.county, mountain.height));
        holder.summits.setText(getContext().getString(R.string.summits, mountain.checkinCount));
        String distanceString = getContext().getString(R.string.not_available);
        if (mLocation != null) {
            distanceString = Utils.formatDistance(getContext(), mountain.getLocation().distanceTo(mLocation));
        }
        holder.distance.setText(getContext().getString(R.string.distance_to_you, distanceString));
        Checkin checkin = Utils.getLatestCheckin(mCheckins, mountain);
        String checkinString = "Ikke besteget";
        if (checkin != null) {
            checkinString = "Besteget " + Utils.getTimeSpanFromNow(checkin.timestamp);
        }
        holder.checkin.setChecked(checkin != null);
        holder.checkinText.setText(checkinString);
        return convertView;
    }

    public static class SortByDistance implements Comparator<Mountain> {

        private final Location mLocation;

        public SortByDistance(Location location) {
            mLocation = location;
        }

        @Override
        public int compare(Mountain lhs, Mountain rhs) {
            return Float.compare(
                    mLocation.distanceTo(lhs.getLocation()),
                    mLocation.distanceTo(rhs.getLocation())
            );
        }

        @Override
        public boolean equals(Object o) {
            return super.equals(o);
        }
    }
}
