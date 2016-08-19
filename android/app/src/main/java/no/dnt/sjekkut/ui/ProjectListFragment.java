package no.dnt.sjekkut.ui;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Paint;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.SearchView;
import android.support.v7.widget.Toolbar;
import android.text.InputType;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;

import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.PlaceCheckinList;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.ProjectList;
import no.dnt.sjekkut.network.TripApiSingleton;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProjectListFragment extends Fragment implements LocationListener, SearchView.OnQueryTextListener {

    final private ProjectListCallback mProjectListCallback = new ProjectListCallback();
    final private ProjectCallback mProjectCallback = new ProjectCallback();
    final private PlaceCheckinListCallback mPlaceCheckinCallback = new PlaceCheckinListCallback();
    final private LocationRequest mLocationRequest = LocationRequestUtils.repeatingRequest();
    @BindView(R.id.projectlist)
    RecyclerView mRecyclerView;
    @BindView(R.id.toolbar)
    Toolbar mToolbar;
    private ProjectListListener mListener;

    public ProjectListFragment() {
    }

    @SuppressWarnings("unused")
    public static ProjectListFragment newInstance(int columnCount) {
        ProjectListFragment fragment = new ProjectListFragment();
        Bundle args = new Bundle();
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setHasOptionsMenu(true);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_projectlist, container, false);
        ButterKnife.bind(this, view);
        if (getActivity() instanceof AppCompatActivity) {
            ((AppCompatActivity) getActivity()).setSupportActionBar(mToolbar);
        }
        mRecyclerView.setLayoutManager(new LinearLayoutManager(view.getContext()));
        mRecyclerView.setAdapter(new ProjectAdapter(mListener));
        Paint textPainter = new Paint();
        textPainter.setColor(Color.BLACK);
        textPainter.setTextSize(30);
        mRecyclerView.addItemDecoration(new ProjectSeparator(textPainter, 80));
        TripApiSingleton.call().getProjectList(getString(R.string.api_key), "steder,bilder,geojson,grupper").enqueue(mProjectListCallback);
        return view;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).startLocationUpdates(this, mLocationRequest);
        }
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_projectlist_fragment, menu);
        MenuItem searchItem = menu.findItem(R.id.action_search);
        SearchView mSearchView = (SearchView) MenuItemCompat.getActionView(searchItem);
        mSearchView.setOnQueryTextListener(this);
        mSearchView.setInputType(InputType.TYPE_TEXT_VARIATION_FILTER);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public void setHasOptionsMenu(boolean hasMenu) {
        super.setHasOptionsMenu(hasMenu);
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof ProjectListListener) {
            mListener = (ProjectListListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement ProjectListListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    private ProjectAdapter getProjectAdapter() {
        if (getView() != null) {
            RecyclerView recyclerView = (RecyclerView) getView().findViewById(R.id.projectlist);
            if (recyclerView != null) {
                if (recyclerView.getAdapter() instanceof ProjectAdapter) {
                    return (ProjectAdapter) recyclerView.getAdapter();
                }
            }
        }
        return null;
    }

    private void setList(List<Project> projectList) {
        if (getProjectAdapter() != null) {
            getProjectAdapter().setList(projectList);
        }
    }

    private void updateProject(Project project) {
        if (getProjectAdapter() != null) {
            getProjectAdapter().updateProject(project);
        }
    }

    @Override
    public void onLocationChanged(Location location) {
        if (getProjectAdapter() != null) {
            getProjectAdapter().updateLocation(location);
        }
    }

    private void updateCheckins(PlaceCheckinList placeCheckinList) {
        if (getProjectAdapter() != null) {
            getProjectAdapter().updatePlaceCheckins(placeCheckinList);
        }
    }

    @Override
    public boolean onQueryTextSubmit(String query) {
        return false;
    }

    @Override
    public boolean onQueryTextChange(String newText) {
        if (getProjectAdapter() != null) {
            getProjectAdapter().filter(newText);
        }
        return true;
    }

    interface ProjectListListener {
        void onProjectClicked(Project project);
    }

    private class ProjectListCallback implements Callback<ProjectList> {

        @Override
        public void onResponse(Call<ProjectList> call, Response<ProjectList> response) {
            if (response.isSuccessful()) {
                List<Project> projectList = response.body().documents;
                setList(projectList);
                for (Project project : projectList) {
                    TripApiSingleton.call().getProject(
                            project._id,
                            getString(R.string.api_key),
                            "steder,geojson,bilder,img,kommune,beskrivelse,grupper",
                            "steder,bilder,grupper"
                    ).enqueue(mProjectCallback);
                }
            } else {
                Utils.showToast(getActivity(), "Failed to get project list: " + response.code());
            }
        }

        @Override
        public void onFailure(Call<ProjectList> call, Throwable t) {
            Utils.showToast(getActivity(), "Failed to get project list: " + t.getLocalizedMessage());
        }
    }

    private class ProjectCallback implements Callback<Project> {

        @Override
        public void onResponse(Call<Project> call, Response<Project> response) {
            if (response.isSuccessful()) {
                updateProject(response.body());
                for (Place place : response.body().steder) {
                    CheckinApiSingleton.call().getPlaceCheckinList(place._id).enqueue(mPlaceCheckinCallback);
                }
            } else {
                Utils.showToast(getActivity(), "Failed to get project: " + response.code());
            }
        }

        @Override
        public void onFailure(Call<Project> call, Throwable t) {
            Utils.showToast(getActivity(), "Failed to get project: " + t.getLocalizedMessage());
        }
    }

    private class PlaceCheckinListCallback implements Callback<PlaceCheckinList> {

        @Override
        public void onResponse(Call<PlaceCheckinList> call, Response<PlaceCheckinList> response) {
            if (response.isSuccessful()) {
                updateCheckins(response.body());
            } else {
                Utils.showToast(getActivity(), "Failed to get place checkin list: " + response.code());
            }
        }

        @Override
        public void onFailure(Call<PlaceCheckinList> call, Throwable t) {
            Utils.showToast(getActivity(), "Failed to get place checkin list: " + t.getLocalizedMessage());
        }
    }

}
