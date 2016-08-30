package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;

import com.squareup.picasso.Picasso;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.PlaceCheckin;
import no.dnt.sjekkut.network.UserCheckins;

/**
 * Copyright Den Norske Turistforening 2016
 * <p/>
 * Created by espen on 25.08.2016.
 */
class PlaceAdapter extends RecyclerView.Adapter<PlaceAdapter.PlaceViewHolder> {

    private final List<Place> mPlaces;
    private final Comparator<Place> mPlaceComparator;
    private final int mDisplayWidth;
    private final PlaceListFragment.PlaceListListener mListener;
    private UserCheckins mUserCheckins;
    private Location mLocation;

    PlaceAdapter(Context context, PlaceListFragment.PlaceListListener listener) {
        mDisplayWidth = Utils.getDisplayWidth(context);
        mPlaces = new ArrayList<>();
        mLocation = null;
        mListener = listener;
        mPlaceComparator = new Comparator<Place>() {
            @Override
            public int compare(Place place1, Place place2) {
                int result = Utils.nullSafeCompareTo(place1.getDistanceTo(mLocation), place2.getDistanceTo(mLocation));
                if (result == 0) {
                    result = Utils.nullSafeCompareTo(place1.navn, place2.navn);
                }
                return result;
            }
        };
    }

    public void setLocation(Location location) {
        mLocation = location;
        Collections.sort(mPlaces, mPlaceComparator);
        notifyDataSetChanged();
    }

    void setPlaces(List<Place> list) {
        mPlaces.clear();
        mPlaces.addAll(list);
        Collections.sort(mPlaces, mPlaceComparator);
        notifyDataSetChanged();
    }

    void updatePlace(Place newPlace) {
        boolean changed = false;
        if (newPlace != null) {
            for (int i = 0; i < mPlaces.size(); ++i) {
                Place oldPlace = mPlaces.get(i);
                if (newPlace._id != null && newPlace._id.equals(oldPlace._id)) {
                    mPlaces.set(i, newPlace);
                    changed = true;
                }
            }
        }
        if (changed) {
            notifyDataSetChanged();
        }
    }

    @Override
    public PlaceViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_place, parent, false);
        return new PlaceViewHolder(view);
    }

    @Override
    public int getItemCount() {
        return mPlaces.size();
    }

    @Override
    public void onBindViewHolder(PlaceViewHolder holder, int position) {
        final Place place = mPlaces.get(position);
        Context context = holder.itemView.getContext();
        Picasso.with(context)
                .load(place.getImageUrl((int) (mDisplayWidth * 0.25f)))
                .error(place.getImageFallback())
                .placeholder(place.getImageFallback())
                .fit()
                .centerCrop()
                .into(holder.image);
        holder.name.setText(place.navn);
        holder.county.setText(context.getString(R.string.county, place.fylke));
        // TODO: number of checkins needs to be fetched from somewhere
        String distanceString = context.getString(R.string.not_available);
        if (mLocation != null && place.hasLocation()) {
            distanceString = Utils.formatDistance(context, place.getDistanceTo(mLocation));
        }
        holder.distance.setText(context.getString(R.string.distance_to_you, distanceString));
        int visits = 0;
        PlaceCheckin latestCheckin = null;
        String checkinString = context.getString(R.string.not_visited);
        if (mUserCheckins != null && mUserCheckins.hasVisited(place._id)) {
            visits = mUserCheckins.getNumberOfVisits(place._id);
            latestCheckin = mUserCheckins.getLatestCheckin(place._id);
            checkinString = context.getString(R.string.last_visited, Utils.getTimeSpanFromNow(latestCheckin.timestamp));
        }
        holder.visits.setText(context.getString(R.string.visits, visits));
        holder.checkin.setChecked(latestCheckin != null);
        holder.checkinText.setText(checkinString);
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onPlaceClicked(place._id);
                }
            }
        });
    }

    void setUserCheckins(UserCheckins userCheckins) {
        mUserCheckins = userCheckins;
        notifyDataSetChanged();
    }

    static class PlaceViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.name)
        TextView name;
        @BindView(R.id.county)
        TextView county;
        @BindView(R.id.visits)
        TextView visits;
        @BindView(R.id.distance)
        TextView distance;
        @BindView(R.id.image)
        ImageView image;
        @BindView(R.id.checkin)
        CheckBox checkin;
        @BindView(R.id.checkinText)
        TextView checkinText;

        PlaceViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}
