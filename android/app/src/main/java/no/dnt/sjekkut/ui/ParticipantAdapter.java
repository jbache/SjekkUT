package no.dnt.sjekkut.ui;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.network.UserCheckins;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 31.08.2016.
 */
public class ParticipantAdapter extends RecyclerView.Adapter<ParticipantAdapter.ParticipantHolder> {

    private final ParticipantAdapter.ParticipantClickedListener mListener;
    private final List<String> mProjectIds = new ArrayList<>();
    private UserCheckins mUserCheckins;


    ParticipantAdapter(ParticipantClickedListener listener) {
        mListener = listener;
    }

    @Override
    public ParticipantHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_participant, parent, false);
        return new ParticipantHolder(view);
    }

    @Override
    public void onBindViewHolder(ParticipantHolder holder, int position) {
        final String projectId = mProjectIds.get(position);
        Context context = holder.itemView.getContext();
        final boolean hasJoined = mUserCheckins != null && mUserCheckins.hasJoined(projectId);
        String button = context.getString(R.string.join_project);
        String text = context.getString(R.string.project_not_joined);
        if (hasJoined) {
            button = context.getString(R.string.leave_project);
            text = context.getString(R.string.project_joined);
        }
        holder.mButton.setText(button);
        if (mListener != null)
            holder.mButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (hasJoined) {
                        mListener.onLeaveProjectClicked(projectId);
                    } else {
                        mListener.onJoinProjectClicked(projectId);
                    }
                }
            });
        holder.mText.setText(text);
    }

    void setProjectIds(List<String> ids) {
        mProjectIds.clear();
        mProjectIds.addAll(ids);
        notifyDataSetChanged();
    }

    @Override
    public int getItemCount() {
        return mProjectIds.size();
    }

    void setUserCheckins(UserCheckins userCheckins) {
        mUserCheckins = userCheckins;
        notifyDataSetChanged();
    }

    void updateUserCheckinsProjects(UserCheckins userCheckins) {
        if (mUserCheckins != null && mUserCheckins.updateJoinedProjects(userCheckins)) {
            notifyDataSetChanged();
        }
    }

    interface ParticipantClickedListener {
        void onJoinProjectClicked(String projectId);

        void onLeaveProjectClicked(String projectId);
    }

    class ParticipantHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.participantButton)
        Button mButton;
        @BindView(R.id.participantText)
        TextView mText;

        ParticipantHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}
