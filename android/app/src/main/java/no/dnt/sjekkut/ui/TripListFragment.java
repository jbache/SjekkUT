package no.dnt.sjekkut.ui;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Trip;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.TripList;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class TripListFragment extends Fragment implements Callback<TripList> {

    private TripListListener mListener;

    public TripListFragment() {
    }

    public static TripListFragment newInstance(int columnCount) {
        TripListFragment fragment = new TripListFragment();
        Bundle args = new Bundle();
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_triplist, container, false);

        // Set the adapter
        if (view instanceof RecyclerView) {
            Context context = view.getContext();
            RecyclerView recyclerView = (RecyclerView) view;
            recyclerView.setLayoutManager(new LinearLayoutManager(context));
            recyclerView.setAdapter(new TripAdapter((TripListListener) getActivity()));
            TripApiSingleton.call().getTripList(getString(R.string.api_key), "steder,bilder,geojson,grupper").enqueue(this);
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
            List<Trip> tripList = response.body().documents;
            setList(tripList);
////            for (Trip trip : tripList) {
////                TripApiSingleton.call().getTrip(
////                        trip._id,
////                        getString(R.string.api_key),
////                        "steder,geojson,bilder,img,kommune,beskrivelse",
////                        "steder,bilder"
////                ).enqueue(this);
//            }
        } else {
            Utils.showToast(getActivity(), "Failed to set adapter: " + response.code());
        }
    }

    private void setList(List<Trip> tripList) {
        if (getView() != null) {
            RecyclerView recyclerView = (RecyclerView) getView().findViewById(R.id.triplist);
            if (recyclerView != null) {
                if (recyclerView.getAdapter() instanceof TripAdapter) {
                    ((TripAdapter) recyclerView.getAdapter()).setList(tripList);
                }
            }
        }
    }

    @Override
    public void onFailure(Call<TripList> call, Throwable t) {
        Utils.showToast(getActivity(), "Failed to set adapter: " + t.getLocalizedMessage());
    }

    interface TripListListener {
        void onTripClick(Trip item);
    }
}
