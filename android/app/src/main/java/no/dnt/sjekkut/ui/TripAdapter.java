package no.dnt.sjekkut.ui;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.network.Trip;
import no.dnt.sjekkut.ui.TripListFragment.TripListListener;

class TripAdapter extends RecyclerView.Adapter<TripAdapter.TripHolder> {

    private final List<Trip> mTripList = new ArrayList<>();
    private final TripListListener mListener;

    TripAdapter(TripListFragment.TripListListener listener) {
        mListener = listener;
    }

    void setList(List<Trip> tripList) {
        mTripList.clear();
        mTripList.addAll(tripList);
        notifyDataSetChanged();
    }

    @Override
    public TripHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.tripitem, parent, false);
        return new TripHolder(view);
    }

    @Override
    public void onBindViewHolder(final TripHolder holder, int position) {
        final Trip trip = mTripList.get(position);
        Context context = holder.mTripTitle.getContext();
        holder.mTripTitle.setText(trip.navn);
        holder.mGroupTitle.setText(context.getString(R.string.not_implemented));
        holder.mDistanceToTrip.setText(context.getString(R.string.not_implemented));
        holder.mVisitStatus.setText(context.getString(R.string.tripVisitStatus, 0, trip.placeCount()));
        holder.mView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onTripClick(trip);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return mTripList.size();
    }

    class TripHolder extends RecyclerView.ViewHolder {
        final View mView;
        final TextView mTripTitle;
        final TextView mGroupTitle;
        final TextView mDistanceToTrip;
        final TextView mVisitStatus;

        TripHolder(View view) {
            super(view);
            mView = view;
            mTripTitle = (TextView) view.findViewById(R.id.title);
            mGroupTitle = (TextView) view.findViewById(R.id.group);
            mDistanceToTrip = (TextView) view.findViewById(R.id.distance);
            mVisitStatus = (TextView) view.findViewById(R.id.visits);
        }

        @Override
        public String toString() {
            return super.toString() + " '" + mGroupTitle.getText() + "'";
        }
    }
}
