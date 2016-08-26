package no.dnt.sjekkut.ui;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.dummy.DummyContent.DummyItem;

class PlaceVisitAdapter extends RecyclerView.Adapter<PlaceVisitAdapter.ViewHolder> {

    private final List<DummyItem> mValues;
    private final ProfileStatsFragment.ProfileStatsListener mListener;

    PlaceVisitAdapter(List<DummyItem> items, ProfileStatsFragment.ProfileStatsListener listener) {
        mValues = items;
        mListener = listener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_placevisit, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(final ViewHolder holder, int position) {
        final DummyItem item = mValues.get(position);
        Context context = holder.itemView.getContext();
        holder.mPlaceName.setText(item.name);
        holder.mNumberOfVisits.setText(context.getString(R.string.antallbesøk, item.visits));
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onListFragmentInteraction(item);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return mValues.size();
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
