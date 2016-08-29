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

import java.util.Collections;

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
    private final Callback<UserCheckins> mUserCheckinsCallback;
    private final LocationRequest mLocationRequest;
    private PlaceAndProjectAdapter mPlaceAndProjectAdapter;
    private Location mLastLocation = null;
    private PlaceListListener mListener;
    private String mProjectId;
    @BindView(R.id.toolbar)
    Toolbar mToolbar;
    @BindView(R.id.placeList)
    RecyclerView mRecyclerView;
    @BindView(R.id.fab)
    FloatingActionButton mFabButton;

    public PlaceListFragment() {
        mLocationRequest = LocationRequestUtils.repeatingRequest();
        mProjectCallback = new Callback<Project>() {
            @Override
            public void onResponse(Call<Project> call, Response<Project> response) {
                if (getView() == null)
                    return;

                if (response.isSuccessful()) {
                    mPlaceAndProjectAdapter.setPlaceAndProject(response.body());
                } else {
                    Utils.showToast(getActivity(), "Failed to get project: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<Project> call, Throwable t) {
                Utils.showToast(getActivity(), "Failed to get project: " + t);
            }
        };

        mUserCheckinsCallback = new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                if (response.isSuccessful()) {
                    mPlaceAndProjectAdapter.setUserCheckins(response.body().getCheckins());
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
        Utils.setupSupportToolbar(getActivity(), mToolbar, "", true);
        mPlaceAndProjectAdapter = new PlaceAndProjectAdapter(getActivity(), mListener);
        mRecyclerView.setAdapter(mPlaceAndProjectAdapter);
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
/* TODO: add back the header
        if (mHeaderViewHolder == null) {
            mHeaderViewHolder = mProjectAdapter.onCreateViewHolder(getListView(), 0);
        }
        getListView().addHeaderView(mHeaderViewHolder.itemView, null, false);
*/
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).startLocationUpdates(this, mLocationRequest);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        Utils.toggleUpButton(getActivity(), true);
        Utils.setActionBarTitle(getActivity(), "Prosjekt");
        fetchPlaces();
        fetchCheckins();
    }

    private void fetchPlaces() {
        if (mPlaceAndProjectAdapter.getItemCount() == 0) {
            TripApiSingleton.call().getProject(
                    mProjectId,
                    getString(R.string.api_key),
                    "steder,geojson,bilder,img,kommune,fylke,beskrivelse",
                    "steder,bilder"
            ).enqueue(mProjectCallback);
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
        mLastLocation = location;
        mPlaceAndProjectAdapter.setLocation(mLastLocation);
    }

    interface PlaceListListener {
        void onPlaceClicked(Place place);
    }
}
