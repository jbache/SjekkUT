package no.dnt.sjekkut.ui;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Trip;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.TripList;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class TripListFragment extends Fragment implements Callback<TripList> {

    // TODO: Customize parameter argument names
    private static final String ARG_COLUMN_COUNT = "column-count";
    // TODO: Customize parameters
    private int mColumnCount = 1;
    private TripListListener mListener;

    /**
     * Mandatory empty constructor for the fragment manager to instantiate the
     * fragment (e.g. upon screen orientation changes).
     */
    public TripListFragment() {
    }

    // TODO: Customize parameter initialization
    @SuppressWarnings("unused")
    public static TripListFragment newInstance(int columnCount) {
        TripListFragment fragment = new TripListFragment();
        Bundle args = new Bundle();
        args.putInt(ARG_COLUMN_COUNT, columnCount);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (getArguments() != null) {
            mColumnCount = getArguments().getInt(ARG_COLUMN_COUNT);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_triplist, container, false);

        // Set the adapter
        if (view instanceof RecyclerView) {
            Context context = view.getContext();
            RecyclerView recyclerView = (RecyclerView) view;
            if (mColumnCount <= 1) {
                recyclerView.setLayoutManager(new LinearLayoutManager(context));
            } else {
                recyclerView.setLayoutManager(new GridLayoutManager(context, mColumnCount));
            }
            TripApiSingleton.call().getTripList(getString(R.string.api_key), "steder").enqueue(this);
        }
        return view;
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        if (activity instanceof TripListListener) {
            mListener = (TripListListener) activity;
        } else {
            throw new RuntimeException(activity.toString()
                    + " must implement TripListListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    @Override
    public void onResponse(Call<TripList> call, Response<TripList> response) {
        if (response.isSuccessful()) {
            RecyclerView recyclerView = (RecyclerView) getView().findViewById(R.id.triplist);
            recyclerView.setAdapter(new TripAdapter(response.body().documents, (TripListListener) getActivity()));
        } else {
            Utils.showToast(getActivity(), "Failed to set adapter: " + response.code());
        }
    }

    @Override
    public void onFailure(Call<TripList> call, Throwable t) {
        Utils.showToast(getActivity(), "Failed to set adapter: " + t.getLocalizedMessage());
    }

    public interface TripListListener {
        void onTripClick(Trip item);
    }
}
