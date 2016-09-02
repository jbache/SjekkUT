package no.dnt.sjekkut.ui;

import android.content.Context;
import android.os.Handler;
import android.support.design.widget.FloatingActionButton;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 02.09.2016.
 */

public class CheckinButton extends RelativeLayout implements View.OnClickListener {

    private final Handler mHandler = new Handler();

    @BindView(R.id.fabButton)
    FloatingActionButton mButton;
    @BindView(R.id.fabText)
    TextView mText;


    public CheckinButton(Context context) {
        super(context);
        inflateView(context);
    }

    public CheckinButton(Context context, AttributeSet attrs) {
        super(context, attrs);
        inflateView(context);
    }

    public CheckinButton(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        inflateView(context);
    }

    private void inflateView(Context context) {
        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.layout_checkinbutton, this);
        ButterKnife.bind(this);
        mButton.setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.fabButton:
                mText.setVisibility(View.VISIBLE);
                mHandler.removeCallbacksAndMessages(null);
                mHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        mText.setVisibility(View.INVISIBLE);
                    }
                }, 2000);
                break;
        }
    }
}
