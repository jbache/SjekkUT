package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.melnykov.fab.FloatingActionButton;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.UserCheckins;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Copyright Den Norske Turistforening 2015
 * <p/>
 * Created by espen on 05.02.2015.
 */
public class PlaceListFragment extends Fragment implements LocationListener, View.OnClickListener {

    private static final java.lang.String BUNDLE_PROJECT_ID = "project_id";
    private final Callback<Project> mProjectCallback;
    private final Callback<Place> mPlaceCallback;
    private final Callback<UserCheckins> mUserCheckinsCallback;
    private final LocationRequest mLocationRequest;
    @BindView(R.id.toolbar)
    Toolbar mToolbar;
    @BindView(R.id.placeList)
    RecyclerView mRecyclerView;
    @BindView(R.id.fab)
    FloatingActionButton mFabButton;
    private ProjectPlaceWrapperAdapter mWrapperAdapter;
    private PlaceListListener mListener;
    private String mProjectId;

    public PlaceListFragment() {
        mLocationRequest = LocationRequestUtils.repeatingRequest();
        mProjectCallback = new Callback<Project>() {
            @Override
            public void onResponse(Call<Project> call, Response<Project> response) {
                if (getView() == null)
                    return;

                if (response.isSuccessful()) {
                    mWrapperAdapter.setProjectAndPlaces(response.body());
                    for (Place place : response.body().steder) {
                        TripApiSingleton.call().getPlace(place._id,
                                getString(R.string.api_key),
                                TripApiSingleton.PLACE_EXPAND)
                                .enqueue(mPlaceCallback);
                    }
                } else {
                    Utils.showToast(getActivity(), "Failed to get project: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<Project> call, Throwable t) {
                Utils.showToast(getActivity(), "Failed to get project: " + t);
            }
        };

        mPlaceCallback = new Callback<Place>() {
            @Override
            public void onResponse(Call<Place> call, Response<Place> response) {
                if (response.isSuccessful()) {
                    mWrapperAdapter.updatePlace(response.body());
                } else {
                    Utils.showToast(getActivity(), "Failed to get place: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<Place> call, Throwable t) {
                Utils.showToast(getActivity(), "Failed to get place: " + t);
            }
        };

        mUserCheckinsCallback = new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                if (response.isSuccessful()) {
                    mWrapperAdapter.setUserCheckins(response.body());
                } else {
                    Utils.showToast(getActivity(), "Failed to get user checkins: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<UserCheckins> call, Throwable t) {
                Utils.showToast(getActivity(), "Failed to get user checkins: " + t);
            }
        };
    }

    static PlaceListFragment newInstance(String projectId) {
        PlaceListFragment fragment = new PlaceListFragment();
        Bundle args = new Bundle();
        args.putString(BUNDLE_PROJECT_ID, projectId);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_placelist, container, false);
        ButterKnife.bind(this, rootView);
        Utils.setupSupportToolbar(getActivity(), mToolbar, getString(R.string.screen_project), true);
        mWrapperAdapter = new ProjectPlaceWrapperAdapter(getActivity(), mListener);
        mRecyclerView.setAdapter(mWrapperAdapter);
        mFabButton.setOnClickListener(this);
        setHasOptionsMenu(true);
        return rootView;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_feedback, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof PlaceListListener) {
            mListener = (PlaceListListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement PlaceListListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mProjectId = getArguments().getString(BUNDLE_PROJECT_ID, "");
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).startLocationUpdates(this, mLocationRequest);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        fetchPlaces();
        fetchCheckins();
    }

    private void fetchPlaces() {
        if (mWrapperAdapter.getItemCount() == 0) {
            TripApiSingleton.call().getProject(
                    mProjectId,
                    getString(R.string.api_key),
                    TripApiSingleton.PROJECT_FIELDS,
                    TripApiSingleton.PROJECT_EXPAND)
                    .enqueue(mProjectCallback);
        }
    }

    private void fetchCheckins() {
        CheckinApiSingleton.call().getUserCheckins(PreferenceUtils.getUserId(getActivity())).enqueue(mUserCheckinsCallback);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.fab:
                getActivity().getSupportFragmentManager().beginTransaction()
                        .replace(R.id.container, PlaceFragment.newInstance(null))
                        .addToBackStack(PlaceFragment.class.getCanonicalName())
                        .commit();
                break;
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.feedback:
                MainActivity.showFeedbackActivity(getActivity());
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    public void onLocationChanged(Location location) {
        mWrapperAdapter.setLocation(location);
    }

    interface PlaceListListener {
        void onPlaceClicked(Place place);
    }
}
