package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.squareup.picasso.Picasso;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.SjekkUTApplication;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.PlaceCheckin;
import no.dnt.sjekkut.network.PlaceCheckinList;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.ui.ProjectListFragment.ProjectListListener;

class ProjectAdapter extends RecyclerView.Adapter<ProjectAdapter.ProjectHolder> {

    private final List<Project> mProjectList = new ArrayList<>();
    private final Set<String> mPlacesVisitedByUser = new HashSet<>();
    private final ProjectListListener mListener;
    private Location mUserLocation = null;
    private int mDisplayWidth = 1080;

    ProjectAdapter(ProjectListFragment.ProjectListListener listener) {
        mListener = listener;
    }

    void setList(List<Project> projectList) {
        mProjectList.clear();
        mProjectList.addAll(projectList);
        mPlacesVisitedByUser.clear();
        notifyDataSetChanged();
    }

    void updateProject(Project newProject) {
        if (newProject != null && newProject._id != null && !newProject._id.isEmpty()) {
            for (int i = 0; i < mProjectList.size(); ++i) {
                Project oldProject = mProjectList.get(i);
                if (newProject._id.equals(oldProject._id)) {
                    mProjectList.set(i, newProject);
                    notifyDataSetChanged();
                    return;
                }
            }
        }
    }

    @Override
    public ProjectHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.projectitem, parent, false);
        return new ProjectHolder(view);
    }

    @Override
    public void onAttachedToRecyclerView(RecyclerView recyclerView) {
        super.onAttachedToRecyclerView(recyclerView);
        mDisplayWidth = Utils.getDisplayWidth(recyclerView.getContext());
    }

    @Override
    public void onBindViewHolder(final ProjectHolder holder, int position) {
        final Project project = mProjectList.get(position);
        Context context = holder.mProjectTitle.getContext();
        holder.mProjectTitle.setText(project.navn);
        holder.mGroupTitle.setText(project.getFirstGroupName());
        holder.mDistanceToProject.setText(project.getDistanceTo(context, mUserLocation));
        int visitedProjectPlaces = calculatedVisitedPlaces(project);
        int totalProjectPlaces = project.getPlaceCount();
        holder.mVisitStatus.setText(context.getString(R.string.projectVisitStatus, visitedProjectPlaces, totalProjectPlaces));
        Picasso.with(context)
                .load(project.getImageUrl((int) (mDisplayWidth * 0.25f)))
                .error(project.getImageFallback())
                .placeholder(project.getImageFallback())
                .fit()
                .centerCrop()
                .into(holder.mImage);
        Picasso.with(context)
                .load(project.getBackgroundUrl(mDisplayWidth))
                .error(project.getBackgroundFallback())
                .placeholder(project.getBackgroundFallback())
                .fit()
                .centerCrop()
                .into(holder.mBackground);
        holder.mView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onProjectClicked(project);
                }
            }
        });
    }

    private int calculatedVisitedPlaces(Project project) {
        int visitedPlaces = 0;
        if (project != null && project.steder != null && !project.steder.isEmpty() && !mPlacesVisitedByUser.isEmpty()) {
            for (Place place : project.steder) {
                if (mPlacesVisitedByUser.contains(place._id)) {
                    ++visitedPlaces;
                }
            }
        }
        return visitedPlaces;
    }

    @Override
    public int getItemCount() {
        return mProjectList.size();
    }

    void updateLocation(Location location) {
        mUserLocation = location;
        notifyDataSetChanged();
    }

    void updatePlaceCheckins(PlaceCheckinList placeCheckinList) {
        if (placeCheckinList != null && placeCheckinList.data != null && !placeCheckinList.data.isEmpty()) {
            boolean changed = false;
            String userId = PreferenceUtils.getUserId(SjekkUTApplication.getContext());
            for (PlaceCheckin checkin : placeCheckinList.data) {
                if (userId.equals(checkin.dnt_user_id)) {
                    changed = true;
                    mPlacesVisitedByUser.add(checkin.ntb_steder_id);
                }
            }
            if (changed) {
                notifyDataSetChanged();
            }
        }
    }

    class ProjectHolder extends RecyclerView.ViewHolder {
        final View mView;
        @BindView(R.id.title)
        TextView mProjectTitle;
        @BindView(R.id.group)
        TextView mGroupTitle;
        @BindView(R.id.distance)
        TextView mDistanceToProject;
        @BindView(R.id.visits)
        TextView mVisitStatus;
        @BindView(R.id.background)
        ImageView mBackground;
        @BindView(R.id.image)
        ImageView mImage;

        ProjectHolder(View view) {
            super(view);
            mView = view;
            ButterKnife.bind(this, view);
        }

        @Override
        public String toString() {
            return super.toString() + " '" + mGroupTitle.getText() + "'";
        }
    }
}
