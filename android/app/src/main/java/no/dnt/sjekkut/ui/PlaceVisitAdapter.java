package no.dnt.sjekkut.ui;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.UserCheckins;

class PlaceVisitAdapter extends RecyclerView.Adapter<PlaceVisitAdapter.ViewHolder> {

    private final List<PlaceVisit> mPlaceVisits;
    private final ProfileStatsFragment.ProfileStatsListener mListener;
    private final Comparator<? super PlaceVisit> mComparator;

    PlaceVisitAdapter(ProfileStatsFragment.ProfileStatsListener listener) {
        mPlaceVisits = new ArrayList<>();
        mListener = listener;
        mComparator = new Comparator<PlaceVisit>() {
            @Override
            public int compare(PlaceVisit place1, PlaceVisit place2) {
                int result = Utils.nullSafeCompareTo(place2.mVisits, place1.mVisits);
                if (result == 0) {
                    result = Utils.nullSafeCompareTo(place1.getName(), place2.getName());
                }
                return result;
            }
        };
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_placevisit, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final ViewHolder holder, int position) {
        final PlaceVisit item = mPlaceVisits.get(position);
        Context context = holder.itemView.getContext();
        holder.mPlaceName.setText(item.getName());
        holder.mNumberOfVisits.setText(context.getString(R.string.antallbesøk, item.mVisits));
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mListener != null) {
                    mListener.onPlaceClicked(item.mId);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return mPlaceVisits.size();
    }

    void setUserCheckins(UserCheckins userCheckins) {
        mPlaceVisits.clear();
        Set<String> visitedPlaces = userCheckins.getVisitedPlaceIds();
        for (String id : visitedPlaces) {
            mPlaceVisits.add(new PlaceVisit(id, userCheckins.getNumberOfVisits(id)));

        }
        Collections.sort(mPlaceVisits, mComparator);
        notifyDataSetChanged();
    }

    void updatePlace(Place place) {
        for (PlaceVisit placeVisit : mPlaceVisits) {
            if (placeVisit.mId.equals(place._id)) {
                placeVisit.mPlace = place;
            }
        }
        Collections.sort(mPlaceVisits, mComparator);
        notifyDataSetChanged();
    }

    static private class PlaceVisit {
        String mId;
        int mVisits;
        Place mPlace;

        PlaceVisit(String id, int visits) {
            mId = id;
            mVisits = visits;
        }

        String getName() {
            return mPlace != null ? mPlace.navn : "";
        }
    }

    class ViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.placename)
        TextView mPlaceName;
        @BindView(R.id.numberofvisits)
        TextView mNumberOfVisits;

        ViewHolder(View view) {
            super(view);
            ButterKnife.bind(this, view);
        }
    }
}
