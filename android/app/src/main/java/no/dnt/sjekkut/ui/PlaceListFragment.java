package no.dnt.sjekkut.ui;

import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.ListFragment;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ListView;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Checkin;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.TripApiSingleton;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Copyright Den Norske Turistforening 2015
 * <p/>
 * Created by espen on 05.02.2015.
 */
public class PlaceListFragment extends ListFragment implements LocationListener, View.OnClickListener {

    private static final java.lang.String PROJECT_ID = "project_id";
    private final List<Checkin> mCheckins;
    private final Callback<Project> mProjectCallback;
    private final LocationRequest mLocationRequest;
    private PlaceAdapter mPlaceAdapter;
    private Location mLastLocation = null;
    private ProjectAdapter mProjectAdapter = null;
    private ProjectAdapter.ProjectHolder mHeaderViewHolder = null;
    private String mProjectId;

    public PlaceListFragment() {
        mCheckins = new ArrayList<>();
        mLocationRequest = LocationRequestUtils.repeatingRequest();
        mProjectCallback = new Callback<Project>() {
            @Override
            public void onResponse(Call<Project> call, Response<Project> response) {
                if (getView() == null)
                    return;

                if (response.isSuccessful()) {
                    mProjectAdapter.setList(Collections.singletonList(response.body()));
                    mPlaceAdapter.setNotifyOnChange(false);
                    mPlaceAdapter.clear();
                    mPlaceAdapter.addAll(response.body().steder);
                    mPlaceAdapter.sortByDistance(mLastLocation);
                    mPlaceAdapter.setNotifyOnChange(true);
                    mPlaceAdapter.notifyDataSetChanged();
                    setListShown(true);
                } else {
                    setListShown(true);
                    setEmptyText(getString(R.string.no_mountains_found));
                }
            }

            @Override
            public void onFailure(Call<Project> call, Throwable t) {
                if (getView() == null)
                    return;

                setListShown(true);
                setEmptyText(getString(R.string.no_mountains_found));
            }
        };
        mProjectAdapter = new ProjectAdapter(null);
        mProjectAdapter.registerAdapterDataObserver(new RecyclerView.AdapterDataObserver() {
            @Override
            public void onChanged() {
                updateHeader();
            }
        });
    }

    static PlaceListFragment newInstance(String projectId) {
        PlaceListFragment fragment = new PlaceListFragment();
        Bundle args = new Bundle();
        args.putString(PROJECT_ID, projectId);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View defaultListView = super.onCreateView(inflater, container, savedInstanceState);
        View rootView = inflater.inflate(R.layout.fragment_placelist, container, false);
        Toolbar toolbar = (Toolbar) rootView.findViewById(R.id.toolbar);
        if (toolbar != null && getActivity() instanceof AppCompatActivity) {
            ((AppCompatActivity) getActivity()).setSupportActionBar(toolbar);
        }
        LinearLayout listContainer = (LinearLayout) rootView.findViewById(R.id.listContainer);
        if (listContainer != null && defaultListView != null) {
            listContainer.addView(defaultListView);
        }
        View fabButton = rootView.findViewById(R.id.fab);
        if (fabButton != null) {
            fabButton.setOnClickListener(this);
        }
        setHasOptionsMenu(true);
        return rootView;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        setListAdapter(null);
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_feedback, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mProjectId = getArguments().getString(PROJECT_ID, "");
        if (mHeaderViewHolder == null) {
            mHeaderViewHolder = mProjectAdapter.onCreateViewHolder(getListView(), 0);
        }
        getListView().addHeaderView(mHeaderViewHolder.itemView, null, false);
        mPlaceAdapter = new PlaceAdapter(getActivity(), mCheckins);
        setListAdapter(mPlaceAdapter);
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
    }

    private void fetchPlaces() {
        if (mPlaceAdapter.getCount() == 0) {
            setListShown(false);
            TripApiSingleton.call().getProject(
                    mProjectId,
                    getString(R.string.api_key),
                    "steder,geojson,bilder,img,kommune,fylke,beskrivelse",
                    "steder,bilder"
            ).enqueue(mProjectCallback);
        }
    }

    private void updateHeader() {
        if (getView() == null || getListView() == null || mHeaderViewHolder == null || mProjectAdapter.getItemCount() <= 0) {
            return;
        }

        mProjectAdapter.onBindViewHolder(mHeaderViewHolder, 0);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.fab:
                getActivity().getSupportFragmentManager().beginTransaction()
                        .replace(R.id.container, CheckinFragment.newInstance(null))
                        .addToBackStack(CheckinFragment.class.getCanonicalName())
                        .commit();
                break;
        }
    }

    @Override
    public void onListItemClick(ListView l, View v, int position, long id) {
        // TODO: pass in the Place clicked on
        getActivity().getSupportFragmentManager().beginTransaction()
                .replace(R.id.container, CheckinFragment.newInstance(null))
                .addToBackStack(CheckinFragment.class.getCanonicalName())
                .commit();
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
        mPlaceAdapter.sortByDistance(mLastLocation);
        mProjectAdapter.updateLocation(mLastLocation);
    }
}
