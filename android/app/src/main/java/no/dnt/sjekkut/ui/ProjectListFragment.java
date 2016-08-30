package no.dnt.sjekkut.ui;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Paint;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.view.MenuItemCompat;
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
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.ProjectList;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.UserCheckins;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProjectListFragment extends Fragment implements LocationListener, SearchView.OnQueryTextListener {

    final private ProjectListCallback mProjectListCallback = new ProjectListCallback();
    final private ProjectCallback mProjectCallback = new ProjectCallback();
    final private Callback<UserCheckins> mUserCheckinsCallback;
    final private LocationRequest mLocationRequest = LocationRequestUtils.repeatingRequest();
    @BindView(R.id.projectlist)
    RecyclerView mRecyclerView;
    @BindView(R.id.toolbar)
    Toolbar mToolbar;
    private ProjectAdapter mProjectAdapter;
    private ProjectListListener mListener;

    public ProjectListFragment() {
        mUserCheckinsCallback = new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                if (response.isSuccessful()) {
                    setUserCheckins(response.body());
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
        Utils.setupSupportToolbar(getActivity(), mToolbar, getString(R.string.app_name), false);
        mToolbar.setNavigationIcon(R.drawable.ic_person);
        mToolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mListener.onProfileClicked();
            }
        });
        mRecyclerView.setLayoutManager(new LinearLayoutManager(view.getContext()));
        mProjectAdapter = new ProjectAdapter(mListener);
        mRecyclerView.setAdapter(mProjectAdapter);
        Paint textPainter = new Paint();
        textPainter.setColor(Color.BLACK);
        textPainter.setTextSize(30);
        mRecyclerView.addItemDecoration(new ProjectSeparator(textPainter, 80));
        TripApiSingleton.call().getProjectList(
                getString(R.string.api_key),
                TripApiSingleton.PROJECTLIST_FIELDS)
                .enqueue(mProjectListCallback);
        CheckinApiSingleton.call().getUserCheckins(
                PreferenceUtils.getUserId(getActivity()))
                .enqueue(mUserCheckinsCallback);
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
        inflater.inflate(R.menu.menu_search, menu);
        inflater.inflate(R.menu.menu_feedback, menu);
        MenuItem searchItem = menu.findItem(R.id.action_search);
        SearchView mSearchView = (SearchView) MenuItemCompat.getActionView(searchItem);
        mSearchView.setOnQueryTextListener(this);
        mSearchView.setInputType(InputType.TYPE_TEXT_VARIATION_FILTER);
        super.onCreateOptionsMenu(menu, inflater);
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

    private void setList(List<Project> projectList) {
        if (mProjectAdapter != null) {
            mProjectAdapter.setProjects(projectList);
        }
    }

    private void updateProject(Project project) {
        if (mProjectAdapter != null) {
            mProjectAdapter.updateProject(project);
        }
    }

    @Override
    public void onLocationChanged(Location location) {
        if (mProjectAdapter != null) {
            mProjectAdapter.setLocation(location);
        }
    }

    private void setUserCheckins(UserCheckins userCheckins) {
        if (mProjectAdapter != null) {
            mProjectAdapter.setUserCheckins(userCheckins);
        }
    }

    @Override
    public boolean onQueryTextSubmit(String query) {
        return false;
    }

    @Override
    public boolean onQueryTextChange(String newText) {
        if (mProjectAdapter != null) {
            mProjectAdapter.filter(newText);
        }
        return true;
    }

    interface ProjectListListener {
        void onProjectClicked(Project project);

        void onProfileClicked();
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
                            TripApiSingleton.PROJECT_FIELDS,
                            TripApiSingleton.PROJECT_EXPAND)
                            .enqueue(mProjectCallback);
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
