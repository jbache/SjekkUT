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
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.UserCheckins;
import no.dnt.sjekkut.ui.ProjectListFragment.ProjectListListener;

class ProjectAdapter extends RecyclerView.Adapter<ProjectAdapter.ProjectHolder> {

    private final List<Project> mProjectList;
    private final Comparator<Project> mProjectComparator;
    private final ProjectListListener mListener;
    private List<Project> mProjectListCopy = null;
    private Location mUserLocation = null;
    private int mDisplayWidth = 1080;
    private UserCheckins mUserCheckins = null;

    ProjectAdapter(ProjectListFragment.ProjectListListener listener) {
        mListener = listener;
        mProjectList = new ArrayList<>();
        mProjectComparator = new Comparator<Project>() {
            @Override
            public int compare(Project o1, Project o2) {
                int result = Utils.nullSafeCompareTo(!hasUserVisited(o1), !hasUserVisited(o2));
                if (result == 0)
                    result = Utils.nullSafeCompareTo(o1.getDistanceTo(mUserLocation), o2.getDistanceTo(mUserLocation));
                if (result == 0)
                    result = Utils.nullSafeCompareTo(o1.navn, o2.navn);
                return result;
            }
        };
    }

    void setProjects(List<Project> projectList) {
        mProjectList.clear();
        mProjectList.addAll(projectList);
        Collections.sort(mProjectList, mProjectComparator);
        notifyDataSetChanged();
    }

    void updateProject(Project newProject) {
        if (newProject != null && newProject._id != null && !newProject._id.isEmpty()) {
            for (int i = 0; i < mProjectList.size(); ++i) {
                Project oldProject = mProjectList.get(i);
                if (newProject._id.equals(oldProject._id)) {
                    mProjectList.set(i, newProject);
                    Collections.sort(mProjectList, mProjectComparator);
                    notifyDataSetChanged();
                    return;
                }
            }
        }
    }

    @Override
    public ProjectHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_project, parent, false);
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
        Context context = holder.itemView.getContext();
        holder.mProjectTitle.setText(project.navn);
        holder.mGroupTitle.setText(project.getFirstGroupName());
        holder.mDistanceToProject.setText(project.getDistanceToString(context, mUserLocation));
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
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onProjectClicked(project);
                }
            }
        });
    }

    private boolean hasUserVisited(Project project) {
        if (project != null && project.steder != null && !project.steder.isEmpty() && mUserCheckins != null) {
            for (Place place : project.steder) {
                if (mUserCheckins.hasVisited(place._id)) {
                    return true;
                }
            }
        }
        return false;
    }

    private int calculatedVisitedPlaces(Project project) {
        int visitedPlaces = 0;
        if (project != null && project.steder != null && !project.steder.isEmpty() && mUserCheckins != null) {
            for (Place place : project.steder) {
                if (mUserCheckins.hasVisited(place._id)) {
                    ++visitedPlaces;
                }
            }
        }
        return visitedPlaces;
    }

    private boolean noFilters() {
        return mProjectListCopy == null;
    }

    String getSeparatorTitle(int position) {
        if (position >= 0 && mProjectList.size() > position) {
            if (noFilters()) {
                if (position == 0) {
                    boolean hasVisited = hasUserVisited(mProjectList.get(position));
                    return hasVisited ? "Mine prosjekter" : "Andre prosjekter";
                } else {
                    boolean hasVisited = hasUserVisited(mProjectList.get(position));
                    boolean hasPreviousVisited = hasUserVisited(mProjectList.get(position - 1));
                    return !hasVisited && hasPreviousVisited ? "Andre prosjekter" : null;
                }
            } else {
                if (position == 0) {
                    return "Søkeresultater";
                }
            }
        }
        return null;
    }

    @Override
    public int getItemCount() {
        return mProjectList.size();
    }

    void setLocation(Location location) {
        mUserLocation = location;
        Collections.sort(mProjectList, mProjectComparator);
        notifyDataSetChanged();
    }

    void setUserCheckins(UserCheckins checkins) {
        mUserCheckins = checkins;
        Collections.sort(mProjectList, mProjectComparator);
        notifyDataSetChanged();
    }

    void filter(String query) {
        // TODO: fix this so we handle calls to setProjects(..) or updateProject(..) while filtering
        if (mProjectListCopy == null) {
            mProjectListCopy = new ArrayList<>(mProjectList);
        }
        mProjectList.clear();
        if (query.isEmpty()) {
            mProjectList.addAll(mProjectListCopy);
            mProjectListCopy = null;
        } else {
            for (Project project : mProjectListCopy) {
                if (project.navn != null && project.navn.toLowerCase().contains(query.toLowerCase())) {
                    mProjectList.add(project);
                }
            }
        }
        notifyDataSetChanged();
    }

    static class ProjectHolder extends RecyclerView.ViewHolder {
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
            ButterKnife.bind(this, view);
        }

        @Override
        public String toString() {
            return super.toString() + " '" + mGroupTitle.getText() + "'";
        }
    }
}
