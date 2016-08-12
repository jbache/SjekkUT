package no.dnt.sjekkut.ui;

import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.network.Trip;
import no.dnt.sjekkut.ui.TripListFragment.TripListListener;

public class TripAdapter extends RecyclerView.Adapter<TripAdapter.ViewHolder> {

    private final List<Trip> mValues;
    private final TripListListener mListener;

    public TripAdapter(List<Trip> items, TripListFragment.TripListListener listener) {
        mValues = items;
        mListener = listener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.tripitem, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final ViewHolder holder, int position) {
        holder.mItem = mValues.get(position);
        holder.mIdView.setText(mValues.get(position).navn);
        int tripCount = mValues.get(position).steder != null ? mValues.get(position).steder.size() : 0;
        holder.mContentView.setText(tripCount + " steder");

        holder.mView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onTripClick(holder.mItem);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return mValues.size();
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        public final View mView;
        public final TextView mIdView;
        public final TextView mContentView;
        public no.dnt.sjekkut.network.Trip mItem;

        public ViewHolder(View view) {
            super(view);
            mView = view;
            mIdView = (TextView) view.findViewById(R.id.id);
            mContentView = (TextView) view.findViewById(R.id.content);
        }

        @Override
        public String toString() {
            return super.toString() + " '" + mContentView.getText() + "'";
        }
    }
}
