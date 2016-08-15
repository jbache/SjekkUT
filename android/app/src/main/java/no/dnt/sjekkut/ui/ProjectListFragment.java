package no.dnt.sjekkut.ui;

import android.app.Activity;
import android.content.Context;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;

import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.ProjectList;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProjectListFragment extends Fragment implements LocationListener {

    final private ProjectListCallback mProjectListCallback = new ProjectListCallback();
    final private ProjectCallback mProjectCallback = new ProjectCallback();
    final private LocationRequest mLocationRequest = LocationRequestUtils.repeatingRequest();
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
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_projectlist, container, false);
        if (view instanceof RecyclerView) {
            Context context = view.getContext();
            RecyclerView recyclerView = (RecyclerView) view;
            recyclerView.setLayoutManager(new LinearLayoutManager(context));
            recyclerView.setAdapter(new ProjectAdapter(mListener));
            TripApiSingleton.call().getProjectList(getString(R.string.api_key), "steder,bilder,geojson,grupper").enqueue(mProjectListCallback);
        }
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
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        if (activity instanceof ProjectListListener) {
            mListener = (ProjectListListener) activity;
        } else {
            throw new RuntimeException(activity.toString()
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
            } else {
                Utils.showToast(getActivity(), "Failed to get project: " + response.code());
            }
        }

        @Override
        public void onFailure(Call<Project> call, Throwable t) {
            Utils.showToast(getActivity(), "Failed to get project: " + t.getLocalizedMessage());
        }
    }
}
