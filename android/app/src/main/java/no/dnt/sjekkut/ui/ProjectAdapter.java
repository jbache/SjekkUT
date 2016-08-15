package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.ui.ProjectListFragment.ProjectListListener;

class ProjectAdapter extends RecyclerView.Adapter<ProjectAdapter.ProjectHolder> {

    private final List<Project> mProjectList;
    private final ProjectListListener mListener;
    private Location mUserLocation;

    ProjectAdapter(ProjectListFragment.ProjectListListener listener) {
        mProjectList = new ArrayList<>();
        mListener = listener;
        mUserLocation = null;
    }

    void setList(List<Project> projectList) {
        mProjectList.clear();
        mProjectList.addAll(projectList);
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
    public void onBindViewHolder(final ProjectHolder holder, int position) {
        final Project project = mProjectList.get(position);
        Context context = holder.mProjectTitle.getContext();
        holder.mProjectTitle.setText(project.navn);
        holder.mGroupTitle.setText(project.getFirstGroupName());
        holder.mDistanceToProject.setText(project.getDistanceTo(context, mUserLocation));
        holder.mVisitStatus.setText(context.getString(R.string.projectVisitStatus, 0, project.getPlaceCount()));
        holder.mView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (null != mListener) {
                    mListener.onProjectClicked(project);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return mProjectList.size();
    }

    void updateLocation(Location location) {
        mUserLocation = location;
        notifyDataSetChanged();
    }

    class ProjectHolder extends RecyclerView.ViewHolder {
        final View mView;
        final TextView mProjectTitle;
        final TextView mGroupTitle;
        final TextView mDistanceToProject;
        final TextView mVisitStatus;

        ProjectHolder(View view) {
            super(view);
            mView = view;
            mProjectTitle = (TextView) view.findViewById(R.id.title);
            mGroupTitle = (TextView) view.findViewById(R.id.group);
            mDistanceToProject = (TextView) view.findViewById(R.id.distance);
            mVisitStatus = (TextView) view.findViewById(R.id.visits);
        }

        @Override
        public String toString() {
            return super.toString() + " '" + mGroupTitle.getText() + "'";
        }
    }
}
